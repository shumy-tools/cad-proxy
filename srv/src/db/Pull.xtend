package db

import java.time.LocalDateTime
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Pull {
  enum Type { REQ, PULL }
  enum Status { START, READY, END, ERROR }
  
  val NeoDB db
  public static val NODE = Pull.simpleName
  
  public static val STARTED             = "started"
  public static val TYPE                = "type"
  public static val PULL_TRIES          = "pullTries"
  
  public static val STATUS              = "status"
  public static val S_TIME              = "sTime"
  public static val ERROR               = "error"
  
  def Long createRequest(Long sourceID) {
    val map = #{ STARTED -> LocalDateTime.now, STATUS -> Status.START.name, S_TIME -> LocalDateTime.now }
    
    val res = db.cypher('''
      MATCH (s:«Source.NODE»)
        WHERE id(s) = «sourceID»
      CREATE (n:«NODE») SET
        n.«PULL_TRIES» = 0,
        n.«TYPE» = "«Type.REQ»",
        
        n.«STARTED» = $«STARTED»,
        n.«STATUS» = $«STATUS»,
        n.«S_TIME» = $«S_TIME»
      MERGE (n)-[:FROM]->(s) 
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create a pull-request. Probable cause, no valid sourceID=«sourceID»''')
    
    return res.head.get("id") as Long
  }
  
  def Long createPull(Long requestID) {
    val map = #{ STARTED -> LocalDateTime.now, STATUS -> Status.START.name, S_TIME -> LocalDateTime.now }
    
    val res = db.cypher('''
      MATCH (s:«NODE»)
        WHERE id(s) = «requestID» AND s.«TYPE» = "«Type.REQ.name»"
      CREATE (n:«NODE») SET
        n.«PULL_TRIES» = 0,
        n.«TYPE» = "«Type.PULL.name»",
        
        n.«STARTED» = $«STARTED»,
        n.«STATUS» = $«STATUS»,
        n.«S_TIME» = $«S_TIME»
      MERGE (n)-[:FROM]->(s)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create a pull. Probable cause, no valid requestID=«requestID»''')
    
    // update pull-tries
    db.cypher('''
      MATCH (s:«NODE») WHERE id(s) = «requestID»
        SET s.«PULL_TRIES» = size([(l:«NODE»)-[:FROM]->(s) | l])
    ''')
    
    return res.head.get("id") as Long
  }
  
  def void these(Long requestID, Long studyID) {
    db.cypher('''
      MATCH (n:«NODE»), (s:«Study.NODE»)
        WHERE id(n) = «requestID» AND id(s) = «studyID»
      MERGE (n)-[:THESE]->(s)
    ''')
  }
  
  def void updateStatusOnPullTries(Long pullID) {
    val res = db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pullID» AND n.«TYPE» = "«Type.REQ.name»"
      RETURN n.«PULL_TRIES» as tries
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find pull-request for pullID=«pullID»''')
      
    val pullTries = res.head.get("tries") as Integer
    if (pullTries > 2)
      error(pullID, "Exceeded the number of pull-tries!")
  }
  
  def void status(Long pullID, Status status) {
    val map = #{ STATUS -> status.name, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pullID»
      SET n.«STATUS» = $«STATUS», n.«S_TIME» = $«S_TIME»
    ''', map)
  }
  
  def void error(Long pullID, String error) {
    val map = #{ ERROR -> error, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pullID»
      SET n.«STATUS» = "«Status.ERROR.name»", n.«S_TIME» = $«S_TIME», n.«ERROR» = $«ERROR»
    ''', map)
  }
  
  def data(Long pullID, Type type) {
    val res = db.cypher('''
      «IF type == Type.REQ»
        MATCH (l:«Source.NODE»)<-[:FROM]-(n:«NODE»)
        WHERE id(n) = «pullID» AND n.«TYPE» = "«type.name»"
        WITH id(l) as source, "«Source.NODE»" as sType, n
      «ELSE»
        MATCH (l:«NODE»)-[:FROM]->(n:«NODE»)
        WHERE id(l) = «pullID» AND l.«TYPE» = "«type.name»" AND n.«TYPE» = "«Type.REQ.name»"
        WITH id(n) as source, "«NODE»" as sType, n
      «ENDIF»
      RETURN source, sType, n.«STATUS» as status, [(n)-[:THESE]->(s:«Study.NODE»)<-[:HAS]-(p:«Subject.NODE») | s {
        subject: p.«Subject.UDI»,
        id: id(s),
        .«Study.UID»,
        .«Study.DATE»,
        series: [(s)-[:HAS]->(e:«Series.NODE») | e {
          id: id(e),
          .«Series.UID»,
          .«Series.SEQ»,
          .«Series.MODALITY»,
          .«Series.ELIGIBLE»,
          .«Series.SIZE»,
          .«Series.STATUS»,
          .«Series.S_TIME»,
          .«Series.ERROR»
        }]
      }] as studies
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find data for pullID: «pullID»''')
    
    return res.head
  }
}