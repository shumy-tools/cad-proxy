package base

import db.Store
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import spark.Route

import static spark.Spark.*

@FinalFieldsConstructor
class WebServer {
  static val logger = LoggerFactory.getLogger(WebServer)
  
  val Store store
  val json = new JsonTransformer
  
  def void setup() {
    val Route getPullPage = [ req, res |
      logger.debug("GET ", req.uri)
      
      // parameter parser and validation
      val page = Integer.parseInt(req.params("page")) - 1
      val pageSize = Integer.parseInt(req.queryParams("pageSize")?: "10")
      
      if (page < 0 || pageSize < 0)
        halt(400, "Invalid parameters!")
      
      val skip = page * pageSize
      
      return store.PULL.page(skip, pageSize)
    ]
    
    val Route getPushPage = [ req, res |
      logger.debug("GET ", req.uri)
      
      // parameter parser and validation
      val page = Integer.parseInt(req.params("page")) - 1
      val pageSize = Integer.parseInt(req.queryParams("pageSize")?: "10")
      
      if (page < 0 || pageSize < 0)
        halt(400, "Invalid parameters!")
      
      val skip = page * pageSize
      
      return store.PUSH.page(skip, pageSize)
    ]
    
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
      
      path("/pull")[
        get("/page/:page", getPullPage, json)
      ]
      
      path("/push")[
        get("/page/:page", getPushPage, json)
      ]
    ]
  }
}