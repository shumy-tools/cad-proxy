package db

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Consent {
  val NeoDB db
  public static val NODE = Consent.simpleName
  
  public static val ACTIVE            = "active"
  public static val A_TIME            = "aTime"
  
  public static val PURPOSE           = "purpose"
  public static val TARGETS           = "targets"
  public static val MODALITIES        = "modalities"
  
  def consentsFromSubject(String subjectUDI) {
    val map = #{ "udi" -> subjectUDI }
    db.cypher('''MATCH (s:«Subject.NODE»)-[:GIVE]->(n:«NODE»)
      WHERE s.«Subject.UDI» = $udi
    RETURN
      id(n) as id,
      n.«ACTIVE» as «ACTIVE»,
      n.«A_TIME» as «A_TIME»,
      n.«PURPOSE» as «PURPOSE»,
      n.«TARGETS» as «TARGETS»,
      n.«MODALITIES» as «MODALITIES»
    ''', map).toList
  }
}