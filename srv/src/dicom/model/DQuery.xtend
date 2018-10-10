package dicom.model

import java.util.List
import org.dcm4che2.data.DicomObject
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
abstract class DQuery extends DObject {
  def void copyTo(DicomObject to) {
    obj.copyTo(to)
  }
  
  def DQuery set(DField field, String value) {
    switch (field.type) {
      case String: obj.putString(field.tag, field.vr, value as String)
      case Integer: obj.putString(field.tag, field.vr, value.toString)
      default: throw new RuntimeException("Unsupported field type: " + field.type)
    }
    
    return this
  }
  
  abstract def List<DField> getAllFields()
}