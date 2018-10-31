package service

import db.Pull
import db.Series
import db.Store
import dicom.DLocal
import dicom.DPull
import dicom.model.DImage
import dicom.model.DPatient
import dicom.model.DQuery
import dicom.model.DResult
import dicom.model.DSeries
import dicom.model.DStudy
import java.net.NetworkInterface
import java.nio.file.Files
import java.nio.file.Paths
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.Collections
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import org.dcm4che2.data.Tag
import org.dcm4che2.data.VR
import org.dcm4che2.io.DicomOutputStream
import org.slf4j.LoggerFactory

class FindResult {
  public val Map<String, Object> results
  val boolean filtered
  
  new (Map<String, Object> results) {this(results, false)}
  new(Map<String, Object> results, boolean filtered) {
    this.results = results
    this.filtered = filtered
  }
  
  def FindResult filter(Set<String> modalities) {
    if (filtered) return this
    
    val newResults = new HashMap<String, Object>
    results.forEach[ sourceAET, sourceValue |
      val patientsMap = (sourceValue as Map<String, Object>)
      
      val filteredPatients = patientsMap.keySet.map[ patientID |
        val patient = (patientsMap.get(patientID) as Map<String, Object>)
        
        val studiesMap = patient.get("studies") as Map<String, Object>
        val filteredStudies = studiesMap.keySet.map[ studyUID |
          val study = (studiesMap.get(studyUID) as Map<String, Object>)
          
          val seriesMap = study.get("series") as Map<String, Object>
          val newSeriesMap = seriesMap.filter[ seriesUID, seriesValue |
            val series = (seriesValue as Map<String, Object>)
            modalities.contains(series.get("modality"))
          ]
          
          // new study with filtered series
          new HashMap<String, Object>() => [
            put("uid", studyUID)
            putAll(study)
            if (!newSeriesMap.empty)
              put("series", newSeriesMap)
          ]
        ].filter[ get("series") !== null ]
        
        // new patient with filtered studies
        new HashMap<String, Object>() => [
          put("pid", patientID)
          putAll(patient)
          if (!filteredStudies.empty) {
            val newStudiesMap = new HashMap<String, Object>
            filteredStudies.forEach[
              newStudiesMap.put(get("uid") as String, it)
            ]
            
            put("studies", newStudiesMap)
          }
            
        ]
      ].filter[ get("studies") !== null ]
      
      // put new source with filtered patients
      if (!filteredPatients.empty) {
        val newPatientsMap = new HashMap<String, Object>
        filteredPatients.forEach[
          newPatientsMap.put(get("pid") as String, it)
        ]
        
        newResults.put(sourceAET, newPatientsMap)
      }
        
    ]
    
    return new FindResult(newResults, true)
  }
  
  override toString() {
    val sb = new StringBuilder
    results.forEach[ sourceAET, sourceValue |
      val patientsMap = (sourceValue as Map<String, Object>)
      sb.append("\n" + sourceAET)
      
      patientsMap.forEach[ patientID, patientValue |
        val patient = (patientValue as Map<String, Object>)
        sb.append("\n  " + patientID)
        sb.append("\n    sex: " + patient.get("sex"))
        sb.append("\n    birthday: " + patient.get("birthday"))
        
        val studiesMap = patient.get("studies") as Map<String, Object>
        studiesMap.forEach[studyUID, studyValue |
          val study = (studyValue as Map<String, Object>)
          sb.append("\n    study: " + studyUID)
          sb.append("\n      date: " + study.get("date"))
          
          val seriesMap = study.get("series") as Map<String, Object>
          seriesMap.forEach[seriesUID, seriesValue |
            val series = (seriesValue as Map<String, Object>)
            sb.append("\n      series: " + seriesUID)
            sb.append("\n        modality: " + series.get("modality"))
            sb.append("\n        number: " + series.get("number"))
            sb.append("\n        date: " + series.get("date"))
            sb.append("\n        time: " + series.get("time"))
          ]
        ]
      ]
    ]
    
    return sb.toString
  }
  
}

class PullService {
  static val logger = LoggerFactory.getLogger(PullService)
  
  val Store store
  val DLocal local
  
  val String cachePath
  val Set<Integer> whiteList
  
  new(Store store) {
    this.store = store
    this.cachePath = System.getProperty("dataPath") + store.KEY.get(String, "path", "cache")
    this.whiteList = store.KEY.get(Set, "dicom", "white-list")
    
    val localAET = store.KEY.get(String, "local-aet", "aet")
    val localEthName = store.KEY.get(String, "local-aet", "eth-name")
    val localPort = store.KEY.get(Integer, "local-aet", "port")
    
    logger.info("Using inet interface: {}", localEthName)
    val localInet = Collections.list(NetworkInterface.getByName(localEthName).inetAddresses).filter[
      siteLocalAddress && isReachable(100)
    ].head
    
    if (localInet === null)
      throw new RuntimeException("No suitable address found for the interface: " + localEthName)
    
    this.local = new DLocal(localAET, localInet.hostAddress, localPort)[
      val seriesUID = get(DSeries.UID)
      
      val seriesID = store.SERIES.exist(seriesUID)
      if (seriesID === null) {
        // if this is executed, it's probably a bug on the PACS server!
        store.LOG.error(PullService, "Trying to store a non requested seriesUID: " + seriesUID)
        return
      }
      
      val reason = isEligible
      if(reason !== null) {
        logger.debug("On-Store filter, non eligible series: {}", seriesUID)
        store.SERIES.nonEligible(seriesID, reason)
        return
      }
      
      val imageUID = get(DImage.UID)
      val imageSeq = get(DImage.NUMBER)
      val imageDT = LocalDateTime.of(get(DImage.CONTENT_DATE), get(DImage.CONTENT_TIME))
      
      try {
        //logger.info("Pre-Process file: (series={}, image={})", seriesUID, imageUID)
        //TODO: pre-process file (i.e. pixel data anonimization)
        
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
        store.LOG.exception(PullService, ex)
      }
    ]
  }
  
