package db

import java.time.LocalDateTime
import java.util.Set
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Push {
  enum Status { START, PREPARE, TRANSMIT, END, ERROR, RETRY }
    
  val NeoDB db
  public static val NODE = Push.simpleName
  
  public static val STARTED             = "started"
  
  public static val STATUS              = "status"
  public static val S_TIME              = "sTime"
  public static val ERROR               = "error"
  
  def Long create(Long targetID, Set<Long> seriesIDs) {
    val map = #{ "series" -> seriesIDs, STARTED -> LocalDateTime.now, STATUS -> Status.START.name, S_TIME -> LocalDateTime.now }
    val res = db.cypher('''
      CREATE (n:«NODE») SET
        n.«STARTED» = $«STARTED»,
        n.«STATUS» = $«STATUS»,
        n.«S_TIME» = $«S_TIME»
      WITH n
      MATCH (t:«Target.NODE»), (e:«Series.NODE»)
        WHERE id(t) = «targetID» AND id(e) IN $series
      MERGE (e)<-[:THESE]-(n)-[:TO]->(t)
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create a push. Probable cause, no valid targetID=«targetID»''')
      
    return res.head.get("id") as Long
  }
  
  def void these(Long pushID, Long seriesID) {
    db.cypher('''
      MATCH (n:«NODE»), (e:«Series.NODE»)
        WHERE id(n) = «pushID» AND id(e) = «seriesID»
      MERGE (n)-[:THESE]->(e)
    ''')
  }
  
  def void status(Long pushID, Status status) {
    val map = #{ STATUS -> status.name, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pushID»
      SET n.«STATUS» = $«STATUS», n.«S_TIME» = $«S_TIME»
    ''', map)
  }
  
  def void error(Long pushID, String error) {
    val map = #{ ERROR -> error, S_TIME -> LocalDateTime.now }
    db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pushID»
      SET n.«STATUS» = "«Status.ERROR.name»", n.«S_TIME» = $«S_TIME», n.«ERROR» = $«ERROR»
    ''', map)
  }
  
  def Set<Long> pending() {
    val res = db.cypher('''
      MATCH (n:«NODE»)
        WHERE n.«STATUS» = "«Status.START.name»" OR n.«STATUS» = "«Status.RETRY.name»"
      RETURN id(n) as id
    ''')
    
    return res.map[get("id") as Long].toSet
  }
  
  def page(int skip, int limit) {
    db.cypher('''
      MATCH (n:«NODE»)-[:TO]->(t:«Target.NODE»)
      OPTIONAL MATCH (n)-[:THESE]->(e:«Series.NODE»)<-[:HAS*]-(s:«Subject.NODE»)
      WITH count(DISTINCT n) as total, {
        id: id(n),
        target: t.«Target.NAME»,
        started: n.«STARTED»,
        subjects: count(DISTINCT s),
        series: count(DISTINCT e),
        status: n.«STATUS»,
        stime: n.«S_TIME»,
        error: n.«ERROR»
      } as list
      ORDER BY list.started SKIP «skip» LIMIT «limit»
      RETURN
        total, collect(list) as data
    ''').head
  }
  
  def details(Long pushID) {
    val res = db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «pushID»
      RETURN id(n) as id,
        [(n)-[:THESE]->(e:«Series.NODE»)<-[:HAS*]-(p:«Subject.NODE») | e {
          subject: p.«Subject.UDI»,
          id: id(e),
          .«Series.MODALITY»,
          .«Series.SIZE»,
          .«Series.STATUS»
        }] as series
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find details for pushID: «pushID»''')
    
    return res.head
  }
  
  def data(Long pushID) {
    val res = db.cypher('''
      MATCH (n:«NODE»)-[:TO]->(t:«Target.NODE»)
        WHERE id(n) = «pushID»
      WITH t.«Target.UDI» as target, n
      RETURN target, n.«STATUS» as status, [(n)-[:THESE]->(e:«Series.NODE»)<-[:HAS*]-(p:«Subject.NODE») | e {
        subject: p.«Subject.UDI»,
        id: id(e),
        .«Series.UID»,
        .«Series.SEQ»,
        .«Series.MODALITY»,
        .«Series.ELIGIBLE»,
        .«Series.SIZE»,
        .«Series.STATUS»,
        .«Series.S_TIME»,
        .«Series.ERROR»
      }] as series
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find data for pushID: «pushID»''')
    
    return res.head
  }
}