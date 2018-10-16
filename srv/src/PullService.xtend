import db.Store
import db.Pull
import dicom.DLocal
import dicom.model.DImage
import dicom.model.DPatient
import dicom.model.DSeries
import dicom.model.DStudy
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.util.HashMap
import org.slf4j.LoggerFactory
import java.util.Set

class PullService {
  static val logger = LoggerFactory.getLogger(PullService)
  
  
  val Store store
  val DLocal local
  
  new(Store store, String localAET, String localIP) {
    this.store = store
    this.local = new DLocal(localAET, localIP, 1104)[
      println('''STORE: «get(DImage.UID)» - «get(DSeries.MODALITY)»''')
    ]
  }
  
  def Set<Long> find(LocalDate day) {
    val modalities = store.TARGET.modalities
    logger.info("On-Find using modalities: {}", modalities)
    
    return store.SOURCE.pullThrottle.map[
      val sourceID = get("id") as Long
      val pullID = store.PULL.create(sourceID, Pull.Type.FIND)
      
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
          val studyID = store.STUDY.create(subjectID, studyUID, get(DStudy.DATE).date)
          logger.debug("On-Find inserted study: {}", studyUID)
          studies.put(studyUID, studyID)
        ]
        
        store.PULL.linkStudies(pullID, studies.values)
        
        val seriesRes = con.findDaySeries(day)
        logger.info("On-Find {} series results for day: {}", studyRes.size, day)
        
        seriesRes.filter[ modalities.contains(get(DSeries.MODALITY)) ].forEach[
          val studyUID = get(DStudy.UID)
          val studyID = studies.get(studyUID)
          if (studyID === null) return
          
          // create series
          val sdt = LocalDateTime.of(get(DSeries.DATE).date, get(DSeries.TIME).time)
          val seriesUID = get(DSeries.UID)
          store.SERIES.create(studyID, seriesUID, get(DSeries.NUMBER), get(DSeries.MODALITY), sdt)
          logger.debug("On-Find inserted series: {}", seriesUID)
        ]
        
        store.PULL.status(pullID, Pull.Status.END)
        con.close
      } catch (Throwable ex) {
        ex.printStackTrace
        store.PULL.error(pullID, ex.message)
      }
      
      return pullID
    ].toSet
  }
  
  private def date(String dateTxt) {
    var date = dateTxt?:'00000101'
    if (date.length > 8)
      date = date.substring(0, 8)
      
    LocalDate.parse(date, DateTimeFormatter.BASIC_ISO_DATE)
  }
  
  private def time(String timeTxt) {
    var time = timeTxt?:'000000'
    if (time.length > 10)
      time = time.substring(0, 10)
    
    return LocalTime.parse(time, DateTimeFormatter.ofPattern('HHmmss[.SSS]'))
  }
  
  /*private def filter(List<DResult> results) {
    //TODO: filter non eligible results. i.e remove disabled patients
    return res
  }*/
}