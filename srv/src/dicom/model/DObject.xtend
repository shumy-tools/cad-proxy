package dicom.model

import org.dcm4che2.data.DicomObject
import org.dcm4che2.data.Tag
import org.dcm4che2.data.VR
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

class DPatient {
  public static val RL = DQuery.RetrieveLevel.PATIENT
  
  public static val ID = new DField(String, "P-ID", Tag.PatientID, VR.LO)
  public static val NAME = new DField(String, "P-NAME", Tag.PatientName, VR.PN)
  public static val GENDER = new DField(String, "P-GENDER", Tag.PatientSex, VR.CS)
  public static val BIRTHDATE = new DField(String, "P-BIRTHDATE", Tag.PatientBirthDate, VR.DA)
  public static val STUDY_COUNT = new DField(Integer, "P-STUDY-COUNT", Tag.NumberOfPatientRelatedStudies, VR.IS)
  
  public static val DEFAULT = #[ID, NAME, GENDER, BIRTHDATE]
}

class DStudy {
  public static val RL = DQuery.RetrieveLevel.STUDY
  
  public static val UID = new DField(String, "S-UID", Tag.StudyInstanceUID, VR.UI)
  public static val DATE = new DField(String, "S-DATE", Tag.StudyDate, VR.DA)
  public static val TIME = new DField(String, "S-TIME", Tag.StudyTime, VR.TM)
  public static val DESCRIPTION = new DField(String, "S-DESCRIPTION", Tag.StudyDescription, VR.LO)
  public static val SERIES_COUNT = new DField(Integer, "S-SERIE-COUNT", Tag.NumberOfStudyRelatedSeries, VR.IS)
  
  public static val DEFAULT = #[DPatient.ID, UID, DATE]
}

class DSeries {
  public static val RL = DQuery.RetrieveLevel.SERIES
  
  public static val UID = new DField(String, "E-UID", Tag.SeriesInstanceUID, VR.UI)
  public static val NUMBER = new DField(Integer, "E-NUMBER", Tag.SeriesNumber, VR.IS)
  public static val DATE = new DField(String, "S-DATE", Tag.SeriesDate, VR.DA)
  public static val TIME = new DField(String, "S-TIME", Tag.SeriesTime, VR.TM)
  public static val MODALITY = new DField(String, "E-MODALITY", Tag.Modality, VR.CS)
  public static val LATERALITY = new DField(String, "E-LATERALITY", Tag.Laterality, VR.CS)
  
  public static val DESCRIPTION = new DField(String, "E-DESCRIPTION", Tag.SeriesDescription, VR.LO)
  public static val IMAGE_COUNT = new DField(Integer, "E-IMAGE-COUNT", Tag.NumberOfSeriesRelatedInstances, VR.IS)
  
  public static val DEFAULT = #[DPatient.ID, DStudy.UID, UID, NUMBER, DATE, TIME, MODALITY, LATERALITY]
}

class DImage {
  public static val RL = DQuery.RetrieveLevel.IMAGE
  
  public static val UID = new DField(String, "I-UID", Tag.SOPInstanceUID, VR.UI)
  public static val NUMBER = new DField(Integer, "I-NUMBER", Tag.InstanceNumber, VR.IS)
  
  public static val CONTENT_DATE = new DField(String, "I-CONTENT-DATE", Tag.ContentDate, VR.DA)
  public static val CONTENT_TIME = new DField(String, "I-CONTENT-TIME", Tag.ContentTime, VR.TM)
  
  public static val ACQ_DATE = new DField(String, "I-ACQ-DATE", Tag.AcquisitionDate, VR.DA)
  public static val ACQ_TIME = new DField(String, "I-ACQ-TIME", Tag.AcquisitionTime, VR.TM)
  
  public static val DEFAULT = #[DPatient.ID, DStudy.UID, DSeries.UID, UID, NUMBER]
}