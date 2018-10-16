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
  
  public static val HAS               = "HAS"
  
  def Long create(Long seriesID, String uid, Integer seq, LocalDateTime time) {
    val map = #{ "sid" -> seriesID, UID -> uid, SEQ -> seq, TIME -> time }
    val res = db.cypher('''
      MATCH (s:«Series.NODE») WHERE id(s) = $sid
      MERGE (n:«NODE» {«UID»: $«UID»})
        ON CREATE SET
          n.«UID» = $«UID»,
          n.«SEQ» = $«SEQ»,
          n.«TIME» = $«TIME»
      MERGE (s)-[:«HAS»]->(n)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create item. Probable cause, no valid seriesID=«seriesID»''')
    
    res.head.get("id") as Long
  }
}