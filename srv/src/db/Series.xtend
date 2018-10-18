package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Series {
  val NeoDB db
  public static val NODE = Series.simpleName
  
  public static val UID               = "uid"
  public static val SEQ               = "seq"
  public static val MODALITY          = "modality"
  
  public static val ELIGIBLE          = "eligible"
  public static val COMPLETED         = "completed"
  
  def Long create(Long studyID, String uid, Integer seq, String modality) {
    val map = #{ UID -> uid, SEQ -> seq, MODALITY -> modality }
    val res = db.cypher('''
      MATCH (s:«Study.NODE») WHERE id(s) = «studyID»
      MERGE (s)-[:HAS]->(n:«NODE» {«UID»: $«UID»})
        ON CREATE SET
          n.«ELIGIBLE» = true,
          n.«COMPLETED» = false,
          
          n.«UID» = $«UID»,
          n.«SEQ» = $«SEQ»,
          n.«MODALITY» = $«MODALITY»
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create series. Probable cause, no valid studyID=«studyID»''')
    
    res.head.get("id") as Long
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
  
  def void eligible(Long seriesID, boolean isEligible) {
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «seriesID»
      SET n.«ELIGIBLE» = «isEligible»
    ''')
  }
  
  def void completed(Long seriesID, boolean isCompleted) {
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «seriesID»
      SET n.«COMPLETED» = «isCompleted»
    ''')
  }
}