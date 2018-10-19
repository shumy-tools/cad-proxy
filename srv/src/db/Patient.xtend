package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDate

@FinalFieldsConstructor
class Patient {
  val NeoDB db
  public static val NODE = Patient.simpleName
  
  public static val PID               = "pid"
  public static val SEX               = "sex"
  public static val BIRTHDAY          = "birthday"
  
  def Long create(Long sourceID, String pid, String sex, LocalDate birthday) {
    val map = #{ PID -> pid, SEX -> sex, BIRTHDAY -> birthday}
    val res = db.cypher('''
      MATCH (s:«Source.NODE») WHERE id(s) = «sourceID»
      MERGE (n:«NODE» {«PID»: $«PID»})-[:FROM]->(s)
        ON CREATE SET
          n.«SEX» = $«SEX»,
          n.«BIRTHDAY» = $«BIRTHDAY»
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create patient. Probable cause, no valid sourceID=«sourceID»''')
    
    res.head.get("id") as Long
  }
}