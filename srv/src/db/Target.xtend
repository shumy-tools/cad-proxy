package db

import java.time.LocalDateTime
import java.util.HashSet
import java.util.Set
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.List

@FinalFieldsConstructor
class Target {
  val NeoDB db
  public static val NODE = Target.simpleName
  
  public static val REMOVED           = "removed"
  public static val ACTIVE            = "active"
  public static val A_TIME            = "aTime"
  
  public static val UDI               = "udi"
  public static val NAME              = "name"
  public static val MODALITIES        = "modalities"
  
  def create(String udi, String name, Set<String> modalities) {
    val map = #{ UDI -> udi, NAME -> name, MODALITIES -> modalities, A_TIME -> LocalDateTime.now }
    db.cypher('''
      MERGE (n:«NODE» {«UDI»: $«UDI»})
        ON CREATE SET
          n.«REMOVED» = false,
          n.«ACTIVE» = true,
          n.«A_TIME» = $«A_TIME»,
          n.«UDI» = $«UDI»,
          n.«NAME» = $«NAME»,
          n.«MODALITIES» = $«MODALITIES»
      RETURN id(n) as id, n.«A_TIME» as «A_TIME»
    ''', map).head
  }
  
  def set(Long id, Boolean active, String udi, String name, Set<String> modalities) {
    if (id === null)
      create(udi, name, modalities)
    else {
      val res = db.cypher('''
        MATCH (n:«NODE») WHERE id(n) = «id» AND n.«REMOVED» = false
        RETURN n.«ACTIVE» as «ACTIVE», n.«A_TIME» as «A_TIME»
      ''')
        
      if (res.empty)
        throw new RuntimeException('''Unable to find target for: «id»''')
      
      // update A_TIME when activating
      val edge = res.head
      val aTime = if (active && !edge.get(ACTIVE) as Boolean)
        LocalDateTime.now
      else
        edge.get(A_TIME) as LocalDateTime
      
      val map = #{ UDI -> udi, NAME -> name, MODALITIES -> modalities, ACTIVE -> active, A_TIME -> aTime }
      db.cypher('''
        MATCH (n:«NODE») WHERE id(n) = «id»
          SET
            n.«ACTIVE» = $«ACTIVE»,
            n.«A_TIME» = $«A_TIME»,
            n.«NAME» = $«NAME»,
            n.«MODALITIES» = $«MODALITIES»
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
      throw new RuntimeException('''Unable to find target for: «id»''')
      
    return res.head.get("id")
  }
  
  def all() {
    db.cypher('''MATCH (n:«NODE»)
      WHERE n.«REMOVED» = false
    RETURN
      id(n) as id,
      n.«ACTIVE» as «ACTIVE»,
      n.«A_TIME» as «A_TIME»,
      n.«UDI» as «UDI»,
      n.«NAME» as «NAME»,
      n.«MODALITIES» as «MODALITIES»
    ''').toList
  }
  
  def modalities() {
    val res = db.cypher('''
      MATCH (t:«NODE»)
        WHERE n.«ACTIVE» = true AND n.«REMOVED» = false
      RETURN t.«MODALITIES» as «MODALITIES»
    ''')
    
    val mods = new HashSet<String>
    res.map[get(MODALITIES) as String[]].forEach[mods.addAll(it)]
    
    return mods as Set<String>
  }
  
  def pendingSeries() {
    db.cypher('''
      «pendingMatch(Series.Status.READY, null)»
      RETURN id(n) as id, collect(id(e)) as series
    ''').toSet
  }
  
  def pendingSeries(Long targetID) {
    val res = db.cypher('''
      «pendingMatch(Series.Status.READY, targetID)»
      RETURN collect(id(e)) as series
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find pending series for targetID: «targetID»''')
      
    return (res.head.get("series") as List<Long>).toSet
  }
  
  def pending() {
    db.cypher('''
      «pendingMatch(null, null)»
      RETURN
        id(n) as id,
        n.«NAME» as target,
        count(DISTINCT u) as subjects,
        count(DISTINCT e) as series,
        collect(DISTINCT e.«Series.MODALITY») as modalities
      ORDER BY target
    ''').toList
  }
  
  def pendingDetails(Long targetID) {
    val res = db.cypher('''
    «pendingMatch(null, targetID)»
      WITH n, e {
        id: id(e),
        subject: u.«Subject.UDI»,
        date: s.«Study.DATE»,
        .«Series.MODALITY»,
        .«Series.SIZE»,
        .«Series.STATUS»,
        .«Series.S_TIME»,
        .«Series.ERROR»
      } as list
      ORDER BY list.date DESC
      RETURN id(n) as id, n.«UDI» as udi, collect(list) as series
    ''')
    
    if (res.empty)
      throw new RuntimeException('''Unable to find pending details for targetID: «targetID»''')
    
    return res.head
  }
  
  private def pendingMatch(Series.Status status, Long targetID) '''
    MATCH (u:«Subject.NODE»)-[:GIVE]->(c:«Consent.NODE»)
      WHERE c.«Consent.ACTIVE» = true AND c.«Consent.PURPOSE» = "auto pre-diagnosis"
    MATCH (n:«NODE»)
      WHERE «IF targetID !== null»id(n) = «targetID» AND«ENDIF»
        n.«ACTIVE» = true AND n.«REMOVED» = false
        AND (c.«Consent.TARGETS» = "all" OR n.«UDI» IN c.«Consent.TARGETS»)
    MATCH (u)-[:HAS]->(s:«Study.NODE»)-[:HAS]->(e:«Series.NODE»)
      WHERE u.«Subject.ACTIVE» = true
        AND e.«Series.ELIGIBLE» = true AND e.size > 0 «IF status !== null»AND e.«Series.STATUS» = "«status.name»"«ENDIF»
        AND e.«Series.MODALITY» IN n.«MODALITIES»
        AND (c.«Consent.MODALITIES» = "all" OR e.«Series.MODALITY» IN c.«Consent.MODALITIES»)
    MATCH (e) WHERE NOT (e)<-[:THESE]-(:«Push.NODE»)-[:TO]->(n) 
      «IF status !== null»OR (e)<-[:THESE]-(:«Push.NODE» {status:"«Push.Status.RETRY.name»"})-[:TO]->(n)«ENDIF» 
  '''
  
  /*private def pendingMatch(Series.Status status, Long targetID) '''
    MATCH (n:«NODE»)<-[:CONSENT]-(u:«Subject.NODE»)-[:HAS]->(s:«Study.NODE»)-[:HAS]->(e:«Series.NODE»)
      WHERE «IF targetID !== null»id(n) = «targetID» AND«ENDIF»
        u.«Subject.ACTIVE» = true AND n.«ACTIVE» = true AND n.«REMOVED» = false
        AND e.«Series.ELIGIBLE» = true AND e.size > 0 «IF status !== null»AND e.«Series.STATUS» = "«status.name»"«ENDIF»
        AND e.«Series.MODALITY» IN n.«MODALITIES»
    MATCH (e) WHERE NOT (e)<-[:THESE]-(:«Push.NODE»)-[:TO]->(n) 
      «IF status !== null»OR (e)<-[:THESE]-(:«Push.NODE» {status:"«Push.Status.RETRY.name»"})-[:TO]->(n)«ENDIF» 
  '''*/
}