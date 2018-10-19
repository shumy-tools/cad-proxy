import db.Pull
import db.Store
import db.Series
import dicom.DLocal
import dicom.DPull
import dicom.model.DImage
import dicom.model.DPatient
import dicom.model.DResult
import dicom.model.DSeries
import dicom.model.DStudy
import java.nio.file.Files
import java.nio.file.Paths
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.Set
import org.dcm4che2.io.DicomOutputStream
import org.slf4j.LoggerFactory
import org.dcm4che2.data.Tag
import org.dcm4che2.data.VR

class PullService {
  static val logger = LoggerFactory.getLogger(PullService)
  
  val Store store
  val DLocal local
  
  //TODO: move this to a DB config. Load on PullService instantiation.
  val cachePath = "./data/cache"
  
  //TODO: move this to a DB config. Load on PullService instantiation.
  val whiteList = #{
    Tag.SOPClassUID,
    
    Tag.PatientOrientation,
    
    Tag.StudyDate,
    Tag.StudyTime,
    
    Tag.SeriesNumber,
    Tag.Modality,
    
    Tag.InstanceNumber,
    Tag.AcquisitionNumber,
    Tag.ContentDate,
    Tag.ContentTime,
    Tag.Laterality,
    
    Tag.PixelData,
    Tag.Columns,
    Tag.Rows,
    Tag.BitsAllocated,
    Tag.BitsStored,
    Tag.HighBit,
    Tag.PixelRepresentation,
    Tag.SamplesPerPixel,
    Tag.PhotometricInterpretation,
    Tag.PlanarConfiguration
  }
  
  new(Store store, String localAET, String localIP) {
    this.store = store
    this.local = new DLocal(localAET, localIP, 1104)[
      val seriesUID = get(DSeries.UID)
      
      val seriesID = store.SERIES.exist(seriesUID)
      if (seriesID === null) {
        // if this is executed, it's probably a bug on the PACS server!
        store.error(PullService, "Trying to store a non requested seriesUID: " + seriesUID)
        return
      }
      
      if(!isEligible) {
        logger.debug("On-Store filter, non eligible series: {}", seriesUID)
        store.SERIES.eligible(seriesID, false)
        return
      }
      
      val imageUID = get(DImage.UID)
      val imageSeq = get(DImage.NUMBER)
      val imageDT = LocalDateTime.of(get(DImage.CONTENT_DATE), get(DImage.CONTENT_TIME))
      
      try {
        logger.info("Cache file: (series={}, image={})", seriesUID, imageUID)
        val dir = Paths.get(cachePath + "/s" + seriesID)
        Files.createDirectories(dir)
        
        val file = dir.resolve(imageSeq + "i.dcm").toFile
        file.delete
        file.createNewFile
        
        // dicom is anonymized before cache storage
        val dos = new DicomOutputStream(file)
        dos.writeDicomFile(anonymize)
        dos.close
        
        store.ITEM.create(seriesID, imageUID, imageSeq, imageDT)
      } catch (Throwable ex) {
        store.error(PullService, "Unable to save file for imageUID: " + seriesUID + " -> " + ex.message)
      }
    ]
  }
  
  def Set<Long> pullRequest(LocalDate day) {
    logger.info("On-Request day: {}", day)
    
    val modalities = store.TARGET.modalities
    logger.info("On-Request using modalities: {}", modalities)
    
    return store.SOURCE.pullThrottle.map[
      val sourceID = get("id") as Long
      val requestID = store.PULL.create(sourceID, Pull.Type.REQ)
      
      try {
        val aet = get("aet") as String
        logger.info("On-Request using source: {}", aet)
        
        val con = local.connect(aet, get("host") as String, get("port") as Integer)
        
        val studyRes = con.findDayStudies(day)
        logger.info("On-Request {} study results for day: {}", studyRes.size, day)
        
        val studies = new HashMap<String, Long>
        studyRes.forEach[
          val patientID = get(DPatient.ID)
          val subjectID = store.SUBJECT.activeFrom(sourceID, patientID)
          if (subjectID === null) return;
          
          logger.debug("On-Request using patientID: {}", patientID)
          
          // get or create study
          val studyUID = get(DStudy.UID)
          val studyID = store.STUDY.create(subjectID, studyUID, get(DStudy.DATE))
          logger.debug("On-Request inserted study: {}", studyUID)
          studies.put(studyUID, studyID)
        ]
        
        store.PULL.linkStudies(requestID, studies.values)
        
        var seriesRes = con.findDaySeries(day)
        logger.info("On-Request {} series results for day: {}", studyRes.size, day)
        
        seriesRes
          .filter[ modalities.contains(get(DSeries.MODALITY)) ]
          .forEach[
            val studyUID = get(DStudy.UID)
            val studyID = studies.get(studyUID)
            if (studyID === null) return
            
            // create series
            val seriesUID = get(DSeries.UID)
            store.SERIES.create(studyID, seriesUID, get(DSeries.NUMBER), get(DSeries.MODALITY))
            logger.debug("On-Request inserted series: {}", seriesUID)
          ]
        
        store.PULL.status(requestID, Pull.Status.READY)
        con.close
      } catch (Throwable ex) {
        ex.printStackTrace
        store.PULL.error(requestID, ex.message)
      }
      
      return requestID
    ].toSet
  }
  
  def Long pull(Long requestID) {
    logger.info("On-Pull findID: {}", requestID)
    val data = store.PULL.data(requestID, Pull.Type.REQ)
    if (data.get("status") != Pull.Status.READY.name)
      throw new RuntimeException("On-Pull request not ready, requestID: " + requestID)
    
    val pullID = store.PULL.create(requestID, Pull.Type.PULL)
    try {
      val sourceID = data.get("source") as Long
      val source = store.SOURCE.byId(sourceID)
      
      val aet = source.get("aet") as String
      logger.info("On-Pull using source: {}", aet)
        
      val con = local.connect(aet, source.get("host") as String, source.get("port") as Integer)
      
      val studies = data.get("studies") as List<Map<String, Object>>
      studies.forEach[
        val studyUID = get("uid") as String
        val series = get("series") as List<Map<String, Object>>
        series.forEach[
          val seriesUID = get("uid") as String
          val seriesID = get("id") as Long
          
          // async pull
          con.pull(studyUID, seriesUID)[
            switch status {
              case DPull.Status.OK: logger.debug("On-Pull ok for series: {}", seriesUID)
              case DPull.Status.COMPLETED: {
                logger.info("On-Pull completed for series: {}", seriesUID)
                store.SERIES.status(seriesID, Series.Status.READY)
              }
              case DPull.Status.ERROR: {
                store.error(PullService, "Series status error series: " + seriesUID)
                store.SERIES.error(seriesID, "DICOM error code: " + dicomErrorCode)
              }
            }
          ]
        ]
      ]
      
      store.PULL.status(pullID, Pull.Status.END)
      store.PULL.status(requestID, Pull.Status.END)
      con.close
    } catch (Throwable ex) {
      ex.printStackTrace
      store.PULL.error(pullID, ex.message)
      store.PULL.updateStatusOnPullTries(requestID)
    }
    
    return pullID
  }
  
  private def anonymize(DResult res) {
    // leave only white listed attributes
    val view = res.obj.excludePrivate
    view.datasetIterator.forEach[
      if (!whiteList.contains(tag))
        view.remove(tag)
    ]
    
    // always remove these meta info
    view.fileMetaInfo => [
      remove(Tag.ImplementationVersionName)
      remove(Tag.SourceApplicationEntityTitle)
      remove(Tag.PrivateInformationCreatorUID)
      remove(Tag.PrivateInformation)
    ]
    
    // reset mandatory attributes
    view => [
      putString(Tag.PatientID, VR.LO, "ZZZZZZZZZZZZ")
      putString(Tag.StudyInstanceUID, VR.UI, "0.0.000.0.0.0000000.0.0000.0.0.0.0000000")
      putString(Tag.StudyID, VR.SH, "0000")
      putString(Tag.SeriesInstanceUID, VR.UI, "0.0.000.000000.000.0.0.000000.0000.00000000000000.0")
      putString(Tag.SOPInstanceUID, VR.UI, "0.0.000.000000.000.0.0.000000.0000.00000000000000.0.0.0.0")
    ]
    
    return view
  }
  
  private def isEligible(DResult result) {
    //TODO: filter non eligible results. i.e filtering some manufacturers!
    return true
  }
  
}