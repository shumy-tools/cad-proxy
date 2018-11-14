package dicom.model

import java.util.List
import org.dcm4che2.data.BasicDicomObject
import org.dcm4che2.data.DicomObject
import org.dcm4che2.data.Tag
import java.lang.reflect.Modifier
import org.dcm4che2.data.VR
import java.util.Map

class DQuery extends DObject {
  static public val TAGS = newImmutableMap(
    Tag.declaredFields
      .filter[ Modifier.isStatic(modifiers) && Modifier.isFinal(modifiers) && Modifier.isPublic(modifiers) ]
      .map[ name -> getInt(null) ]
  )
  
  static enum RetrieveLevel { PATIENT, STUDY, SERIES, IMAGE }
  
  public val RetrieveLevel rl

  new() { this(RetrieveLevel.PATIENT) }
  new(RetrieveLevel rl) {
    super(new BasicDicomObject())
    this.rl = rl
  }
  
  def void copyTo(DicomObject to) {
    obj.copyTo(to)
  }
  
  def DQuery set(DField<?> field, String value) {
    obj.putString(field.tag, field.vr, value)
    return this
  }
  
  def DQuery set(String field, String value) {
    val tag = TAGS.get(field)
    obj.putString(tag, VR.UT, value)
    return this
  }
  
  def DQuery set(Map<String, String> tagValueMap) {
    tagValueMap.forEach[key, value | set(key, value)]
    return this
  }
  
  def List<? extends DField<?>> defaults() {
    switch rl {
      case RetrieveLevel.PATIENT: DPatient.DEFAULT
      case RetrieveLevel.STUDY: DStudy.DEFAULT
      case RetrieveLevel.SERIES: DSeries.DEFAULT
      case RetrieveLevel.IMAGE: DImage.DEFAULT
    }
  }
}
