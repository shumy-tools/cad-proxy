package db.mng

import db.NeoDB
import java.util.Collection
import java.util.HashSet
import java.util.Set
import org.dcm4che2.data.Tag
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Key {
  val NeoDB db
  public static val NODE = Key.simpleName
  
  public static val ACTIVE              = "active"
  public static val TYPE                = "type"
  public static val GROUP               = "group"
  public static val KEY                 = "key"
  public static val VALUE               = "value"
  
  def setupDefault() {
    //db.cypher("MATCH (n:Key) DETACH DELETE n")
    
    create("String", "path", "cache", "/cache")
    
    create("Integer", "pull", "interval", 3) // 3 hours interval
    create("Integer","push", "interval", 3) // 3 hours interval
    
    create("String", "local-aet", "aet", "CAD-PROXY")
    create("String", "local-aet", "eth-name", "lo")
    create("Integer","local-aet", "port", 1104)
    
    create("Set-Integer", "dicom", "white-list", #{
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
    
    create("Set-String", "dicom", "modalities", #{
      "CT-Computed Tomography",
      "MR-Magnetic Resonance",
      "XA-X-Ray Angiography",
      "MG-Mammography",
      "XC-External-camera Photography"
    })
  }
  
  def create(String type, String group, String key, Object value) {
    if(!isValidType(type, value))
      throw new RuntimeException('''Incorrect (type, vType)=(«type», «value.class.simpleName»)''')
    
    val map = #{ TYPE -> type,  GROUP -> group, KEY -> key, VALUE -> value }
    val res = db.cypher('''
      MERGE (n:«NODE» {«GROUP»: $«GROUP», «KEY»: $«KEY»})
        ON CREATE SET
          n.«ACTIVE» = true,
          n.«TYPE» = $«TYPE»,
          n.«VALUE» = $«VALUE»
      RETURN id(n) as id
    ''', map)
    
    res.head.get("id") as Long
  }
  
  def set(String type, String group, String key, Object value) {
    if(!isValidType(type, value))
      throw new RuntimeException('''Incorrect (type, vType)=(«type», «value.class.simpleName»)''')
    
    val map = #{ TYPE -> type, GROUP -> group, KEY -> key, VALUE -> value }
    val res = db.cypher('''
      MERGE (n:«NODE» {«GROUP»: $«GROUP», «KEY»: $«KEY»})
        ON CREATE SET
          n.«ACTIVE» = true,
          n.«TYPE» = $«TYPE»,
          n.«VALUE» = $«VALUE»
        ON MATCH SET
          n.«VALUE» = $«VALUE»
      RETURN id(n) as id
    ''', map)
    
    res.head.get("id") as Long
  }
  
  def <T> T getOrDefault(String group, String key, T defValue) {
    val map = #{ GROUP -> group, KEY -> key }
    val res = db.cypher('''
      MATCH (n:«NODE» {«GROUP»: $«GROUP», «KEY»: $«KEY»})
      RETURN
        n.«ACTIVE» as «ACTIVE»,
        n.«TYPE» as «TYPE»,
        n.«VALUE» as «VALUE»
    ''', map)
    
    if (res.empty)
      return defValue
    
    val keyNode = res.head
    if (!keyNode.get(ACTIVE) as Boolean)
      throw new RuntimeException('''The (group, key)=(«group», «key») is not active.''')
    
    return tryConvert(keyNode.get(VALUE), keyNode.get(TYPE) as String) as T
  }
  
  def <T> T get(String group, String key) {
    val value = getOrDefault(group, key, null)
    
    if (value === null)
      throw new RuntimeException('''Unable to find (group, key)=(«group», «key»)''')
      
    return value
  }
  
  def all() {
    db.cypher('''MATCH (n:«NODE»)
      RETURN
        n.«ACTIVE» as «ACTIVE»,
        n.«TYPE» as «TYPE»,
        n.«GROUP» as «GROUP»,
        n.«KEY» as «KEY»,
        n.«VALUE» as «VALUE»
      ORDER BY «GROUP», «KEY»
    ''').map[
      #{
        ACTIVE -> get(ACTIVE),
        TYPE -> get(TYPE),
        GROUP -> (GROUP),
        KEY -> get(KEY),
        VALUE -> tryConvert(get(VALUE), get(TYPE) as String)
      }
    ].toList
  }
  
  private def isValidType(String type, Object value) {
    val tList = type.split("-")
    
    switch tList.get(0) {
      case String.simpleName: value.class === String
      case Integer.simpleName: value.class === Integer
      case Set.isAssignableFrom(value.class): true//value.class.componentType?.simpleName == tList.get(1)
    }
  }
  
  private def Object tryConvert(Object value, String toType) {
    val type = value.class
    if (type.array) {
      val Collection<?> array = switch type.componentType {
        case int: value as int[]
        case String: value as String[]
      }
      
      return new HashSet(array)
    }
    
    return value
  }
}