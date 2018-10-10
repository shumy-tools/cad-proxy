package dicom

import org.dcm4che2.data.DicomObject
import org.dcm4che2.net.Association
import org.dcm4che2.net.PDVInputStream
import org.dcm4che2.net.service.StorageService
import org.slf4j.LoggerFactory

class DStorage extends StorageService {
  static val log = LoggerFactory.getLogger(DStorage)
  
  val String path
  
  new(String path) {
    super(DCapabilities.STORE_CUIDS)
    this.path = path
  }
  
  override protected onCStoreRQ(Association ass, int pcid, DicomObject rq, PDVInputStream dataStream, String tsuid, DicomObject rsp) {
    log.debug("C-STORE-RQ => {} {}", pcid, rq)
    //val iuid = rq.getString(Tag.AffectedSOPInstanceUID)
    //val cuid = rq.getString(Tag.AffectedSOPClassUID)
  }
  
}