package db.mng

import db.NeoDB
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.dcm4che2.data.Tag
import java.util.Set
import java.util.HashSet
import java.util.ArrayList
import java.util.List
import java.util.Collection

@FinalFieldsConstructor
class Key {
  val NeoDB db
  public static val NODE = Key.simpleName
  
  public static val ACTIVE              = "active"
  public static val GROUP               = "group"
  public static val KEY                 = "key"
  public static val VALUE               = "value"
  
  def setupDefault() {
    create("path", "cache", "/cache")
    
    create("pull", "interval", 3) // 3 hours interval
    
    create("push", "interval", 3) // 3 hours interval
    
    create("local-aet", "aet", "CAD-PROXY")
    create("local-aet", "eth-name", "lo")
    create("local-aet", "port", 1104)
    
    create("dicom", "white-list", #{
      Tag.SOPClassUID,
      
      Tag.PatientOrientation,
      
      Tag.StudyDate,
      Tag.StudyTime,
      
      Tag.SeriesNumber,
      Tag.Modality,
      
      Tag.InstanceNumber,
      Tag.AcquisitionNumber,
      Tag.ContentDate,
      Tag.ContentTime,
      Tag.Laterality,
      
      Tag.PixelData,
      Tag.Columns,
      Tag.Rows,
      Tag.BitsAllocated,
      Tag.BitsStored,
      Tag.HighBit,
      Tag.PixelRepresentation,
      Tag.SamplesPerPixel,
      Tag.PhotometricInterpretation,
      Tag.PlanarConfiguration
    })
  }
  
  def create(String group, String key, Object value) {
    val map = #{ GROUP -> group, KEY -> key, VALUE -> value }
    val res = db.cypher('''
      MERGE (n:«NODE» {«GROUP»: $«GROUP», «KEY»: $«KEY»})
        ON CREATE SET
          n.«ACTIVE» = true,
          n.«VALUE» = $«VALUE»
      RETURN id(n) as id
    ''', map)
    
    res.head.get("id") as Long
  }
  
  def set(String group, String key, Object value) {
    val map = #{ GROUP -> group, KEY -> key, VALUE -> value }
    val res = db.cypher('''
      MERGE (n:«NODE» {«GROUP»: $«GROUP», «KEY»: $«KEY»})
        ON CREATE SET
          n.«ACTIVE» = true,
          n.«VALUE» = $«VALUE»
        ON MATCH SET
          n.«VALUE» = $«VALUE»
      RETURN id(n) as id
    ''', map)
    
    res.head.get("id") as Long
  }
  
  def <T> getOrDefault(Class<T> type, String group, String key, T defValue) {
    val map = #{ GROUP -> group, KEY -> key }
    val res = db.cypher('''
      MATCH (n:«NODE» {«GROUP»: $«GROUP», «KEY»: $«KEY»})
      RETURN
        n.«ACTIVE» as «ACTIVE», 
        n.«VALUE» as «VALUE»
    ''', map)
    
    if (res.empty)
      return defValue
    
    val keyNode = res.head
    if (!keyNode.get(ACTIVE) as Boolean)
      throw new RuntimeException('''The (group, key)=(«group», «key») is not active.''')
    
    val value = tryConvert(keyNode.get(VALUE), type)
    if (!type.isAssignableFrom(value.class))
      throw new RuntimeException('''Incorrect type for (type, group, key)=(«value.class.simpleName», «group», «key»). Requested type «type.simpleName»''')
    
    return value as T
  }
  
  def <T> get(Class<T> type, String group, String key) {
    val value = getOrDefault(type, group, key, null)
    
    if (value === null)
      throw new RuntimeException('''Unable to find (group, key)=(«group», «key»)''')
      
    return value
  }
  
  def all() {
    db.cypher('''MATCH (n:«NODE»)
      RETURN
        n.«ACTIVE» as «ACTIVE»,
        n.«GROUP» as «GROUP»,
        n.«KEY» as «KEY»,
        n.«VALUE» as «VALUE»
      ORDER BY «GROUP», «KEY»
    ''')
  }
  
  private def Object tryConvert(Object value, Class<?> toType) {
    val type = value.class
    if (type.array) {
      val Collection<?> array = switch type.componentType {
        case int: value as int[]
        case long: value as long[]
        case String: value as String[]
      }
      
      switch toType {
        case Set: return new HashSet(array)
        case List: return new ArrayList(array)
      }
    }
    
    return value
  }
}