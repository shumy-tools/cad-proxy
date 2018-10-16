package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDateTime

@FinalFieldsConstructor
class Source {
  val NeoDB db
  public static val NODE = Source.simpleName
  
  public static val ACTIVE            = "active"
  public static val A_TIME            = "aTime"
  
  public static val PULL_INTERVAL     = "pullInterval"
  
  public static val AET               = "aet"
  public static val HOST              = "ip"
  public static val PORT              = "port"
  
  def Long create(String aet, String ip, Integer port) {
    val map = #{ AET -> aet, HOST -> ip, PORT -> port, A_TIME -> LocalDateTime.now}
    val res = db.cypher('''
      MERGE (n:«NODE» {«AET»: $«AET»})
        ON CREATE SET
          n.«ACTIVE» = true,
          n.«PULL_INTERVAL» = 180,
          
          n.«A_TIME» = $«A_TIME»,
          n.«AET» = $«AET»,
          n.«HOST» = $«HOST»,
          n.«PORT» = $«PORT»
      RETURN id(n) as id
    ''', map)
    
    res.head.get("id") as Long
  }
  
  def getAll() {
    db.cypher('''MATCH (n:«NODE») RETURN
      id(n) as id,
      n.«ACTIVE» as «ACTIVE»,
      n.«A_TIME» as «A_TIME»,
      n.«PULL_INTERVAL» as «PULL_INTERVAL»,
      n.«AET» as «AET»,
      n.«HOST» as «HOST»,
      n.«PORT» as «PORT»
    ''')
  }
  
  def pullThrottle() {
    val map = #{ "now" -> LocalDateTime.now}
    db.cypher('''
      MATCH (n:«NODE») WHERE n.«ACTIVE» = true
      OPTIONAL MATCH (n)<-[:«Pull.FROM»]-(p:«Pull.NODE»)
        WHERE p.«Pull.TYPE» = "FIND" AND p.«Pull.STATUS» = "END"
      WITH id(n) as id, n.«AET» as aet, n.«HOST» as host, n.«PORT» as port, n.«PULL_INTERVAL» as interval, max(p.«Pull.STARTED») as last
        WHERE last IS NULL OR duration.between(last, $now).minutes > interval
      RETURN id, aet, host, port, last
    ''', map)
  }
}