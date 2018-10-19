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
import java.util.List
import java.util.Map

class Server {
  static val log = LoggerFactory.getLogger(Server)
  
  def static void main(String[] args) {
    testPull
    //testPendingData
    //testDicom
    
    //1.2.826.0.1.3680043.2.1174.4.1.5.2572560 -> 56f3c197-53f8-4d08-95e1-9c3868b58b90
    /*val store = Store.setup(true)
    println(store.cypher('''
      MATCH (p:Subject)-[:HAS]->(s:Study)
        WHERE s.uid = "1.2.826.0.1.3680043.2.1174.4.1.5.2572560"
      RETURN s.uid as study, p.udi as subject
    ''').head)
    */
  }
  
  static def void insertSubjects(Store store) {
    val dSrv = new DLocal("MICAEL", "192.168.21.250", 1104, null)
    val con = dSrv.connect("DICOOGLE-STORAGE", "192.168.21.250", 1045)
    
    val query = new DQuery(DPatient.RL)
    con.find(query, DPatient.ID, DPatient.SEX, DPatient.BIRTHDATE).forEach[
      store.SUBJECT.create(2L, UUID.randomUUID.toString, get(DPatient.ID), get(DPatient.SEX), get(DPatient.BIRTHDATE))
    ]
    
    con.close
    
    println("Subjects: ")
    store.cypher("MATCH (n:Subject) RETURN id(n), n.pid, n.birthday, n.sex").forEach[
      println(it)
    ]
  }
  
  static def void testPendingData() {
    val store = Store.setup(true)
    
    //store.cypher("MATCH (:Subject)-[c:CONSENT]->(:Target) DELETE c")
    //store.cypher("MERGE (s:Subject)-[:CONSENT]->(t:Target)")
    //store.cypher("MATCH (s:Subject),(t:Target) CREATE (s)-[:CONSENT]->(t)")
    //store.cypher("MATCH (s:Subject)-[:CONSENT]->(t:Target) RETURN id(s), id(t)").forEach[println(it)]
    
    
    /*store.cypher('''
      MATCH (n:Target), (e:Series) WHERE id(n) = 1 AND id(e) = 358
      CREATE (n)<-[:TO]-(:Push {status:"RETRY"})-[:THESE]->(e)
    ''')*/
    
    //store.cypher("MATCH (n:Target) WHERE n.name IS NULL DETACH DELETE n")
    
    println("Targets: ")
    store.TARGET.all.forEach[
      print(it + " -> [ ")
      (get("modalities") as String[]).forEach[
        print(it + " ")
      ]
      println("]")
    ]
    
    // Pull(1, 330, END), Pull(1, 357, ERROR), Pull(1, 358, RETRY)
    // expected {id=1, series=[284, 303, 320, 344, 358, 374]}
    println("Pending: ")
    store.TARGET.pendingData.forEach[
      println(it)
    ]
  }
  
  static def void testPull() {
    val store = Store.setup(true)
    
    /*println("Last Logs: ")
    store.logs.forEach[
      println(it)
    ]
    
    store.cypher("MATCH (n:Log) DELETE n")
    */
    
    //store.cypher("MATCH (n:Subject) DETACH DELETE n")
    store.cypher("MATCH (n:Pull) DETACH DELETE n")
    store.cypher("MATCH (n:Study) DETACH DELETE n")
    store.cypher("MATCH (n:Series) DETACH DELETE n")
    store.cypher("MATCH (n:Item) DETACH DELETE n")
    
    //store.insertSubjects
    
    val pullSrv = new PullService(store, "MICAEL", "192.168.21.250") 
    pullSrv.pullRequest(LocalDate.parse("2017-01-30")).forEach[
      println("Find-ID: " + it)
      println(store.PULL.data(it, Pull.Type.REQ))
      
      val pullID = pullSrv.pull(it)
      println("Pulls: ")
      store.cypher("MATCH (n:Pull)-[:FROM]->(l) RETURN id(n), n.type, n.status, n.pullTries, id(l)").forEach[
        println(it)
      ]
      
      val studies = store.PULL.data(pullID, Pull.Type.PULL).get("studies") as List<Map>
      studies.forEach[
        val series = get("series") as List<Map>
        series.forEach[
          val size = get("size") as Long
          if (size > 0)
            println('''SERIES (id=«get("id")», udi=«get("uid")», size=«size», modality=«get("modality")»)''')
        ]
      ]
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