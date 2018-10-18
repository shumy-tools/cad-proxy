package db

import java.time.LocalDateTime
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Pull {
  enum Type { FIND, STORE }
  enum Status { START, END, ERROR }
  
  val NeoDB db
  public static val NODE = Pull.simpleName
  
  public static val STARTED             = "started"
  public static val TYPE                = "type"
  
  public static val STATUS              = "status"
  public static val S_TIME              = "sTime"
  public static val ERROR               = "error"
  
  public static val FROM                = "FROM"
  public static val THESE               = "THESE"
  
  def Long create(Long linkID, Type type) {
    val map = #{ STARTED -> LocalDateTime.now, TYPE -> type.name, STATUS -> Status.START.name, S_TIME -> LocalDateTime.now }
    
    val res = db.cypher('''
      «IF type == Type.FIND»
        MATCH (s:«Source.NODE») WHERE id(s) = «linkID»
      «ELSE»
        MATCH (s:«NODE») WHERE id(s) = «linkID» AND s.«TYPE» = "«Type.FIND.name»"
      «ENDIF»
        CREATE (n:«NODE») SET
          n.«STARTED» = $«STARTED»,
          n.«TYPE» = $«TYPE»,
          n.«STATUS» = $«STATUS»,
          n.«S_TIME» = $«S_TIME»
        MERGE (n)-[:«FROM»]->(s)
        RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to create pull. Probable cause, no valid linkID=«linkID»''')
      
    res.head.get("id") as Long
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
      SET n.«STATUS» = «Status.ERROR.name», n.«S_TIME» = $«S_TIME», n.«ERROR» = $«ERROR»
    ''', map)
  }
  
  def Long linkStudies(Long pullID, Iterable<Long> studiesIDs) {
    val map = #{ "sids" -> studiesIDs }
    val res = db.cypher('''
      MATCH (n:«NODE»), (s:«Study.NODE»)
        WHERE id(n) = «pullID» AND id(s) IN $sids
      MERGE (n)-[l:«THESE»]->(s)
      RETURN count(l) as size
    ''', map)
    
    res.head.get("size") as Long
  }
  
  def data(Long pullID, Type type) {
    val res = db.cypher('''
      «IF type == Type.FIND»
        MATCH (l:«Source.NODE»)<-[:«FROM»]-(n:«NODE»)
        WHERE id(n) = «pullID» AND n.«TYPE» = "«type.name»"
        WITH id(l) as source, "«Source.NODE»" as sType, n
      «ELSE»
        MATCH (l:«NODE»)-[:«FROM»]->(n:«NODE»)
        WHERE id(l) = «pullID» AND l.«TYPE» = "«type.name»" AND n.«TYPE» = "«Type.FIND.name»"
        WITH id(n) as source, "«NODE»" as sType, n
      «ENDIF»
      RETURN source, sType, [(n)-[:«THESE»]->(s:«Study.NODE»)<-[:HAS]-(p:«Subject.NODE») | s {
        subject: p.«Subject.UDI»,
        .«Study.UID»,
        .«Study.DATE»,
        series: [(s)-[:HAS]->(e:«Series.NODE») | e {
          id: id(e),
          .«Series.UID»,
          .«Series.SEQ»,
          .«Series.MODALITY»,
          .«Series.COMPLETED»,
          items: [(e)-[:HAS]->(i:«Item.NODE») | i {
            .«Item.UID»,
            .«Item.SEQ»,
            .«Item.TIME»
          }]
        }]
      }] as studies
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find data for pullID: «pullID»''')
    
    return res.head
  }
}