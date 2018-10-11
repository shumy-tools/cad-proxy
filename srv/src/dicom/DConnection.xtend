package dicom

import dicom.model.DField
import dicom.model.DQuery
import dicom.model.DResult
import dicom.model.DStudy
import java.util.ArrayList
import java.util.List
import org.dcm4che2.data.BasicDicomObject
import org.dcm4che2.data.DicomObject
import org.dcm4che2.data.Tag
import org.dcm4che2.data.UID
import org.dcm4che2.net.Association
import org.dcm4che2.net.CommandUtils
import org.dcm4che2.net.DimseRSPHandler
import org.dcm4che2.net.NetworkApplicationEntity
import org.dcm4che2.net.NetworkConnection
import org.dcm4che2.net.NewThreadExecutor
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory

class DConnection {
  static val log = LoggerFactory.getLogger(DConnection)
  static val tsuid = UID.ImplicitVRLittleEndian
  
  public val String aet
  
  val DLocal local
  val con = new NetworkConnection()
  val ae = new NetworkApplicationEntity()
  var Association ass = null
  
  new(DLocal local, String remoteAet, String remoteHost, Integer remotePort) {
    this.local = local
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
  }
  
  private def boolean prepareLink() {
    if (ass === null || !ass.readyForDataTransfer) {
      ass = local.ae.connect(ae, new NewThreadExecutor(aet))
      log.info("Connected and ready to {}", aet)
    }
    
    return true
  }
  
  def boolean echo() {
    prepareLink
    
    CommandUtils.setIncludeUIDinRSP(true)
    val rsp = ass.cecho(UID.StudyRootQueryRetrieveInformationModelFIND)
    
    return rsp.next
  }
  
  def List<DResult> find(DQuery query, DField ...retrieveFields) {
    prepareLink
    
    val keys = new BasicDicomObject
    query.copyTo(keys)
    
    //set the request fields from server
    val toLoad = if (retrieveFields.empty) query.defaults else retrieveFields.toList
    for(f: toLoad)
      if(!keys.contains(f.tag))
        keys.putNull(f.tag, f.vr)
    
    val rsp = ass.cfind(UID.StudyRootQueryRetrieveInformationModelFIND, 0, keys, tsuid, Integer.MAX_VALUE)
    
    val result = new ArrayList<DicomObject>
    while (rsp.next) {
      if (CommandUtils.isPending(rsp.command))
        result.add(rsp.dataset)
    }
    
    return result.map[ new DResult(it) ]
  }
  
  def void pull(String suid) {
    pull(suid, null)
  }
  
  def void pull(String suid, (Pull) => void onPull) {
    prepareLink
    
    val query = new DQuery(DStudy.RL) => [ set(DStudy.UID, suid) ]
    val mh = new MoveHandler(suid, onPull)
    ass.cmove(UID.StudyRootQueryRetrieveInformationModelMOVE, 0, query.obj, tsuid, local.aet, mh)
  }
  
  def void close() {
    if (ass !== null && ass.readyForDataTransfer)
      ass.release(false)
      
    con.unbind()
    log.info(" {}", aet)
  }
}

@FinalFieldsConstructor
class Pull {
  enum Status { OK, COMPLETED, ERROR }
  
  public val Status status
  public val Integer dicomErrorCode
}

@FinalFieldsConstructor
class MoveHandler extends DimseRSPHandler {
  static val log = LoggerFactory.getLogger(MoveHandler)
  
  val String suid
  val (Pull) => void onPull
  
  override onDimseRSP(Association ass, DicomObject cmd, DicomObject data) {
    val status = cmd.getInt(Tag.Status)
    
    switch status {
      case 0: {
        val remaining = cmd.getInt(Tag.NumberOfRemainingSuboperations)
        if(remaining != 0) {
          log.debug("Move on Study {}: {}", suid, remaining)
          onPull?.apply(new Pull(Pull.Status.OK, 0))
        } else {
          log.debug("Move completed on Study {}", suid)
          onPull?.apply(new Pull(Pull.Status.COMPLETED, 0))
        }
      }
      
      case 65280: log.debug("Move pending on Study {}", suid)
      
      default: {
        log.error("Move error on Study {}", suid)
        onPull?.apply(new Pull(Pull.Status.ERROR, status))
      }
    }
  }
}