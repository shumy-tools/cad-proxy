package db

import java.time.LocalDateTime
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.Set
import java.time.LocalDate

@FinalFieldsConstructor
class Subject {
  val NeoDB db
  public static val NODE = Subject.simpleName
  
  public static val ACTIVE            = "active"
  public static val A_TIME            = "aTime"
  
  public static val UDI               = "udi"
  public static val SEX               = "sex"
  public static val BIRTHDAY          = "birthday"
  
  def create(String udi, String sex, LocalDate birthday) {
    val map = #{ UDI -> udi, SEX -> sex, BIRTHDAY -> birthday, A_TIME -> LocalDateTime.now }
    db.cypher('''
      MERGE (n:«NODE» {«UDI»: $«UDI»})
        ON CREATE SET
          n.«ACTIVE» = true,
          n.«A_TIME» = $«A_TIME»,
          n.«UDI» = $«UDI»,
          n.«SEX» = $«SEX»,
          n.«BIRTHDAY» = $«BIRTHDAY»
      RETURN id(n) as id, n.«A_TIME» as «A_TIME»
    ''', map).head
  }
  
  def activation(Long id, Boolean active) {
    val res = db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «id»
      RETURN n.«ACTIVE» as «ACTIVE», n.«A_TIME» as «A_TIME»
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find subject: «id»''')
    
    // update A_TIME when activating
    val subject = res.head
    val aTime = if (active && !subject.get(ACTIVE) as Boolean)
      LocalDateTime.now
    else
      subject.get(A_TIME) as LocalDateTime
    
    val map = #{ ACTIVE -> active, A_TIME -> aTime }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «id»
        SET
          n.«ACTIVE» = $«ACTIVE»,
          n.«A_TIME» = $«A_TIME»
    ''', map)
    
    return # { A_TIME -> aTime }
  }
  
  def get(String udi) {
    val map = #{ UDI -> udi }
    val res = db.cypher('''
      MATCH (n:«NODE» {«UDI»: $«UDI»})
      RETURN
        id(n) as id,
        n.«UDI» as «UDI»,
        n.«ACTIVE» as «ACTIVE»,
        n.«A_TIME» as «A_TIME»,
        n.«SEX» as «SEX»,
        n.«BIRTHDAY» as «BIRTHDAY»,
        
        [(n)-[:GIVE]->(c:«Consent.NODE») | c {
          id: id(c),
          .«Consent.ACTIVE»,
          .«Consent.A_TIME»,
          .«Consent.PURPOSE»,
          .«Consent.TARGETS»,
          .«Consent.MODALITIES»
        }] as consents,
        
        [(n)-[:IS]->(p:«Patient.NODE»)-[:FROM]->(s:«Source.NODE») WHERE p.«Patient.REMOVED» = false | {
          source: s.«Source.AET»,
          pid: p.«Patient.PID»
        }] as associations
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to get subject: «udi»''')
    
    res.head
  }
  
  def associate(String udi, String source, String pid) {
    val map = #{ "udi" -> udi, "source" -> source, "pid" -> pid }
    val res = db.cypher('''
      MATCH (n:«NODE»), (s:«Source.NODE»)
        WHERE n.«UDI» = $udi AND s.«Source.AET» = $source
      MERGE (p:«Patient.NODE» {«Patient.PID»: $pid})-[:FROM]->(s)
        ON MATCH
          SET p.«Patient.REMOVED» = false
      MERGE (n)-[:IS]->(p)
      RETURN id(p) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to associate (udi, source, pid): («udi», «source», «pid»)''')
    
    res.head.get("id") as Long
  }
  
  def deAssociate(String udi, String source, String pid) {
    val map = #{ "udi" -> udi, "source" -> source, "pid" -> pid }
    val res = db.cypher('''
      MATCH (n:«NODE»)-[:IS]->(p:«Patient.NODE»)-[:FROM]->(s:«Source.NODE»)
        WHERE n.«UDI» = $udi AND p.«Patient.PID» = $pid AND s.«Source.AET» = $source
      SET p.«Patient.REMOVED» = true
      RETURN id(p) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to deAssociate (udi, source, pid): («udi», «source», «pid»)''')
    
    res.head.get("id") as Long
  }
  
  def associations(String udi) {
    val map = #{ UDI -> udi}
    val res = db.cypher('''
      MATCH (n:«NODE» {«UDI»: $udi})-[:IS]->(p:«Patient.NODE»)-[:FROM]->(s:«Source.NODE»)
        WHERE p.«Patient.REMOVED» = false
      RETURN
        s.«Source.AET» as source,
        p.«Patient.PID» as pid
    ''', map)
    
    return res.toList
  }
  
  def from(Long sourceID, String patientID) {
    val map = #{ "pid" -> patientID }
    val res = db.cypher('''
      MATCH (n:«NODE»)-[:IS]->(p:«Patient.NODE»)-[:FROM]->(s:«Source.NODE»)
        WHERE n.«ACTIVE» = true AND id(s) = «sourceID» AND p.«Patient.PID» = $pid AND p.«Patient.REMOVED» = false
      RETURN id(n) as id
    ''', map)
    
    if (res.empty) return null
    res.head.get("id") as Long
  }
  
  def boolean exist(Long sourceID, Set<String> patientIDs) {
    val map = #{ "pids" -> patientIDs }
    val res = db.cypher('''
      MATCH (n:«NODE»)-[:IS]->(p:«Patient.NODE»)-[:FROM]->(s:«Source.NODE»)
        WHERE n.«ACTIVE» = true AND id(s) = «sourceID» AND p.«Patient.PID» IN $pids AND p.«Patient.REMOVED» = false
      RETURN count(s) as size
    ''', map)
    
    return res.head.get("size") as Long !== 0L
  }
  
  def page(int skip, int limit) {
    db.cypher('''
      MATCH (n:«NODE»)
      OPTIONAL MATCH (n)-[:IS]->(p:«Patient.NODE»)
        WHERE p.«Patient.REMOVED» = false
      WITH count(DISTINCT n) as total, n {
        id: id(n),
        sources: count(DISTINCT p),
        .«UDI»,
        .«ACTIVE»,
        .«A_TIME»,
        .«SEX»,
        .«BIRTHDAY»
      } as list
      ORDER BY list.«A_TIME» DESC SKIP «skip» LIMIT «limit»
      RETURN
        total, collect(list) as data
    ''').head
  }
  
  def details(Long subjectID) {
    val res = db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «subjectID»
      RETURN n.«UDI» as udi,
        [(n)-[:IS]->(p:«Patient.NODE»)-[:FROM]->(s:«Source.NODE») WHERE p.«Patient.REMOVED» = false | p {
          id: id(p),
          source: s.«Source.AET»,
          .«Patient.PID»
        }] as sources,
        
        [(n)-[:HAS*]->(e:«Series.NODE») | e {
          id: id(e),
          .«Series.UID»,
          .«Series.SEQ»,
          .«Series.MODALITY»,
          .«Series.ELIGIBLE»,
          .«Series.SIZE»,
          .«Series.STATUS»
        }] as series
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find details for subjectID: «subjectID»''')
    
    return res.head
  }
}