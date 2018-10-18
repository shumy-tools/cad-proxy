package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDate

@FinalFieldsConstructor
class Study {
  val NeoDB db
  public static val NODE = Study.simpleName
  
  public static val UID               = "uid"
  public static val DATE              = "date"
  
  def Long create(Long subjectID, String uid, LocalDate date) {
    val map = #{ UID -> uid, DATE -> date }
    val res = db.cypher('''
      MATCH (s:«Subject.NODE») WHERE id(s) = «subjectID»
      MERGE (s)-[:HAS]->(n:«NODE» {«UID»: $«UID»})
        ON CREATE SET
          n.«UID» = $«UID»,
          n.«DATE» = $«DATE»
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create study. Probable cause, no valid subjectID=«subjectID»''')
      
    res.head.get("id") as Long
  }
}