package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDateTime
import java.util.Set

@FinalFieldsConstructor
class Push {
  val NeoDB db
  public static val NODE = Push.simpleName
  
  public static val STARTED             = "started"
  
  public static val STATUS              = "status"
  public static val S_TIME              = "sTime"
  public static val ERROR               = "error"
  
  public static val TO                  = "TO"
  public static val THESE               = "THESE"
  
  def Long create(Long targetID, String type, String status) {
    val map = #{ STARTED -> LocalDateTime.now, STATUS -> status, S_TIME -> LocalDateTime.now }
    val res = db.cypher('''
      MATCH (t:«Target.NODE») WHERE id(s) = «targetID»
      MERGE (n:«NODE»)
        ON CREATE SET
          n.«STARTED» = $«STARTED»,
          n.«STATUS» = $«STATUS»,
          n.«S_TIME» = $«S_TIME»
      MERGE (n)-[:«TO»]->(t)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty) return -1L
    res.head.get("id") as Long
  }
  
  def Long linkSeries(Long pushID, Set<Long> seriesIDs) {
    val map = #{ "sids" -> seriesIDs }
    val res = db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pushID»
      MATCH (s:«Series.NODE») WHERE id(s) IN $sids
      MERGE (n)-[l:«THESE»]->(s)
      RETURN count(l) as size
    ''', map)
    
    res.head.get("size") as Long
  }
}