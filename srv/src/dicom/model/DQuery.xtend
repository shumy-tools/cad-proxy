package dicom.model

import java.util.List
import org.dcm4che2.data.BasicDicomObject
import org.dcm4che2.data.DicomObject

class DQuery extends DObject {
  enum RetrieveLevel { PATIENT, STUDY, SERIES, IMAGE }
  
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
    obj.putString(field.tag, field.vr, value.toString)
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
