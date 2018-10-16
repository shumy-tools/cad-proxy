import db.Store
import dicom.DLocal
import dicom.model.DImage
import dicom.model.DPatient
import dicom.model.DQuery
import dicom.model.DSeries
import dicom.model.DStudy
import org.slf4j.LoggerFactory
import java.util.UUID
import java.time.LocalDate

class Server {
  static val log = LoggerFactory.getLogger(Server)
  
  def static void main(String[] args) {
    //test()
    
    val store = Store.setup(true)
    //store.SUBJECT.create(2L, UUID.randomUUID.toString, "Z0VYEYND6669", "M", LocalDate.parse("1956-02-21"))
    
    store.cypher("MATCH (n:Pull) DETACH DELETE n")
    store.cypher("MATCH (n:Study) DETACH DELETE n")
    store.cypher("MATCH (n:Series) DETACH DELETE n")
    
    val pullSrv = new PullService(store, "MICAEL", "192.168.21.250") 
    pullSrv.find(LocalDate.parse("2017-01-30")).forEach[
      println("Pull-ID: " + it)
      store.PULL.data(it).forEach[println("Study: " + it)]
    ]
  }
  
  static def void test() {
    //val storePath = "./dcm-store"
    val port = 1104
    
    val dSrv = new DLocal("MICAEL", "192.168.21.250", port) [
      println('''STORE: «get(DImage.UID)» - «get(DSeries.MODALITY)»''')
    ]
    
    val con = dSrv.connect("DICOOGLE-STORAGE", "192.168.21.250", 1045)
    
    val query = new DQuery(DStudy.RL) => [
      set(DStudy.UID, "1.2.826.0.1.3680043.2.1174.4.1.5.2376752")
      set(DSeries.MODALITY, "XC")
    ]
    
    val result = con.find(query, DPatient.ID, DStudy.UID, DSeries.UID, DStudy.DATE, DSeries.MODALITY, DSeries.NUMBER, DSeries.DATE, DSeries.TIME)
    println("RESULTS: " + result.length)
    result.forEach[
      println(it)
    ]
    
    con.pull("1.2.826.0.1.3680043.2.1174.4.1.5.2376752")[
      println('''STATUS: «status»''')
    ]
  }
}