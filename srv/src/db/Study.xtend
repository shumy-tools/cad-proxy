package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDate

@FinalFieldsConstructor
class Study {
  val NeoDB db
  public static val NODE = Study.simpleName
  
  public static val UID               = "uid"
  public static val DATE              = "date"
  
  public static val HAS               = "HAS"
  
  def Long create(Long subjectID, String uid, LocalDate date) {
    val map = #{ UID -> uid, DATE -> date }
    val res = db.cypher('''
      MATCH (s:«Subject.NODE») WHERE id(s) = «subjectID»
      MERGE (n:«NODE» {«UID»: $«UID»})
        ON CREATE SET
          n.«UID» = $«UID»,
          n.«DATE» = $«DATE»
      MERGE (s)-[:«HAS»]->(n)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create study. Probable cause, no valid subjectID=«subjectID»''')
      
    res.head.get("id") as Long
  }
}