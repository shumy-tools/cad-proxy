package dicom

import dicom.model.DResult
import org.dcm4che2.data.DicomObject
import org.dcm4che2.data.Tag
import org.dcm4che2.net.Association
import org.dcm4che2.net.PDVInputStream
import org.dcm4che2.net.service.StorageService
import org.slf4j.LoggerFactory

class DStorage extends StorageService {
  static val log = LoggerFactory.getLogger(DStorage)
  
  val (DResult) => void onStore
  
  new((DResult) => void onStore) {
    super(DCapabilities.STORE_CUIDS)
    this.onStore = onStore
  }
  
  override protected onCStoreRQ(Association ass, int pcid, DicomObject rq, PDVInputStream dataStream, String tsuid, DicomObject rsp) {
    log.debug("Store {}", rq)
    val iuid = rq.getString(Tag.AffectedSOPInstanceUID)
    val cuid = rq.getString(Tag.AffectedSOPClassUID)
    
    val obj = dataStream.readDataset
    obj.initFileMetaInformation(cuid, iuid, tsuid)
    
    if(cuid !== null && DCapabilities.STORE_CUIDS.contains(cuid)){
      val res = new DResult(obj)
      onStore.apply(res)
    } else
      log.warn("Unsupported CUID: " + cuid)
  }
}