package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDateTime

@FinalFieldsConstructor
class Item {
  val NeoDB db
  public static val NODE = Item.simpleName
  
  public static val UID               = "uid"
  public static val SEQ               = "seq"
  public static val TIME              = "time"
  
  def Long create(Long seriesID, String uid, Integer seq, LocalDateTime time) {
    val map = #{ UID -> uid, SEQ -> seq, TIME -> time }
    val res = db.cypher('''
      MATCH (s:«Series.NODE») WHERE id(s) = «seriesID»
      MERGE (s)-[:HAS]->(n:«NODE» {«UID»: $«UID»})
        ON CREATE SET
          n.«UID» = $«UID»,
          n.«SEQ» = $«SEQ»,
          n.«TIME» = $«TIME»
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create series. Probable cause, no valid seriesID==«seriesID»''')
    
    res.head.get("id") as Long
  }
}