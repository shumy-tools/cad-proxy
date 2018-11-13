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
    
    create("dicom", "modalities", #{
      "CT-Computed Tomography",
      "MR-Magnetic Resonance",
      "XA-X-Ray Angiography",
      "MG-Mammography",
      "XC-External-camera Photography"
    })
  }
  
  def create(String group, String key, Object value) {
    val type = valueType(value)
    if(type === null)
      throw new RuntimeException('''Unsuported type=«value.class.simpleName»''')
    
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
  
  def set(String group, String key, Object value) {
    val type = valueType(value)
    if(type === null)
      throw new RuntimeException('''Unsuported type=«value.class.simpleName»''')
    
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
    
    return tryConvert(keyNode.get(VALUE)) as T
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
        GROUP -> get(GROUP),
        KEY -> get(KEY),
        VALUE -> tryConvert(get(VALUE))
      }
    ].toList
  }
  
  private def valueType(Object value) {
    val type = value.class
    switch type {
      case String,
      case Integer: "nat"
      
      case Set.isAssignableFrom(type): "set"
      
      default: null
    }
  }
  
  private def Object tryConvert(Object value) {
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