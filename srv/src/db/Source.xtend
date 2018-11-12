package db

import java.time.LocalDateTime
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Source {
  val NeoDB db
  public static val NODE = Source.simpleName
  
  public static val REMOVED           = "removed"
  public static val ACTIVE            = "active"
  public static val A_TIME            = "aTime"
  
  public static val AET               = "aet"
  public static val HOST              = "host"
  public static val PORT              = "port"
  
  def create(String aet, String host, Integer port) {
    val map = #{ AET -> aet, HOST -> host, PORT -> port, A_TIME -> LocalDateTime.now}
    db.cypher('''
      MERGE (n:«NODE» {«AET»: $«AET»})
        ON CREATE SET
          n.«REMOVED» = false,
          n.«ACTIVE» = true,
          n.«A_TIME» = $«A_TIME»,
          n.«AET» = $«AET»,
          n.«HOST» = $«HOST»,
          n.«PORT» = $«PORT»
      RETURN id(n) as id, n.«A_TIME» as «A_TIME»
    ''', map).head
  }
  
  def set(Long id, Boolean active, String aet, String host, Integer port) {
    if (id === null)
      create(aet, host, port)
    else {
      val res = db.cypher('''
        MATCH (n:«NODE») WHERE id(n) = «id» AND n.«REMOVED» = false
        RETURN n.«ACTIVE» as «ACTIVE», n.«A_TIME» as «A_TIME»
      ''')
        
      if (res.empty)
        throw new RuntimeException('''Unable to find source for: «id»''')
      
      // update A_TIME when activating
      val edge = res.head
      val aTime = if (active && !edge.get(ACTIVE) as Boolean)
        LocalDateTime.now
      else
        edge.get(A_TIME) as LocalDateTime
      
      val map = #{ AET -> aet, HOST -> host, PORT -> port, ACTIVE -> active, A_TIME -> aTime }
      db.cypher('''
        MATCH (n:«NODE») WHERE id(n) = «id»
          SET
            n.«ACTIVE» = $«ACTIVE»,
            n.«A_TIME» = $«A_TIME»,
            n.«AET» = $«AET»,
            n.«HOST» = $«HOST»,
            n.«PORT» = $«PORT»
        RETURN id(n) as id, n.«A_TIME» as «A_TIME»
      ''', map).head
    }
  }
  
  def remove(Long id) {
    val res = db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «id»
        SET
          n.«REMOVED» = true,
          n.«ACTIVE» = false
      RETURN id(n) as id
    ''')
   
    if (res.empty)
      throw new RuntimeException('''Unable to find source for: «id»''')
      
    return res.head.get("id")
  }
  
  def all() {
    db.cypher('''MATCH (n:«NODE»)
      WHERE n.«REMOVED» = false
    RETURN
      id(n) as id,
      n.«ACTIVE» as «ACTIVE»,
      n.«A_TIME» as «A_TIME»,
      n.«AET» as «AET»,
      n.«HOST» as «HOST»,
      n.«PORT» as «PORT»
    ''').toList
  }
  
  def idFromAET(String aet) {
    val map = #{ AET -> aet }
    val res = db.cypher('''
      MATCH (n:«NODE»)
        WHERE n.«AET» = $«AET» n.«REMOVED» = false
      RETURN id(n) as id
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to find source by aet: «aet»''')
    
    res.head.get("id") as Long
  }
  
  def byId(Long id) {
    val res = db.cypher('''
      MATCH (n:«NODE») WHERE id(n) = «id»
        WHERE n.«REMOVED» = false
      RETURN
        id(n) as id,
        n.«ACTIVE» as «ACTIVE»,
        n.«A_TIME» as «A_TIME»,
        n.«AET» as «AET»,
        n.«HOST» as «HOST»,
        n.«PORT» as «PORT»
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find source by id: «id»''')
    
    res.head
  }
}