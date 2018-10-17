import db.Pull
import db.Store
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

class PullRequests {
  // number of in progress pulls for a seriesUID <seriesUID, pullRequests>
  // uses a refCount mechanism to manage requests
  val inProgress = new HashMap<String, Integer> 
  
  def synchronized void add(String seriesUID) {
    val count = inProgress.get(seriesUID)?:0
    inProgress.put(seriesUID, count + 1)
  }
  
  def synchronized void remove(String seriesUID) {
    val count = inProgress.get(seriesUID)?:0
    if (count > 0)
      inProgress.put(seriesUID, count - 1)
    else
      inProgress.remove(seriesUID)
  }
  
  def synchronized boolean contains(String seriesUID) {
    val count = inProgress.get(seriesUID)?:0
    return count !== 0
  }
}

class PullService {
  static val logger = LoggerFactory.getLogger(PullService)
  
  val Store store
  val DLocal local
  
  val requests = new PullRequests
  val cachePath = "./data/cache"
  
  new(Store store, String localAET, String localIP) {
    this.store = store
    this.local = new DLocal(localAET, localIP, 1104)[
      val seriesUID = get(DSeries.UID)
      if(!isEligible) {
        logger.debug("On-Store filter, non eligible series: {}", seriesUID)
        return
      }
      
      if (!requests.contains(seriesUID)) {
        // if this is executed, it's probably a bug from the PACS server!
        logger.error("On-Store trying to store an non requested seriesUID: {}", seriesUID)
        //TODO: set the series status/error ?
        return
      }
      
      val imageUID = get(DImage.UID)
      val imageSeq = get(DImage.NUMBER)
      val imageDT = LocalDateTime.of(get(DImage.CONTENT_DATE), get(DImage.CONTENT_TIME))
      
      logger.info("Cache file: (series={}, image={})", seriesUID, imageUID)
      
      val dir = Paths.get(cachePath + "/" + seriesUID)
      Files.createDirectories(dir)
      
      val file = dir.resolve(imageUID + ".dcm").toFile
      file.deleteOnExit
      file.createNewFile
      
      //TODO: dicom should be pseudonymous ?
      val dos = new DicomOutputStream(file)
      dos.writeDicomFile(obj)
      dos.close
      
      store.ITEM.linkCreate(seriesUID, imageUID, imageSeq, imageDT)
    ]
  }
  
  def Set<Long> find(LocalDate day) {
    logger.info("On-Find day: {}", day)
    
    val modalities = store.TARGET.modalities
    logger.info("On-Find using modalities: {}", modalities)
    
    return store.SOURCE.pullThrottle.map[
      val sourceID = get("id") as Long
      val findID = store.PULL.create(sourceID, Pull.Type.FIND)
      
      try {
        val aet = get("aet") as String
        logger.info("On-Find using source: {}", aet)
        
        val con = local.connect(aet, get("host") as String, get("port") as Integer)
        
        val studyRes = con.findDayStudies(day)
        logger.info("On-Find {} study results for day: {}", studyRes.size, day)
        
        val studies = new HashMap<String, Long>
        studyRes.forEach[
          val patientID = get(DPatient.ID)
          val subjectID = store.SUBJECT.activeFrom(sourceID, patientID)
          if (subjectID === null) return;
          
          logger.debug("On-Find using patientID: {}", patientID)
          
          // get or create study
          val studyUID = get(DStudy.UID)
          val studyID = store.STUDY.create(subjectID, studyUID, get(DStudy.DATE))
          logger.debug("On-Find inserted study: {}", studyUID)
          studies.put(studyUID, studyID)
        ]
        
        store.PULL.linkStudies(findID, studies.values)
        
        var seriesRes = con.findDaySeries(day)
        logger.info("On-Find {} series results for day: {}", studyRes.size, day)
        
        seriesRes
          .filter[ modalities.contains(get(DSeries.MODALITY)) ]
          .forEach[
            val studyUID = get(DStudy.UID)
            val studyID = studies.get(studyUID)
            if (studyID === null) return
            
            // create series
            val seriesUID = get(DSeries.UID)
            store.SERIES.create(studyID, seriesUID, get(DSeries.NUMBER), get(DSeries.MODALITY))
            logger.debug("On-Find inserted series: {}", seriesUID)
          ]
        
        store.PULL.status(findID, Pull.Status.END)
        con.close
      } catch (Throwable ex) {
        ex.printStackTrace
        store.PULL.error(findID, ex.message)
      }
      
      return findID
    ].toSet
  }
  
  def Long pull(Long findID) {
    logger.info("On-Pull findID: {}", findID)
    
    val data = store.PULL.data(findID, Pull.Type.FIND)
    val pullID = store.PULL.create(findID, Pull.Type.STORE)
    
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
          requests.add(seriesUID)
          con.pull(studyUID, seriesUID)[
            if (status === DPull.Status.COMPLETED) {
              println("COMPLETED: " + seriesUID)
              requests.remove(seriesUID)
              store.SERIES.completed(seriesID, true)
              logger.info("On-Pull completed for series: {}", seriesUID)
            }
          ]
        ]
      ]
      
      store.PULL.status(pullID, Pull.Status.END)
      con.close
    } catch (Throwable ex) {
      ex.printStackTrace
      store.PULL.error(pullID, ex.message)
    }
    
    return pullID
  }
  
  private def isEligible(DResult result) {
    //TODO: filter non eligible results. i.e filtering some manufacturers!
    return true
  }
  
}