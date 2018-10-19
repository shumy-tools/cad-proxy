package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDateTime
import java.util.Set

@FinalFieldsConstructor
class Push {
  enum Status { START, ZIP, TRANSMIT, END, ERROR, RETRY }
    
  val NeoDB db
  public static val NODE = Push.simpleName
  
  public static val STARTED             = "started"
  
  public static val STATUS              = "status"
  public static val S_TIME              = "sTime"
  public static val ERROR               = "error"
  
  def Long create(Long targetID, String type, String status) {
    val map = #{ STARTED -> LocalDateTime.now, STATUS -> status, S_TIME -> LocalDateTime.now }
    val res = db.cypher('''
      MATCH (t:«Target.NODE») WHERE id(t) = «targetID»
      CREATE (n:«NODE»)
        ON CREATE SET
          n.«STARTED» = $«STARTED»,
          n.«STATUS» = $«STATUS»,
          n.«S_TIME» = $«S_TIME»
      MERGE (n)-[:TO]->(t)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty) return -1L
    res.head.get("id") as Long
  }
  
  def void status(Long pushID, Status status) {
    val map = #{ STATUS -> status.name, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pushID»
      SET n.«STATUS» = $«STATUS», n.«S_TIME» = $«S_TIME»
    ''', map)
  }
  
  def void error(Long pushID, String error) {
    val map = #{ ERROR -> error, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pushID»
      SET n.«STATUS» = "«Status.ERROR.name»", n.«S_TIME» = $«S_TIME», n.«ERROR» = $«ERROR»
    ''', map)
  }
  
  def Long linkSeries(Long pushID, Set<Long> seriesIDs) {
    val map = #{ "sids" -> seriesIDs }
    val res = db.cypher('''
      MATCH (n:«NODE»), (s:«Series.NODE»)
        WHERE id(n) = «pushID» AND id(s) IN $sids
      MERGE (n)-[l:THESE]->(s)
      RETURN count(l) as size
    ''', map)
    
    res.head.get("size") as Long
  }
  
  def data(Long pushID) {
    val res = db.cypher('''
      MATCH (l:«Target.NODE»)<-[:FROM]-(n:«NODE»)
        WHERE id(n) = «pushID»
      WITH id(l) as target, n
      RETURN target, n.«STATUS» as status, [(n)-[:THESE]->(e:«Series.NODE»)<-[:HAS*]-(p:«Subject.NODE») | e {
        subject: p.«Subject.UDI»,
        id: id(e),
        .«Series.UID»,
        .«Series.SEQ»,
        .«Series.MODALITY»,
        .«Series.ELIGIBLE»,
        .«Series.SIZE»,
        .«Series.STATUS»,
        .«Series.S_TIME»,
        .«Series.ERROR»
      }] as series
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find data for pushID: «pushID»''')
    
    return res.head
  }
}