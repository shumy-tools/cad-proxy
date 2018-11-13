import base.SecurityPolicy
import base.Server
import db.Pull
import db.Store
import db.mng.Key
import dicom.DLocal
import dicom.model.DImage
import dicom.model.DPatient
import dicom.model.DQuery
import dicom.model.DSeries
import dicom.model.DStudy
import java.io.File
import java.security.Policy
import java.util.List
import java.util.Map
import java.util.UUID
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters
import service.PullService
import service.PushService
import service.TransmitService

import static java.security.Policy.*

@Command(
  name = "cadp", footer = "Copyright(c) 2017",
  description = "CAD-Proxy CLI Helper"
)
class RCommand {
  @Parameters(arity = "0..1", paramLabel = "DATA-PATH", description = "Relative path of the data directory.")
  public String path
  
  @Option(names = #["-h", "--help"], help = true, description = "Display this help and exit.")
  public boolean help
  
  @Option(names = #["--stack"], help = true, description = "Display the stack-trace error if any.")
  public boolean stack
  
  @Option(names = #["-s", "--server"], help = true, description = "Run the server.")
  public boolean server
  
  @Option(names = #["-ns", "--no-schedule"], help = true, description = "Disable pull/push scheduled tasks.")
  public boolean noSchedule
  
  @Option(names = #["--key-list"], help = true, description = "List all configuration keys. Order by group.")
  public boolean keyList
  
  @Option(names = #["--key-reset"], help = true, description = "Reset all configuration keys to default.")
  public boolean keyReset
  
  @Option(names = #["--eth"], help = true, description = "Ethernet interface to use for the local DICOM storage service.")
  public String ethName
}

class CadProxyCLI {
  def static void main(String[] args) {
    Policy.policy = SecurityPolicy.CURRENT
    
    val cmd =  try {
      CommandLine.populateCommand(new RCommand, args)
    } catch (Throwable ex) {
      CommandLine.usage(new RCommand, System.out)
      return
    }
    
    val basePath = (cmd.path?: "data")
    if (basePath.startsWith(File.separator))
      throw new RuntimeException("DATA-PATH is a relative path!")
    
    val dataPath = System.getProperty("user.dir") + "/" + basePath
    val dbPath = dataPath + "/db"
    
    System.setProperty("dataPath", dataPath)
    System.setProperty("dbPath", dbPath)
    
    try {
      if (cmd.help) {
        CommandLine.usage(cmd, System.out)
        return
      }
      
       if (cmd.keyReset) {
        keyReset
        return
      }
      
      if (cmd.keyList) {
        keyList
        return
      }
      
      if (cmd.server) {
        new Server(cmd.ethName).run(cmd.noSchedule)
        return
      }
    } catch (Throwable ex) {
      if (cmd.stack)
        ex.printStackTrace
      else
        println(ex.message)
    }
  }

  def static void keyReset() {
    val store = Store.setup
    store.cypher('''MATCH (n:«Key.NODE») DETACH DELETE n''')
    store.KEY.setupDefault
  }
  
  def static void keyList() {
    val store = Store.setup
    store.KEY.all.forEach[
      println('''(«Key.GROUP»=«get(Key.GROUP)», «Key.KEY»=«get(Key.KEY)», «Key.VALUE»=«get(Key.VALUE)»), «Key.ACTIVE»=«get(Key.ACTIVE)»)''')
    ]
  }
  
  
  static def void setTargets() {
    val store = Store.setup
    store.cypher("MATCH (n:Subject) WHERE n.udi IS NULL DETACH DELETE n")
    store.cypher("MATCH (n:Target) DETACH DELETE n")
    
    store.TARGET.create(UUID.randomUUID.toString, "t1", #{ "XC" })
    store.TARGET.create(UUID.randomUUID.toString, "t2", #{ "CT" })
    store.TARGET.create(UUID.randomUUID.toString, "t3", #{ "XC", "CT" })
    
    store.cypher("MATCH (u:Subject), (t:Target) MERGE (u)-[:CONSENT]->(t)")
    store.cypher("MATCH (:Subject)-[:CONSENT]->(t:Target) RETURN t { .* }").forEach[
      println(it)
    ]
  }
  
  static def void setupSubject() {
    val store = Store.setup
    
    store.cypher("MATCH (n:Patient) DETACH DELETE n")
    store.cypher("MATCH (n:Subject) DETACH DELETE n")
    
    val sourceID = store.SOURCE.idFromAET("DICOOGLE-STORAGE")
    val subjectID = store.SUBJECT.create(UUID.randomUUID.toString)
    
    //consent all targets
    store.TARGET.all.forEach[
      store.SUBJECT.consent(subjectID, get("id") as Long)
    ]
    
    val dSrv = new DLocal("MICAEL", "192.168.21.250", 1104, null)
    val con = dSrv.connect("DICOOGLE-STORAGE", "192.168.21.250", 1045)
    
    con.find(new DQuery, DPatient.ID, DPatient.SEX, DPatient.BIRTHDAY).forEach[
      val patientID = store.PATIENT.create(sourceID, get(DPatient.ID), get(DPatient.SEX), get(DPatient.BIRTHDAY))
      store.SUBJECT.is(subjectID, patientID)
    ]
    
    con.close
    
    println("Subjects: ")
    store.cypher("MATCH (n:Subject) RETURN id(n) as id, [(n)-[:IS]->(p:Patient) | p { .pid, .sex, .birthday }] as is").forEach[
      println(it)
    ]
  }
  
  static def void testFind() {
    val store = Store.setup
    val pullSrv = new PullService(store)
    
    val query = new DQuery => [set(DStudy.DATE, "20170130")]
    println(pullSrv.find(query))
  }
  
  static def void testPush() {
    val store = Store.setup
    
    //store.cypher("MATCH (:Subject)-[c:CONSENT]->(:Target) DELETE c")
    //store.cypher("MERGE (s:Subject)-[:CONSENT]->(t:Target)")
    //store.cypher("MATCH (s:Subject),(t:Target) CREATE (s)-[:CONSENT]->(t)")
    //store.cypher("MATCH (s:Subject)-[:CONSENT]->(t:Target) RETURN id(s), id(t)").forEach[println(it)]
    
    
    /*store.cypher('''
      MATCH (n:Target), (e:Series) WHERE id(n) = 1 AND id(e) = 358
      CREATE (n)<-[:TO]-(:Push {status:"RETRY"})-[:THESE]->(e)
    ''')*/
    
    //store.cypher("MATCH (n:Target) WHERE n.name IS NULL DETACH DELETE n")
    
    store.cypher("MATCH (n:Push) DETACH DELETE n")
    
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
    store.TARGET.pendingSeries.forEach[
      println(it)
    ]
    
    val transSrv = new TransmitService
    val pushSrv = new PushService(store, transSrv)
    pushSrv.pushRequests.forEach[
      println("Push-ID: " + it)
      println(store.PUSH.data(it))
      pushSrv.push(it)
    ]
    
    /*println("Pending: ")
    store.TARGET.pendingData.forEach[
      println(it)
    ]*/
  }
  
  static def void testPull() {
    val store = Store.setup
    
    store.cypher("MATCH (n:Log) DELETE n")
    store.cypher("MATCH (n:Pull) DETACH DELETE n")
    store.cypher("MATCH (n:Push) DETACH DELETE n")
    store.cypher("MATCH (n:Study) DETACH DELETE n")
    store.cypher("MATCH (n:Series) DETACH DELETE n")
    store.cypher("MATCH (n:Item) DETACH DELETE n")
    
    val pullSrv = new PullService(store)
    val result = pullSrv.find(new DQuery => [set(DStudy.DATE, "20170130")])
    
    pullSrv.pullRequests(result).forEach[
      println("Request-ID: " + it)
      //println(store.PULL.data(it, Pull.Type.REQ))
      
      val pullID = pullSrv.pull(it)
      
      val data = store.PULL.data(pullID, Pull.Type.PULL)
      println('''Pull-Data: (source=«data.get("source")», status=«data.get("status")»)''')
      
      val studies = data.get("studies") as List<Map<String, Object>>
      studies.forEach[
        val series = get("series") as List<Map<String, Object>>
        series.forEach[
          println('''  SERIES (id=«get("id")», udi=«get("uid")», size=«get("size")», modality=«get("modality")»)''')
        ]
      ]
    ]
    
    println("Pulls: ")
    store.cypher("MATCH (n:Pull)-[:FROM]->(l) RETURN id(n), n.type, n.status, n.pullTries, id(l)").forEach[
      println(it)
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