  def FindResult find(DQuery query) {
    logger.debug("On-Find : {}", query)
    
    // <study-uid> -> Study 
    val tmpStudies = new HashMap<String, Object>
    
    // <source-aet>#<patient-id> -> Patient
    val results = new HashMap<String, Object>
    
    store.SOURCE.all.forEach[
      val aet = get("aet") as String
      logger.debug("On-Find using source: {}", aet)
      
      val con = local.connect(aet, get("host") as String, get("port") as Integer)
      
      // retrieve studies
      val studyRes = con.find(DQuery.RetrieveLevel.STUDY, query,
        DPatient.ID, DPatient.SEX, DPatient.BIRTHDAY, DStudy.UID, DStudy.DATE
      )
      
      logger.debug("On-Find {} study results: {}", studyRes.size)
      if (studyRes.empty)
        return;
      
      val source = new HashMap<String, Object>
      results.put(aet, source)
      
      studyRes.forEach[
        val patientID = get(DPatient.ID)
        val studyUID = get(DStudy.UID)
        
        val patient = source.get(patientID) as Map<String, Object> ?: #{
          "sex" -> get(DPatient.SEX),
          "birthday" -> get(DPatient.BIRTHDAY),
          "studies" -> new HashMap<String, Object>
        }
        
        source.put(patientID, patient)
        
        val studies = patient.get("studies") as Map<String, Object>
        studies.put(studyUID, #{
          "date" -> get(DStudy.DATE),
          "series" -> new HashMap<String, Object>
        })
        
        tmpStudies.put(studyUID, studies.get(studyUID))
      ]
      
      // retrieve series
      var seriesRes = con.find(DQuery.RetrieveLevel.SERIES, query,
        DStudy.UID, DSeries.UID, DSeries.MODALITY, DSeries.NUMBER, DSeries.DATE, DSeries.TIME
      )
      logger.debug("On-Find {} series results: {}", seriesRes.size)
      
      seriesRes.forEach[
        val studyUID = get(DStudy.UID)
        val study = tmpStudies.get(studyUID) as Map<String, Object>
        
        val series = study.get("series") as Map<String, Object>
        series.put(get(DSeries.UID), #{
          "modality" -> get(DSeries.MODALITY),
          "number" -> get(DSeries.NUMBER),
          "date" -> get(DSeries.DATE),
          "time" -> get(DSeries.TIME)
        })
      ]
    ]
    
    return new FindResult(results)
  }
  
  def Set<Long> pullRequests(FindResult rawResult) {
    val modalities = store.TARGET.modalities
    logger.info("On-Request using modalities: {}", modalities)
    
    val result = rawResult.filter(modalities)
    val requests = new HashSet<Long>
    
    result.results.forEach[ sourceAET, sourceValue |
      val sourceID = store.SOURCE.idFromAET(sourceAET)
      val source = (sourceValue as Map<String, Object>)
      
      if (!store.SUBJECT.exist(sourceID, source.keySet)) {
        logger.info("On-Request no linked or active subjects for sourceID: {}", sourceID)
        return;
      }
      
      val requestID = store.PULL.createRequest(sourceID)
      requests.add(requestID)
      
      try {
        source.forEach[ patientID, patientValue |
          val patient = (patientValue as Map<String, Object>)
          
          val subjectID = store.SUBJECT.from(sourceID, patientID) // can be null
          if (subjectID === null) return;
          
          logger.debug("On-Request using subjectID: {}", subjectID)
          
          // add studies
          val studiesMap = patient.get("studies") as Map<String, Object>
          (studiesMap as Map<String, Object>).forEach[studyUID, studyValue |
            val study = (studyValue as Map<String, Object>)
            
            val studyDate = study.get("date") as LocalDate
            val studyID = store.STUDY.create(subjectID, studyUID, studyDate)
            store.PULL.these(requestID, studyID)
            
            // add series
            val seriesMap = study.get("series") as Map<String, Object>
            seriesMap.forEach[seriesUID, seriesValue |
              val series = (seriesValue as Map<String, Object>)
              
              val seq = series.get("number") as Integer
              val modality = series.get("modality") as String
              store.SERIES.create(studyID, seriesUID, seq, modality)
            ]
          ]
        ]
        
        store.PULL.status(requestID, Pull.Status.READY)
      } catch (Throwable ex) {
        store.LOG.exception(PullService, ex)
        store.PULL.error(requestID, ex.message)
      }
    ]
    
    return requests
  }
  
  def Long pull(Long requestID) {
    logger.info("On-Pull findID: {}", requestID)
    val data = store.PULL.data(requestID, Pull.Type.REQ)
    if (data.get("status") != Pull.Status.READY.name)
      throw new RuntimeException("On-Pull request not ready, requestID: " + requestID)
    
    val pullID = store.PULL.createPull(requestID)
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
                store.LOG.error(PullService, "Series status error series: " + seriesUID)
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
      store.LOG.exception(PullService, ex)
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
  
  private def String isEligible(DResult result) {
    //TODO: filter non eligible results. i.e filtering some manufacturers!
    
    // if non eligible, return a reason
    return null
  }
  
}