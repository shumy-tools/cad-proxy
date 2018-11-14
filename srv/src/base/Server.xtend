package base

import db.Store
import dicom.model.DQuery
import dicom.model.DStudy
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.HashSet
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.slf4j.LoggerFactory
import service.PullService
import service.PushService
import service.TransmitService

class Server {
  static val logger = LoggerFactory.getLogger(Server)
  static val formatter = DateTimeFormatter.ofPattern("yyyyMMdd")
  
  val Store store
  val TransmitService transSrv 
  
  var PullService pullSrv = null
  var PushService pushSrv = null
  
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
      val pullInterval = store.KEY.get("pull", "interval") as Integer
      val pushInterval = store.KEY.get("push", "interval") as Integer
      
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
    new WebServer(store, pullSrv, pushSrv).setup
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
}