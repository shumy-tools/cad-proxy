package dicom

import base.SecurityPolicy
import dicom.model.DResult
import java.net.SocketPermission
import java.util.ArrayList
import org.dcm4che2.net.Device
import org.dcm4che2.net.NetworkApplicationEntity
import org.dcm4che2.net.NetworkConnection
import org.dcm4che2.net.NewThreadExecutor
import org.slf4j.LoggerFactory

class DLocal {
  static val log = LoggerFactory.getLogger(DLocal)
  
  public val String aet
  
  val con = new NetworkConnection()
  package val ae = new NetworkApplicationEntity()
  val dev = new Device()
  
  val conns = new ArrayList<DConnection>
  
  new(String localAet, Integer localPort, (DResult) => void onStore) {
    this(localAet, "127.0.0.1", localPort, onStore)
  }
  
  new(String localAet, String localHost, Integer localPort, (DResult) => void onStore) {
    this.aet = localAet
    
    SecurityPolicy.CURRENT
      .addPermission("dcm4che", new SocketPermission(localHost + ":" + localPort, "listen,resolve"))
      .addPermission("dcm4che", new SocketPermission("*:" + localPort, "listen,resolve"))
      .addPermission("dcm4che", new SocketPermission("*:0", "accept,resolve"))
    
    con => [
      hostname = localHost
      port = localPort
    ]
    
    ae => [
      AETitle = aet
      networkConnection = con
      associationInitiator = true
      associationAcceptor = true
      transferCapability = DCapabilities.TCS
      register = new DStorage(onStore)
    ]
    
    dev => [
      networkApplicationEntity = ae
      networkConnection = con
    ]

    con.bind(new NewThreadExecutor(aet))
    while (!con.isListening()) {
      log.info("Waiting for local {} listening state", aet)
      Thread.sleep(500)
    }
    
    log.info("Local {} is up", aet)
    Runtime.getRuntime().addShutdownHook(new Thread[
      this.close
    ])
  }
  
  def connect(String srvAet, String srvHost, Integer srvPort) {
    val newCon = new DConnection(this, srvAet, srvHost, srvPort)
    conns.add(newCon)
    return newCon
  }

  def void close() {
    conns.forEach[close]
    conns.clear

    con.unbind()
    log.info("Closed {}", aet)
  }
}