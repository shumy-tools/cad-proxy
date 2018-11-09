package db

import java.time.LocalDateTime
import java.util.HashSet
import java.util.Set
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Target {
  val NeoDB db
  public static val NODE = Target.simpleName
  
  public static val ACTIVE            = "active"
  public static val A_TIME            = "aTime"
  
  public static val UDI               = "udi"
  public static val NAME              = "name"
  public static val MODALITIES        = "modalities"
  
  def Long create(String udi, String name, Set<String> modalities) {
    val map = #{ UDI -> udi, NAME -> name, MODALITIES -> modalities, A_TIME -> LocalDateTime.now }
    val res = db.cypher('''
      MERGE (n:«NODE» {«UDI»: $«UDI»})
        ON CREATE SET
          n.«ACTIVE» = true,
          
          n.«A_TIME» = $«A_TIME»,
          n.«UDI» = $«UDI»,
          n.«NAME» = $«NAME»,
          n.«MODALITIES» = $«MODALITIES»
      RETURN id(n) as id
    ''', map)
    
    res.head.get("id") as Long
  }
  
  def all() {
    db.cypher('''MATCH (n:«NODE») RETURN
      id(n) as id,
      n.«ACTIVE» as «ACTIVE»,
      n.«A_TIME» as «A_TIME»,
      n.«UDI» as «UDI»,
      n.«NAME» as «NAME»,
      n.«MODALITIES» as «MODALITIES»
    ''')
  }
  
  def modalities() {
    val res = db.cypher('''MATCH (t:«NODE») RETURN t.«MODALITIES» as «MODALITIES»''')
    
    val mods = new HashSet<String>
    res.map[get(MODALITIES) as String[]].forEach[mods.addAll(it)]
    
    return mods as Set<String>
  }
  
  def pendingSeries() {
    db.cypher(pendingMatch(Series.Status.READY) + "RETURN id(n) as id, collect(id(e)) as series")
  }
  
  def pendingPage(int skip, int limit) {
    db.cypher('''
      MATCH (n:«NODE»)<-[:CONSENT]-(u:«Subject.NODE»)
        WHERE u.«Subject.ACTIVE» = true AND n.«ACTIVE» = true
      MATCH (u)-[:HAS*]->(e:«Series.NODE»)
        WHERE e.«Series.ELIGIBLE» = true AND e.size > 0 AND e.«Series.MODALITY» IN n.«MODALITIES»
      WITH count(DISTINCT n) as total, n {
        id: id(n),
        subjects: count(DISTINCT u),
        series: count(DISTINCT e),
        .«UDI»,
        .«NAME»
      } as list
      ORDER BY list.«NAME» SKIP «skip» LIMIT «limit»
      RETURN
        total, collect(list) as data
    ''').head
    
    /*
        subject: p.«Subject.UDI»,
        .«Series.MODALITY»,
        .«Series.SIZE»,
        .«Series.STATUS»,
        .«Series.S_TIME»,
        .«Series.ERROR»
     */
  }
  
  private def pendingMatch(Series.Status status) '''
    MATCH (n:«NODE»)<-[:CONSENT]-(p:«Subject.NODE»)-[:HAS*]->(e:«Series.NODE»)
      WHERE p.«Subject.ACTIVE» = true AND n.«ACTIVE» = true
        AND e.«Series.ELIGIBLE» = true AND e.size > 0 «IF status !== null»AND e.«Series.STATUS» = "«status.name»"«ENDIF»
        AND e.«Series.MODALITY» IN n.«MODALITIES»
    MATCH (e) WHERE NOT (e)<-[:THESE]-(:«Push.NODE»)-[:TO]->(n) 
      «IF status !== null»OR (e)<-[:THESE]-(:«Push.NODE» {status:"«Push.Status.RETRY.name»"})-[:TO]->(n)«ENDIF» 
  '''
}