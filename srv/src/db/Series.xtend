package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDateTime

@FinalFieldsConstructor
class Series {
  val NeoDB db
  public static val NODE = Series.simpleName
  
  public static val UID               = "uid"
  public static val SEQ               = "seq"
  public static val TIME              = "time"
  public static val MODALITY          = "modality"
  
  public static val IN_CACHE          = "inCache"
  
  public static val HAS               = "HAS"
  
  def Long create(Long studyID, String uid, Integer seq, String modality, LocalDateTime time) {
    val map = #{ "sid" -> studyID, UID -> uid, SEQ -> seq, MODALITY -> modality, TIME -> time }
    val res = db.cypher('''
      MATCH (s:«Study.NODE») WHERE id(s) = $sid
      MERGE (n:«NODE» {«UID»: $«UID»})
        ON CREATE SET
          n.«IN_CACHE» = false,
          
          n.«UID» = $«UID»,
          n.«SEQ» = $«SEQ»,
          n.«TIME» = $«TIME»,
          n.«MODALITY» = $«MODALITY»
      MERGE (s)-[:«HAS»]->(n)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create series. Probable cause, no valid studyID=«studyID»''')
    
    res.head.get("id") as Long
  }
}