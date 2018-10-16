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
  
  def getAll() {
    db.cypher('''MATCH (n:«NODE») RETURN
      id(n) as id,
      n.«ACTIVE» as «ACTIVE»,
      n.«A_TIME» as «A_TIME»,
      n.«UDI» as «UDI»,
      n.«NAME» as «NAME»,
      n.«MODALITIES» as «MODALITIES»
    ''')
  }
  
  def getModalities() {
    val res = db.cypher('''MATCH (t:«NODE») RETURN t.«MODALITIES» as «MODALITIES»''')
    
    val mods = new HashSet<String>
    res.map[get(MODALITIES) as String[]].forEach[mods.addAll(it)]
    
    return mods as Set<String>
  }
}