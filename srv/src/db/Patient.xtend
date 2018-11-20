package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Patient {
  val NeoDB db
  public static val NODE = Patient.simpleName
  
  public static val REMOVED           = "removed"
  public static val PID               = "pid"
  
  def Long create(Long sourceID, String pid) {
    val map = #{ PID -> pid }
    val res = db.cypher('''
      MATCH (s:«Source.NODE») WHERE id(s) = «sourceID»
      MERGE (n:«NODE» {«PID»: $«PID»})-[:FROM]->(s)
        ON CREATE SET
          n.«REMOVED» = false
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create patient. Probable cause, no valid sourceID=«sourceID»''')
    
    res.head.get("id") as Long
  }
}