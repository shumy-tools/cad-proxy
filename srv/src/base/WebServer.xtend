package base

import db.Store
import dicom.model.DQuery
import java.util.Collections
import java.util.List
import java.util.Map
import org.slf4j.LoggerFactory
import service.PullService
import service.PushService
import spark.Request

import static spark.Spark.*
import java.util.HashMap

class WebServer {
  static val logger = LoggerFactory.getLogger(WebServer)
  
  val Store store
  val PullService pullSrv
  val PushService pushSrv
  
  val List<String> excludedKeys 
  val json = new JsonTransformer
  
  val tagConverter = #{
    "pid" -> "PatientID",
    "name" -> "PatientName",
    "sex" -> "PatientSex",
    "birthday" -> "PatientBirthDate"
  } 
  
  enum NodeType { SUBJECT, PULL, PUSH }
  
  new(Store store, PullService pullSrv, PushService pushSrv) {
    this.store = store
    this.pullSrv = pullSrv
    this.pushSrv = pushSrv
    
    val write = Boolean.getBoolean("write")
    this.excludedKeys = if (write)
      #[ "drop", "call", "load", "detach", "cypher", "using" ]
      else
      #[ "create", "merge", "delete", "remove", "set", "drop", "call", "load", "detach", "cypher", "using" ]
  }
  
  def getSubject(Request req) {
    // parameter parser and validation
    val udi = req.params("udi")
    if (udi === null)
      halt(400, "Invalid parameters!")
      
    store.SUBJECT.get(udi)
  }
  
  def subjectAddAssociation(Request req) {
    val it = json.parse(req.body, Map)
    
    // parameter parser and validation
    val udi = get("udi") as String
    val source = get("source") as String
    var pid = get("pid") as String
    
    if (udi === null || source === null || pid === null)
      halt(400, "Invalid parameters!")
    
    store.SUBJECT.associate(udi, source, pid)
  }
  
  def subjectRemoveAssociation(Request req) {
    // parameter parser and validation
    val udi = req.params("udi") as String
    val source = req.params("source") as String
    var pid = req.params("pid") as String
    
    if (udi === null || source === null || pid === null)
      halt(400, "Invalid parameters!")
    
    store.SUBJECT.deAssociate(udi, source, pid)
  }
  
  def getPage(NodeType nt, Request req) {
    // parameter parser and validation
    val page = Integer.parseInt(req.params("page")) - 1
    val pageSize = Integer.parseInt(req.queryParams("pageSize")?: "10")
    
    if (page < 0 || pageSize < 0)
      halt(400, "Invalid parameters!")
    
    val skip = page * pageSize
    
    val res = switch nt {
      case SUBJECT: store.SUBJECT.page(skip, pageSize)
      case PULL: store.PULL.page(skip, pageSize)
      case PUSH: store.PUSH.page(skip, pageSize)
    }
    
    return res ?: #{ "total" -> 0, "data" -> Collections.EMPTY_LIST }
  }
  
  def getDetails(NodeType nt, Request req) {
    // parameter parser and validation
    if (req.params("id") === null)
      halt(400, "Invalid parameters!")
    
    val id = Long.parseLong(req.params("id"))
    
    switch nt {
      case SUBJECT: store.SUBJECT.details(id)
      case PULL: store.PULL.details(id)
      case PUSH: store.PUSH.details(id)
    }
  }
  
  def getPendingData(Request req) {
    store.TARGET.pending
  }
  
  def getPendingDataDetails(Request req) {
    // parameter parser and validation
    if (req.params("id") === null)
      halt(400, "Invalid parameters!")
    
    val id = Long.parseLong(req.params("id"))
    store.TARGET.pendingDetails(id)
  }
  
  def pushPendingData(Request req) {
    val it = json.parse(req.body, Map)
    
    // parameter parser and validation
    val id = if (get("id") === null) null else (get("id") as Double).longValue as Long
    val series = get("series")
    
    if (id === null || series === null)
      halt(400, "Invalid parameters!")
    
    val seriesIDs = (series as List<Double>).map[longValue].toSet
    store.PUSH.create(id, seriesIDs)
    
    return id
  }
  
  def getEdges(Request req) {
    store.edges
  }
  
  def setEdge(Request req) {
    val it = json.parse(req.body, Map)
    
    // parameter parser and validation
    val edge = get("edge") as String
    val id = if (get("id") === null) null else (get("id") as Double).longValue as Long
    val active = get("active") as Boolean
    
    if (edge === null || active === null)
      halt(400, "Invalid parameters!")
    
    switch edge {
      case "Source": {
        val aet = get("aet") as String
        val host = get("host") as String
        val rawPort = get("port")
        
        if (aet === null || host === null || rawPort === null)
          halt(400, "Invalid parameters!")
        
        val port = if (rawPort instanceof String)
            try { Integer.parseInt(rawPort) } catch (NumberFormatException e) { 0 }
          else if (rawPort instanceof Double)
            rawPort.intValue
        
        store.SOURCE.set(id, active, aet, host, port)
      }
      
      case "Target": {
        val udi = get("udi") as String
        val name = get("name") as String
        val modalities = (get("modalities") as List<String>)?.toSet
        
        if (udi === null || name === null || modalities === null || modalities.empty)
          halt(400, "Invalid parameters!")
        
        store.TARGET.set(id, active, udi, name, modalities)
      }
    }
  }
  
  def removeEdge(Request req) {
    // parameter parser and validation
    if (req.params("id") === null)
      halt(400, "Invalid parameters!")
    
    val edge = req.params("edge")
    val id = Long.parseLong(req.params("id"))
    
    if (edge === null)
      halt(400, "Invalid parameters!")
    
    switch edge {
      case "Source": store.SOURCE.remove(id)
      case "Target": store.TARGET.remove(id)
    }
  }
  
  def getAllKeys(Request req) {
    store.KEY.all
  }
  
  def getKey(Request req) {
    // parameter parser and validation
    val group = req.params("group") as String
    val key = req.params("key") as String
    
    if (group === null || key === null)
      halt(400, "Invalid parameters!")
    
    store.KEY.get(group, key)
  }
  
  def setKey(Request req) {
    val it = json.parse(req.body, Map)
    
    // parameter parser and validation
    val group = get("group") as String
    val key = get("key") as String
    var value = get("value")
    
    if (group === null || key === null || value === null)
      halt(400, "Invalid parameters!")
    
    if (value instanceof Double) {
      value = value.intValue
    } if (value instanceof String) {
      try {
        value = Integer.parseInt(value)
      } catch (NumberFormatException e) {}
    } else if (List.isAssignableFrom(value.class)) {
      value = (value as List<Object>)
        .map[
          if (it instanceof Double)
            intValue
          else if (it instanceof String) try {
              Integer.parseInt(it)
            } catch (NumberFormatException e) { it }
          else it
        ]
        .toSet
    }
    
    store.KEY.set(group, key, value)
  }
  
  def dicomFind(Request req) {
    val dQuery = prepareDicomQuery(req)
    pullSrv.find(dQuery)
  }
  
  def dicomPatientFind(Request req) {
    val dQuery = prepareDicomQuery(req)
    pullSrv.patientFind(dQuery)
  }
  
  def cypherQuery(Request req) {
    val it = json.parse(req.body, Map)
    
    // parameter parser and validation
    val query = get("query") as String
    if (query === null)
      halt(400, "Invalid parameters!")
    
    // read-only queries. No modification operations are allowed.
    // this is not an advanced security feature. It's just to avoid administrator input mistakes.
    val lQuery = query.toLowerCase
    if (excludedKeys.exists[
      val index = lQuery.indexOf(it)
      !(index < 0 || index > 0 && lQuery.charAt(index - 1) == '.'.charAt(0))
    ])
      halt(400, "Read-only mode! Try to remove possible cypher modification keywords.")
    
    val results = try {
      store.cypher(query)
    } catch (Throwable e) {
      halt(400, e.message)
      return null
    }
    
    val headers = if (!results.empty)
        results.head.keySet.toList
      else
        Collections.EMPTY_LIST
    
    return #{ "headers" -> headers, "results" -> results }
  }
  
  def void setup() {
    initExceptionHandler[
      logger.error("WebServer initialization failed!", it)
      System.exit(-1)
    ]
    
    staticFileLocation("/ui")
    
    path("/api")[
      before[ req, res |
        logger.debug("{} - {}", req.requestMethod, req.uri)
        //if (!authenticated) {
        //  halt(401, "You are not welcome here")
      ]
      
      after[req, res |
        res.type("application/json")
      ]
      
      post("/dfind", [req, res | dicomFind(req)], json)
      post("/pfind", [req, res | dicomPatientFind(req)], json)
      post("/cypher", [req, res | cypherQuery(req)], json)
      
      path("/keys")[
        get("", [req, res | getAllKeys(req)], json)
        get("/:group/:key", [req, res | getKey(req)], json)
        post("", [req, res | setKey(req)], json)
      ]
      
      path("/edges")[
        get("", [req, res | getEdges(req)], json)
        post("", [req, res | setEdge(req)], json)
        delete("/:edge/:id", [req, res | removeEdge(req)], json)
      ]
      
      path("/pending")[
        get("", [req, res | getPendingData(req)], json)
        get("/:id", [req, res | getPendingDataDetails(req)], json)
        post("/push", [req, res | pushPendingData(req)], json)
      ]
      
      path("/subject")[
        get("/:id", [req, res | getDetails(NodeType.SUBJECT, req)], json)
        get("/udi/:udi", [req, res | getSubject(req)], json)
        get("/page/:page", [req, res | getPage(NodeType.SUBJECT, req)], json)
        post("/associate", [req, res | subjectAddAssociation(req)], json)
        delete("/associate/:udi/:source/:pid", [req, res | subjectRemoveAssociation(req)], json)
      ]
      
      path("/pull")[
        get("/:id", [req, res | getDetails(NodeType.PULL, req)], json)
        get("/page/:page", [req, res | getPage(NodeType.PULL, req)], json)
      ]
      
      path("/push")[
        get("/:id", [req, res | getDetails(NodeType.PUSH, req)], json)
        get("/page/:page", [req, res | getPage(NodeType.PUSH, req)], json)
      ]
    ]
  }
  
  private def prepareDicomQuery(Request req) {
    val it = json.parse(req.body, Map)
    
    // parameter parser and validation
    val query = get("query") as String
    if (query === null)
      halt(400, "Invalid parameters!")
    
    // simple query parser - <field>:<value> & ..
    val items = newImmutableMap(query.split("&").map[
      val keyValue = split(":")
      if (keyValue.length !== 2)
        halt(400, "Invalid query format!")
      
      keyValue.get(0).trim -> keyValue.get(1)
    ])
    
    val parsedItems = new HashMap<String, String>
    items.forEach[key, value |
      if (!DQuery.TAGS.containsKey(key))
        if (tagConverter.containsKey(key.toLowerCase))
          parsedItems.put(tagConverter.get(key.toLowerCase), value)
        else
          halt(400, "Non existent DICOM Tag: " + key)
      else
        parsedItems.put(key, value)
    ]
    
    return new DQuery => [ set(parsedItems) ]
  }
}