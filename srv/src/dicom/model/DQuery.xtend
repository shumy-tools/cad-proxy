package dicom.model

import org.dcm4che2.data.BasicDicomObject
import org.dcm4che2.data.DicomObject
import org.dcm4che2.data.Tag
import org.dcm4che2.data.VR
import java.util.List

class DQuery extends DObject {
  enum RetrieveLevel { PATIENT, STUDY, SERIES }
  
  val RetrieveLevel rl
  
  new(RetrieveLevel rl) {
    super(new BasicDicomObject())
    this.rl = rl
    obj.putString(Tag.QueryRetrieveLevel, VR.CS, rl.name)
  }
  
  def void copyTo(DicomObject to) {
    obj.copyTo(to)
  }
  
  def DQuery set(DField field, String value) {
    obj.putString(field.tag, field.vr, value.toString)
    return this
  }
  
  def List<DField> defaults() {
    switch rl {
      case RetrieveLevel.PATIENT: DPatient.DEFAULT
      case RetrieveLevel.STUDY: DStudy.DEFAULT
      case RetrieveLevel.SERIES: DSerie.DEFAULT
    }
  }
}

class DPatient {
  public static val RL = DQuery.RetrieveLevel.PATIENT
  
  public static val ID = new DField(String, "P-ID", Tag.PatientID, VR.LO)
  public static val NAME = new DField(String, "P-NAME", Tag.PatientName, VR.PN)
  public static val GENDER = new DField(String, "P-GENDER", Tag.PatientSex, VR.CS)
  public static val BIRTHDATE = new DField(String, "P-BIRTHDATE", Tag.PatientBirthDate, VR.DA)
  public static val STUDY_COUNT = new DField(Integer, "P-STUDY-COUNT", Tag.NumberOfPatientRelatedStudies, VR.IS)
  
  public static val DEFAULT = #[ID, NAME, GENDER, BIRTHDATE, STUDY_COUNT]
}

class DStudy {
  public static val RL = DQuery.RetrieveLevel.STUDY
  
  public static val UID = new DField(String, "S-UID", Tag.StudyInstanceUID, VR.UI)
  public static val DESCRIPTION = new DField(String, "S-DESCRIPTION", Tag.StudyDescription, VR.LO)
  public static val DATE = new DField(String, "S-DATE", Tag.StudyDate, VR.DA)
  public static val TIME = new DField(String, "S-TIME", Tag.StudyTime, VR.TM)
  public static val SERIE_COUNT = new DField(Integer, "S-SERIE-COUNT", Tag.NumberOfStudyRelatedSeries, VR.IS)
  
  public static val DEFAULT = #[DPatient.ID, UID, DESCRIPTION, DATE, TIME, SERIE_COUNT]
}

class DSerie {
  public static val RL = DQuery.RetrieveLevel.SERIES
  
  public static val UID = new DField(String, "E-UID", Tag.SeriesInstanceUID, VR.UI)
  public static val NUMBER = new DField(Integer, "E-NUMBER", Tag.SeriesNumber, VR.IS)
  public static val DESCRIPTION = new DField(String, "E-DESCRIPTION", Tag.SeriesDescription, VR.LO)
  public static val MODALITY = new DField(String, "E-MODALITY", Tag.Modality, VR.CS)
  public static val IMAGE_COUNT = new DField(Integer, "E-IMAGE-COUNT", Tag.NumberOfSeriesRelatedInstances, VR.IS)
  
  public static val DEFAULT = #[DPatient.ID, DStudy.UID, UID, NUMBER, DESCRIPTION, IMAGE_COUNT]
}