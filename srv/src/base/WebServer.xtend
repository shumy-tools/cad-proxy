package base

import db.Store
import java.util.Collections
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import spark.Request

import static spark.Spark.*

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
    
    val id = Long.parseLong(req.params("id"))
    store.TARGET.pendingDetails(id)
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
      
      get("/pending", [req, res | getPendingData(req)], json)
      get("/pending/:id", [req, res | getPendingDataDetails(req)], json)
      
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