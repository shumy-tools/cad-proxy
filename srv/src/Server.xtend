import db.Store
import db.Pull
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
    testPull
    //testDicom
  }
  
  static def void testPull() {
    val store = Store.setup(true)
    //store.SUBJECT.create(2L, UUID.randomUUID.toString, "Z0VYEYND6669", "M", LocalDate.parse("1956-02-21"))
    
    store.cypher("MATCH (n:Pull) DETACH DELETE n")
    store.cypher("MATCH (n:Study) DETACH DELETE n")
    store.cypher("MATCH (n:Series) DETACH DELETE n")
    store.cypher("MATCH (n:Item) DETACH DELETE n")
    
    val pullSrv = new PullService(store, "MICAEL", "192.168.21.250") 
    pullSrv.find(LocalDate.parse("2017-01-30")).forEach[
      println("Find-ID: " + it)
      println(store.PULL.data(it, Pull.Type.FIND))
      
      val pullID = pullSrv.pull(it)
      println("Pulls: ")
      store.cypher("MATCH (n:Pull)-[:FROM]->(l) RETURN id(n), n.type, n.status, id(l)").forEach[
        println(it)
      ]
      
      println(store.PULL.data(pullID, Pull.Type.STORE))
    ]
  }
  
  static def void testDicom() {
    val port = 1104
    
    val dSrv = new DLocal("MICAEL", "192.168.21.250", port) [
      println('''STORE: «get(DStudy.UID)» - «get(DSeries.UID)» - «get(DImage.NUMBER)» - «get(DSeries.MODALITY)»''')
    ]
    
    val con = dSrv.connect("DICOOGLE-STORAGE", "192.168.21.250", 1045)
    
    val query = new DQuery(DStudy.RL) => [
      set(DSeries.MODALITY, "XC")
    ]
    
    val result = con.find(query, DPatient.ID, DStudy.UID, DSeries.UID, DStudy.SERIES_COUNT)
    println("RESULTS: " + result.length)
    /*result.forEach[
      println(it)
    ]*/
    
    /*con.pull("1.2.826.0.1.3680043.2.1174.4.1.5.2376753")[
      println('''STATUS: «status»''')
    ]*/
    
    con.pull("1.2.826.0.1.3680043.2.1174.4.1.5.2376752", "1.2.392.200046.100.3.8.103441.9122.20170130144904.2")[
      println('''STATUS: «status»''')
    ]
  }
}