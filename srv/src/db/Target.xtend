package db

import java.time.LocalDateTime
import java.util.HashSet
import java.util.Set
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Target {
  val NeoDB db
  public static val NODE = Target.simpleName
  
  public static val ACTIVE = "active"
  public static val A_TIME = "aTime"
  
  public static val UDI = "udi"
  public static val NAME = "name"
  public static val MODALITIES = "modalities"
  
  def Long create(String udi, String name, Set<String> modalities) {
    val map = #{ UDI -> udi, NAME -> name, MODALITIES -> modalities }
    val res = db.cypher('''
      MERGE (t:«NODE» {«UDI»: $«UDI»})
      ON CREATE SET
        t.«ACTIVE» = true,
        t.«A_TIME» = "«LocalDateTime.now»",
        t.«UDI» = $«UDI»,
        t.«NAME» = $«NAME»,
        t.«MODALITIES» = $«MODALITIES»
      RETURN id(t) as id
    ''', map)
    
    res.head.get("id") as Long
  }
  
  def getAll() {
    db.cypher('''MATCH (t:«NODE») RETURN
      t.«ACTIVE» as «ACTIVE»,
      t.«A_TIME» as «A_TIME»,
      t.«UDI» as «UDI»,
      t.«NAME» as «NAME»,
      t.«MODALITIES» as «MODALITIES»
    ''')
  }
  
  def getModalities() {
    val res = db.cypher('''MATCH (t:«NODE») RETURN t.«MODALITIES» as «MODALITIES»''')
    
    val mods = new HashSet<String>
    res.map[get(MODALITIES) as String[]].forEach[mods.addAll(it)]
    
    return mods as Set<String>
  }
}