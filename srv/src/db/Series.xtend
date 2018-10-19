package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDateTime

@FinalFieldsConstructor
class Series {
  enum Status { START, READY, END, ERROR, RETRY }
  
  val NeoDB db
  public static val NODE = Series.simpleName
  
  public static val UID               = "uid"
  public static val SEQ               = "seq"
  public static val MODALITY          = "modality"
  public static val ELIGIBLE          = "eligible"
  public static val SIZE              = "size"
  
  public static val STATUS              = "status"
  public static val S_TIME              = "sTime"
  public static val ERROR               = "error"
  
  def Long create(Long studyID, String uid, Integer seq, String modality) {
    val map = #{ UID -> uid, SEQ -> seq, MODALITY -> modality, STATUS -> Status.START.name, S_TIME -> LocalDateTime.now }
    val res = db.cypher('''
      MATCH (s:«Study.NODE») WHERE id(s) = «studyID»
      MERGE (s)-[:HAS]->(n:«NODE» {«UID»: $«UID»})
        ON CREATE SET
          n.«ELIGIBLE» = true,
          n.«SIZE» = 0,
          
          n.«UID» = $«UID»,
          n.«SEQ» = $«SEQ»,
          n.«MODALITY» = $«MODALITY»,
          n.«STATUS» = $«STATUS»,
          n.«S_TIME» = $«S_TIME»
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create series. Probable cause, no valid studyID=«studyID»''')
    
    res.head.get("id") as Long
  }
  
  def void eligible(Long seriesID, boolean isEligible) {
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «seriesID»
      SET n.«ELIGIBLE» = «isEligible»
    ''')
  }
  
  def void status(Long seriesID, Status status) {
    val map = #{ STATUS -> status.name, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «seriesID»
      SET n.«STATUS» = $«STATUS», n.«S_TIME» = $«S_TIME», n.«SIZE» = size([(n)-[:HAS]->(i:«Item.NODE») | i])
    ''', map)
  }
  
  def void error(Long seriesID, String error) {
    val map = #{ ERROR -> error, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «seriesID»
      SET n.«STATUS» = "«Status.ERROR.name»", n.«S_TIME» = $«S_TIME», n.«ERROR» = $«ERROR»
    ''', map)
  }
  
  def Long exist(String seriesUID) {
    val map = #{ "suid" -> seriesUID }
    val res = db.cypher('''
      MATCH (n:«NODE» {«UID»: $suid})
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      return null
    
    return res.head.get("id") as Long
  }
}