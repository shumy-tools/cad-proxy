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
    
    val res = switch type {
      case FIND: db.cypher('''
        MATCH (l:«Source.NODE») WHERE id(l) = «linkID»
        CREATE (n:«NODE») SET
          n.«STARTED» = $«STARTED»,
          n.«TYPE» = $«TYPE»,
          n.«STATUS» = $«STATUS»,
          n.«S_TIME» = $«S_TIME»
        MERGE (n)-[:«FROM»]->(l)
        RETURN id(n) as id
      ''', map)
      
      case STORE: db.cypher('''
        MATCH (l:«NODE») WHERE id(l) = «linkID» AND l.«TYPE» = "«Type.FIND.name»"
        CREATE (n:«NODE») SET
          n.«STARTED» = $«STARTED»,
          n.«TYPE» = $«TYPE»,
          n.«STATUS» = $«STATUS»,
          n.«S_TIME» = $«S_TIME»
        MERGE (n)-[:«FROM»]->(l)
        RETURN id(n) as id
      ''', map)
    }
    
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
      MATCH (n:«NODE») WHERE id(n) = «pullID»
      MATCH (s:«Study.NODE») WHERE id(s) IN $sids
      MERGE (n)-[l:«THESE»]->(s)
      RETURN count(l) as size
    ''', map)
    
    res.head.get("size") as Long
  }
  
  def data(Long pullID, Type type) {
    val dataMatch = '''
      MATCH (n)-[:«THESE»]->(s:«Study.NODE»)-[:«Study.HAS»]->(e:«Series.NODE»)
      OPTIONAL MATCH (e)-[:«Series.HAS»]->(i:«Item.NODE»)
    '''
    
    val res = db.cypher('''
      «IF type == Type.FIND»
        MATCH (l:«Source.NODE»)<-[:«FROM»]-(n:«NODE»)
        WHERE id(n) = «pullID» AND n.«TYPE» = "«type.name»"
        «dataMatch»
        WITH id(l) as source, "«Source.NODE»" as sType,
      «ELSE»
        MATCH (l:«NODE»)-[:«FROM»]->(n:«NODE»)
        WHERE id(l) = «pullID» AND l.«TYPE» = "«type.name»" AND n.«TYPE» = "«Type.FIND.name»"
        «dataMatch»
        WITH id(n) as source, "«NODE»" as sType,
      «ENDIF»
        s, e,
        i {
          .«Item.UID»,
          .«Item.SEQ»,
          .«Item.TIME»
        } as l_items
      WITH source, sType, s,
        e {
          id: id(e),
          .«Series.UID»,
          .«Series.SEQ»,
          .«Series.MODALITY»,
          .«Series.COMPLETED»,
          items: collect(l_items)
        } as l_series
      WITH source, sType,
        s {
          .«Study.UID»,
          .«Study.DATE»,
          series: collect(l_series)
        } as l_study
      RETURN source, sType, collect(l_study) as studies
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find data for pullID: «pullID»''')
    
    return res.head
  }
}