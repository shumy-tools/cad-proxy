package dicom.model

import org.dcm4che2.data.DicomObject
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
abstract class DObject {
  protected val DicomObject obj
  
  def void copyTo(DicomObject to) {
    obj.copyTo(to)
  }
  
  def <T> T get(DField field) {
    val value = switch (field.type) {
      case String: obj.getString(field.tag)
      case Integer: obj.getInt(field.tag)
      default: throw new RuntimeException("Unsupported field type: " + field.type)
    }
    
    return value as T
  }
  
  def DObject set(DField field, String value) {
    switch (field.type) {
      case String: obj.putString(field.tag, field.vr, value as String)
      case Integer: obj.putString(field.tag, field.vr, value.toString)
      default: throw new RuntimeException("Unsupported field type: " + field.type)
    }
    
    return this
  }
  
  override toString() {
    obj.toString
  }
}