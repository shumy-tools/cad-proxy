package base

import db.Store
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import spark.Request

import static spark.Spark.*

@FinalFieldsConstructor
class WebServer {
  static val logger = LoggerFactory.getLogger(WebServer)
  
  val Store store
  val json = new JsonTransformer
  
  enum PageType { SUBJECT, PULL, PUSH }
  
  def getPage(PageType pt, Request req) {
    logger.debug("GET ", req.uri)
    
    // parameter parser and validation
    val page = Integer.parseInt(req.params("page")) - 1
    val pageSize = Integer.parseInt(req.queryParams("pageSize")?: "10")
    
    if (page < 0 || pageSize < 0)
      halt(400, "Invalid parameters!")
    
    val skip = page * pageSize
    
    switch pt {
      case SUBJECT: return store.SUBJECT.page(skip, pageSize)
      case PULL: return store.PULL.page(skip, pageSize)
      case PUSH: return store.PUSH.page(skip, pageSize)
    }
  }
  
  def getSubject(Request req) {
    
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
      
      path("/subject")[
        get("/:id", [req, res | getSubject(req)], json)
        get("/page/:page", [req, res | getPage(PageType.SUBJECT, req)], json)
      ]
      
      path("/pull")[
        get("/page/:page", [req, res | getPage(PageType.PULL, req)], json)
      ]
      
      path("/push")[
        get("/page/:page", [req, res | getPage(PageType.PUSH, req)], json)
      ]
    ]
  }
}