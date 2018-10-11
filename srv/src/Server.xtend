import dicom.DLocal
import dicom.model.DQuery
import dicom.model.DSerie
import dicom.model.DStudy
import org.slf4j.LoggerFactory

class Server {
  static val log = LoggerFactory.getLogger(Server)
  
  def static void main(String[] args) {
    //val storePath = "./dcm-store"
    val port = 1104
    
    val dSrv = new DLocal("MICAEL", "192.168.21.250", port) [
      println('''STORE: «get(DStudy.UID)» - «get(DSerie.UID)» - «get(DSerie.MODALITY)»''')
    ]
    
    val con = dSrv.connect("DICOOGLE-STORAGE", "192.168.21.250", 1045)
    
    val query = new DQuery(DSerie.RL) => [
      set(DStudy.DATE, "20170207")
    ]
    
    val result = con.find(query, DStudy.UID, DSerie.UID, DSerie.MODALITY)
    println("RESULTS: " + result.length)
    result.forEach[
      println(it)
    ]
    
    val t1 = new Thread[
      con.pull("1.2.826.0.1.3680043.2.1174.4.1.5.2584739")[
        println('''STATUS: «status»''')
      ]
    ]
    
    val t2 = new Thread[
      con.pull("1.2.826.0.1.3680043.2.1174.4.1.5.2584739")
    ]
    
    t1.run
    t2.run
  }
}