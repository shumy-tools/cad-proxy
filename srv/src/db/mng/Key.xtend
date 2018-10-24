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
  public static val NODE = Log.simpleName
  
  public static val ACTIVE              = "active"
  public static val GROUP               = "group"
  public static val KEY                 = "key"
  public static val VALUE               = "value"
  
  def setupDefault() {
    create("path", "cache", "/cache")
    
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
  
  def <T> get(Class<T> type, String group, String key) {
    val map = #{ GROUP -> group, KEY -> key }
    val res = db.cypher('''
      MATCH (n:«NODE» {«GROUP»: $«GROUP», «KEY»: $«KEY»})
        WHERE n.«ACTIVE» = true
      RETURN
        n.«VALUE» as «VALUE»
    ''', map)
    
    if (res.empty)
      throw new RuntimeException('''Unable to find (group, key)=(«group», «key»)''')
    
    val value = tryConvert(res.head.get(VALUE), type)
    if (!type.isAssignableFrom(value.class))
      throw new RuntimeException('''Incorrect type for (type, group, key)=(«value.class.simpleName», «group», «key»). Requested type «type.simpleName»''')
    
    return value as T
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