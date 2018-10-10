package dicom

import dicom.model.DField
import dicom.model.DQuery
import dicom.model.DResult
import java.util.ArrayList
import java.util.List
import org.dcm4che2.data.BasicDicomObject
import org.dcm4che2.data.DicomObject
import org.dcm4che2.data.UID
import org.dcm4che2.net.Association
import org.dcm4che2.net.CommandUtils
import org.dcm4che2.net.NetworkApplicationEntity
import org.dcm4che2.net.NetworkConnection
import org.dcm4che2.net.NewThreadExecutor
import org.slf4j.LoggerFactory

class DConnection {
  static val log = LoggerFactory.getLogger(DConnection)
  static val tsuid = UID.ImplicitVRLittleEndian
  
  public val String aet
  
  val con = new NetworkConnection()
  val ae = new NetworkApplicationEntity()
  var Association ass= null
  
  new(DLocal local, String remoteAet, String remoteHost, Integer remotePort) {
    this.aet = remoteAet
    
    con => [
      hostname = remoteHost
      port = remotePort
    ]
    
    ae => [
      AETitle = aet
      networkConnection = con
      installed = true
      associationAcceptor = true
    ]
    
    try {
      log.info("Trying to connect with {}", aet)
      ass = local.ae.connect(ae, new NewThreadExecutor(aet))
      log.info("Connected to {}", aet)
    } catch (Throwable ex) {
      log.error("Connection failed: {}", ex.message)
    }
  }
  
  def boolean echo() {
    if (ass === null)
      throw new RuntimeException("Connection association is down for " + aet)
    
    CommandUtils.setIncludeUIDinRSP(true)
    val rsp = ass.cecho(UID.StudyRootQueryRetrieveInformationModelFIND)
    
    return rsp.next
  }
  
  def List<DResult> find(DQuery queryObj, DField ...loadFields) {
    if (ass === null)
      throw new RuntimeException("Connection association is down for " + aet)
    
    val keys = new BasicDicomObject
    queryObj.copyTo(keys)
    
    //set the request fields from server
    val toLoad = if (loadFields.empty) queryObj.allFields else loadFields.toList
    for(f: toLoad)
      if(!keys.contains(f.tag))
        keys.putNull(f.tag, f.vr)
    
    val rsp = ass.cfind(UID.StudyRootQueryRetrieveInformationModelFIND, 0, keys, tsuid, Integer.MAX_VALUE)
    
    val result = new ArrayList<DicomObject>
    while (rsp.next) {
      if (CommandUtils.isPending(rsp.command)) {
        //println(rsp)
        result.add(rsp.dataset)
      }
    }
    
    return result.map[ new DResult(it) ]
  }
  
  def void close() {
    ass?.release(false)
    con.unbind()
    log.info(" {}", aet)
  }
}