package db

import java.time.LocalDateTime
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.Set

@FinalFieldsConstructor
class Subject {
  val NeoDB db
  public static val NODE = Subject.simpleName
  
  public static val ACTIVE            = "active"
  public static val A_TIME            = "aTime"
  
  public static val UDI               = "udi"
  
  def Long create(String udi) {
    val map = #{ UDI -> udi, A_TIME -> LocalDateTime.now}
    val res = db.cypher('''
      MERGE (n:«NODE» {«UDI»: $«UDI»})
        ON CREATE SET
          n.«ACTIVE» = true,
          n.«A_TIME» = $«A_TIME»,
          n.«UDI» = $«UDI»
      RETURN id(n) as id
    ''', map)
    
    res.head.get("id") as Long
  }
  
  def void is(Long subjectID, Long patientID) {
    db.cypher('''
      MATCH (n:«NODE»), (p:«Patient.NODE»)
        WHERE id(n) = «subjectID» AND id(p) = «patientID»
      MERGE (n)-[:IS]->(p)
    ''')
  }
  
  def void consent(Long subjectID, Long targetID) {
    db.cypher('''
      MATCH (n:«NODE»), (t:«Target.NODE»)
        WHERE id(n) = «subjectID» AND id(t) = «targetID»
      MERGE (n)-[:CONSENT]->(t)
    ''')
  }
  
  def from(Long sourceID, String patientID) {
    val map = #{ "pid" -> patientID }
    val res = db.cypher('''
      MATCH (n:«NODE»)-[:IS]->(p:«Patient.NODE»)-[:FROM]->(s:«Source.NODE»)
        WHERE n.«ACTIVE» = true AND id(s) = «sourceID» AND p.«Patient.PID» = $pid
      RETURN id(n) as id
    ''', map)
    
    if (res.empty) return null
    res.head.get("id") as Long
  }
  
  def boolean exist(Long sourceID, Set<String> patientIDs) {
    val map = #{ "pids" -> patientIDs }
    val res = db.cypher('''
      MATCH (n:«NODE»)-[:IS]->(p:«Patient.NODE»)-[:FROM]->(s:«Source.NODE»)
        WHERE n.«ACTIVE» = true AND id(s) = «sourceID» AND p.«Patient.PID» IN $pids
      RETURN count(s) as size
    ''', map)
    
    return res.head.get("size") as Long !== 0L
  }
  
  def all() {
    db.cypher('''MATCH (n:«NODE») RETURN
      id(n) as id,
      n.«ACTIVE» as «ACTIVE»,
      n.«A_TIME» as «A_TIME»,
      n.«UDI» as «UDI»
    ''')
  }
}