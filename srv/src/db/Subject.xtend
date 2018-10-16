package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.time.LocalDate
import java.time.LocalDateTime

@FinalFieldsConstructor
class Subject {
  val NeoDB db
  public static val NODE = Subject.simpleName
  
  public static val ACTIVE            = "active"
  public static val A_TIME            = "aTime"
  
  public static val UDI               = "udi"
  public static val PID               = "pid"
  
  public static val SEX               = "sex"
  public static val BIRTHDAY          = "birthday"
  
  public static val FROM              = "FROM"
  
  def Long create(Long sourceID, String udi, String pid, String sex, LocalDate birthday) {
    val map = #{ "sid" -> sourceID, UDI -> udi, PID -> pid, SEX -> sex, BIRTHDAY -> birthday, A_TIME -> LocalDateTime.now}
    val res = db.cypher('''
      MATCH (s:«Source.NODE») WHERE id(s) = $sid
      MERGE (n:«NODE» {«UDI»: $«UDI»})
        ON CREATE SET
          n.«ACTIVE» = true,
          
          n.«A_TIME» = $«A_TIME»,
          n.«UDI» = $«UDI»,
          n.«PID» = $«PID»,
          n.«SEX» = $«SEX»,
          n.«BIRTHDAY» = $«BIRTHDAY»
      MERGE (n)-[:«FROM»]->(s)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create subject. Probable cause, no valid sourceID=«sourceID»''')
    
    res.head.get("id") as Long
  }
  
  def activeFrom(Long sourceID, String patientID) {
    val map = #{ "sid" -> sourceID, "pid" -> patientID }
    val res = db.cypher('''
      MATCH (n:«NODE»)-[:«FROM»]->(s:«Source.NODE»)
      WHERE n.«ACTIVE» = true AND n.«PID» = $pid AND id(s) = $sid
      RETURN id(n) as id
    ''', map)
    
    if (res.empty) return null
    res.head.get("id") as Long
  }
  
  def getAll() {
    db.cypher('''MATCH (n:«NODE») RETURN
      id(n) as id,
      n.«ACTIVE» as «ACTIVE»,
      n.«A_TIME» as «A_TIME»,
      n.«UDI» as «UDI»,
      n.«PID» as «PID»,
      n.«SEX» as «SEX»,
      n.«BIRTHDAY» as «BIRTHDAY»
    ''')
  }
}