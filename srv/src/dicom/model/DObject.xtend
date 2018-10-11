package dicom.model

import org.dcm4che2.data.DicomObject
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
abstract class DObject {
  public val DicomObject obj
  
  def <T> T get(DField field) {
    val value = switch (field.type) {
      case String: obj.getString(field.tag)
      case Integer: obj.getInt(field.tag)
      default: throw new RuntimeException("Unsupported field type: " + field.type)
    }
    
    return value as T
  }
  
  override toString() {
    obj.toString
  }
}