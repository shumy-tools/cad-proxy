package base

import db.Store
import java.util.Collections
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import spark.Request

import static spark.Spark.*
import java.util.Map
import java.util.List

@FinalFieldsConstructor
class WebServer {
  static val logger = LoggerFactory.getLogger(WebServer)
  
  val Store store
  val json = new JsonTransformer
  
  enum NodeType { SUBJECT, PULL, PUSH }
  
  def getPage(NodeType nt, Request req) {
    logger.debug("GET ", req.uri)
    
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
    logger.debug("GET ", req.uri)
    
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
    logger.debug("GET ", req.uri)
    store.TARGET.pending
  }
  
  def getPendingDataDetails(Request req) {
    logger.debug("GET ", req.uri)
    
    // parameter parser and validation
    if (req.params("id") === null)
      halt(400, "Invalid parameters!")
    
    val id = Long.parseLong(req.params("id"))
    store.TARGET.pendingDetails(id)
  }
  
  def getEdges(Request req) {
    logger.debug("GET ", req.uri)
    store.edges
  }
  
  def setEdge(Request req) {
    logger.debug("POST ", req.uri)
    
    val it = json.parse(req.body, Map)
    
    val edge = get("edge") as String
    val id = if (get("id") === null) null else (get("id") as Double).longValue as Long
    val active = get("active") as Boolean
    
    if (edge === null || active === null)
      halt(400, "Invalid parameters!")
    
    switch edge {
      case "Source": {
        val aet = get("aet") as String
        val host = get("host") as String
        val port = if (get("port") === null) null else Integer.parseInt(get("port") as String)
        
        if (aet === null || host === null || port === null)
          halt(400, "Invalid parameters!")
        
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
    logger.debug("POST ", req.uri)
    
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
    logger.debug("GET ", req.uri)
    store.KEY.all
  }
  
  def getKey(Request req) {
    logger.debug("GET ", req.uri)
    
    // parameter parser and validation
    val group = req.params("group") as String
    val key = req.params("key") as String
    
    if (group === null || key === null)
      halt(400, "Invalid parameters!")
    
    store.KEY.get(group, key)
  }
  
  def void setup() {
    initExceptionHandler[
      logger.error("WebServer initialization failed!", it)
      System.exit(-1)
    ]
    
    staticFileLocation("/ui")
    
    path("/api")[
      before[ req, res |
        logger.info("API call")
        //if (!authenticated) {
        //  halt(401, "You are not welcome here")
      ]
      
      after[req, res |
        res.type("application/json")
      ]
      
      path("/keys")[
        get("", [req, res | getAllKeys(req)], json)
        get("/:group/:key", [req, res | getKey(req)], json)
      ]
      
      path("/edges")[
        get("", [req, res | getEdges(req)], json)
        post("", [req, res | setEdge(req)], json)
        delete("/:edge/:id", [req, res | removeEdge(req)], json)
      ]
      
      path("/pending")[
        get("", [req, res | getPendingData(req)], json)
        get("/:id", [req, res | getPendingDataDetails(req)], json)
      ]
      
      path("/subject")[
        get("/:id", [req, res | getDetails(NodeType.SUBJECT, req)], json)
        get("/page/:page", [req, res | getPage(NodeType.SUBJECT, req)], json)
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
}