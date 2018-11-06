package base

import db.Pull
import db.Store
import dicom.DLocal
import dicom.model.DImage
import dicom.model.DPatient
import dicom.model.DQuery
import dicom.model.DSeries
import dicom.model.DStudy
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.List
import java.util.Map
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.slf4j.LoggerFactory
import service.PullService
import service.PushService
import service.TransmitService
import java.util.HashSet

class Server {
  static val logger = LoggerFactory.getLogger(Server)
  static val formatter = DateTimeFormatter.ofPattern("yyyyMMdd")
  
  val Store store
  val TransmitService transSrv 
  
  val PullService pullSrv
  val PushService pushSrv
  
  new() {this(null)}
  new(String ethName) {
    this.store = Store.setup
    this.transSrv = new TransmitService
    
    if(ethName !== null)
      store.KEY.set("local-aet", "eth-name", ethName) 
    
    this.pullSrv = new PullService(store)
    this.pushSrv = new PushService(store, transSrv)
  }
  
  def run(boolean noSchedule) {
    if (!noSchedule) {
      val pullInterval = store.KEY.get(Integer, "pull", "interval")
      val pushInterval = store.KEY.get(Integer, "push", "interval")
      
      // TODO: set initialDelay to synchronize with a certain day time?
      
      Executors.newScheduledThreadPool(1) => [
        scheduleAtFixedRate([this.pullTask], 0, pullInterval, TimeUnit.HOURS)
        Runtime.runtime.addShutdownHook(new Thread[shutdownNow])
      ]
      
      Executors.newScheduledThreadPool(1) => [
        scheduleAtFixedRate([this.pushTask], 0, pushInterval, TimeUnit.HOURS)
        Runtime.runtime.addShutdownHook(new Thread[shutdownNow])
      ]  
    }
    
    // setup REST services
    new WebServer(store).setup
  }
  
  def void pullTask() {
    val day = LocalDate.now.format(formatter)
    logger.info("Starting scheduled pull-tasks. Pulling day: {}", day)
    
    val query = new DQuery => [set(DStudy.DATE, day)]
    val result = pullSrv.find(query)
    
    new HashSet<Long> => [
      addAll(store.PULL.pending)
      addAll(pullSrv.pullRequests(result))
      forEach[pullSrv.pull(it)]
    ]
  }
  
  def void pushTask() {
    logger.info("Starting scheduled push-tasks.")
    
    new HashSet<Long> => [
      addAll(store.PUSH.pending)
      addAll(pushSrv.pushRequests)
      forEach[pushSrv.push(it)]
    ]
  }
  
  static def void test() {
    //System.securityManager.
    
    /*Security.addProvider(new BouncyCastleProvider)
    
    val kp = new KeyPairHelper()
    kp.genKeyPair*/
    
    //setupSubject
    //testFind
    testPull
    //testPush
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
    store.TARGET.pendingData.forEach[
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
    
    /*println("Last Logs: ")
    store.logs.forEach[
      println(it)
    ]
    */
    
    store.cypher("MATCH (n:Log) DELETE n")
    store.cypher("MATCH (n:Pull) DETACH DELETE n")
    store.cypher("MATCH (n:Study) DETACH DELETE n")
    store.cypher("MATCH (n:Series) DETACH DELETE n")
    store.cypher("MATCH (n:Item) DETACH DELETE n")
    
    val pullSrv = new PullService(store)
    val result = pullSrv.find(new DQuery => [set(DStudy.DATE, "20170130")])
    
    pullSrv.pullRequests(result).forEach[
      println("Request-ID: " + it)
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