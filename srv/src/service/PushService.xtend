package service

import db.Push
import db.Store
import java.io.FileInputStream
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import java.util.zip.Deflater
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory

@FinalFieldsConstructor
class PushService {
  static val logger = LoggerFactory.getLogger(PushService)
  
  val Store store
  val TransmitService transmit
  
  //TODO: move this to a DB config. Load on PullService instantiation.
  val cachePath = "./data/cache"
  
  def Set<Long> pushRequests() {
    val requests = new HashSet<Long>
    store.TARGET.pendingData.forEach[
      val targetID = get("id") as Long
      val seriesIDs = get("series") as List<Long>
      requests.add(store.PUSH.create(targetID, seriesIDs.toSet))
    ]
    
    return requests
  }
  
  def void push(Long pushID) {
    logger.info("On-Push pushID: {}", pushID)
    val data = store.PUSH.data(pushID)
    if (data.get("status") != Push.Status.START.name)
      throw new RuntimeException("On-Push request not started, pushID: " + pushID)
    
    
    //TODO: if Push-RETRY verify if series are archived! Pull series again, on manual request?
    
    val targetUDI = data.get("target") as String
    val series = data.get("series") as List<Map<String, Object>>
    
    // prepare zip output
    val zipFile = prepare(pushID, targetUDI, series)
    
    // transmit
    transmit(pushID, zipFile)
    
    //TODO: if transmission OK, set Push-END
  }
  
  private def prepare(Long pushID, String targetUDI, List<Map<String, Object>> series) {
    store.PUSH.status(pushID, Push.Status.PREPARE)
    
    // zip files for each subject
    val buffer = newByteArrayOfSize(1024*1024)
    val os = transmit.push(targetUDI, pushID)
    val zipFile = new ZipOutputStream(os) => [
      //TODO: compression should depend of the DICOM raw data type. i.e. if already compressed the level should be BEST_SPEED
      level = Deflater.BEST_SPEED
    ]
    
    val subjects = new HashMap<String, Set<Long>>
    series.forEach[
      val seriesID = get("id") as Long
      val subjectUDI = get("subject") as String
      
      // aggregate series from subject
      val seriesList = subjects.get(subjectUDI)?: {
        val sl = new HashSet<Long>
        subjects.put(subjectUDI, sl)
        sl
      }
      seriesList.add(seriesID)
      
      // put series entry
      val seriesPath = "/s" + seriesID + "/" 
      store.SERIES.items(seriesID).forEach[
        val imageSeq = get("seq") as Integer
        val imagePath = imageSeq + 'i.dcm'
        
        zipFile.putNextEntry(new ZipEntry(seriesPath + imagePath))
          val filePath = cachePath + seriesPath + imagePath
          zipFile.zipAddFile(filePath, buffer)
        zipFile.closeEntry
      ]
    ]
    
    val info = '''
    {
      «FOR udi : subjects.keySet SEPARATOR ","»
        "«udi»": [«FOR seriesID: subjects.get(udi) SEPARATOR ","»"s«seriesID»"«ENDFOR»]
      «ENDFOR»
    }
    '''
    
    zipFile.putNextEntry(new ZipEntry("info.json"))
      zipFile.write(info.bytes)
    zipFile.closeEntry
    
    return zipFile
  }
  
  private def transmit(Long pushID, ZipOutputStream zipFile) {
    store.PUSH.status(pushID, Push.Status.TRANSMIT)
    
    zipFile => [ flush close ]
  }
  
  private def zipAddFile(ZipOutputStream zipFile, String path, byte[] buffer) {
    val ins = new FileInputStream(path)
    
    var bytesRead = -1
    while ((bytesRead = ins.read(buffer)) !== -1)
      zipFile.write(buffer, 0, bytesRead)
      
    ins.close
  }
}