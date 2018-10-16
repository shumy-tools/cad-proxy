package db

import java.time.LocalDateTime
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Pull {
  enum Type { FIND, PULL }
  enum Status { START, END, ERROR }
  
  val NeoDB db
  public static val NODE = Pull.simpleName
  
  public static val STARTED             = "started"
  public static val TYPE                = "type"
  
  public static val STATUS              = "status"
  public static val S_TIME              = "sTime"
  public static val ERROR               = "error"
  
  public static val FROM                = "FROM"
  public static val THESE               = "THESE"
  
  def Long create(Long sourceID, Type type) {
    val map = #{ "sid" -> sourceID, STARTED -> LocalDateTime.now, TYPE -> type.name, STATUS -> Status.START.name, S_TIME -> LocalDateTime.now }
    val res = db.cypher('''
      MATCH (s:«Source.NODE») WHERE id(s) = $sid
      CREATE (n:«NODE») SET
        n.«STARTED» = $«STARTED»,
        n.«TYPE» = $«TYPE»,
        n.«STATUS» = $«STATUS»,
        n.«S_TIME» = $«S_TIME»
      MERGE (n)-[:«FROM»]->(s)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create pull. Probable cause, no valid sourceID=«sourceID»''')
      
    res.head.get("id") as Long
  }
  
  def void status(Long pullID, Status status) {
    val map = #{ "pid" -> pullID, STATUS -> status.name, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = $pid
      SET n.«STATUS» = $«STATUS», n.«S_TIME» = $«S_TIME»
    ''', map)
  }
  
  def void error(Long pullID, String error) {
    val map = #{ "pid" -> pullID, ERROR -> error, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = $pid
      SET n.«STATUS» = «Status.ERROR.name», n.«S_TIME» = $«S_TIME», n.«ERROR» = $«ERROR»
    ''', map)
  }
  
  def Long linkStudies(Long pullID, Iterable<Long> studiesIDs) {
    val map = #{ "pid" -> pullID, "sids" -> studiesIDs }
    val res = db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = $pid
      MATCH (s:«Study.NODE») WHERE id(s) IN $sids
      MERGE (n)-[l:«THESE»]->(s)
      RETURN count(l) as size
    ''', map)
    
    res.head.get("size") as Long
  }
  
  def data(Long pullID) {
    val map = #{ "pid" -> pullID }
    db.cypher('''
      MATCH (n:«NODE»)-[:«THESE»]->(s:«Study.NODE»)-[:«Study.HAS»]->(e:«Series.NODE»)
      WHERE id(n) = $pid
      RETURN
        s.«Study.UID» as uid,
        s.«Study.DATE» as date,
        e {
          .«Series.UID»,
          .«Series.SEQ»,
          .«Series.MODALITY»
        } as series
    ''', map)
  }
}