package dicom.model

import org.dcm4che2.data.DicomObject
import org.dcm4che2.data.Tag
import org.dcm4che2.data.VR
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.List
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter

@FinalFieldsConstructor
abstract class DObject {
  public val DicomObject obj
  
  def <T> T get(DField<T> field) {
    val value = switch (field.type) {
      case String: obj.getString(field.tag)
      case Integer: obj.getInt(field.tag)
      case LocalDate: obj.getString(field.tag).date
      case LocalTime: obj.getString(field.tag).time
      default: throw new RuntimeException("Unsupported field type: " + field.type)
    }
    
    return value as T
  }
  
  override toString() {
    obj.toString
  }
  
  private def date(String dateTxt) {
    var date = dateTxt?:'00000101'
    if (date.length > 8)
      date = date.substring(0, 8)
      
    LocalDate.parse(date, DateTimeFormatter.BASIC_ISO_DATE)
  }
  
  private def time(String timeTxt) {
    var time = timeTxt?:'000000'
    if (time.length > 10)
      time = time.substring(0, 10)
    
    return LocalTime.parse(time, DateTimeFormatter.ofPattern('HHmmss[.SSS]'))
  }
}

class DPatient {
  public static val RL = DQuery.RetrieveLevel.PATIENT
  
  public static val ID = new DField(String, "P-ID", Tag.PatientID, VR.LO)
  public static val NAME = new DField(String, "P-NAME", Tag.PatientName, VR.PN)
  public static val SEX = new DField(String, "P-SEX", Tag.PatientSex, VR.CS)
  public static val BIRTHDATE = new DField(LocalDate, "P-BIRTHDATE", Tag.PatientBirthDate, VR.DA)
  public static val STUDY_COUNT = new DField(Integer, "P-STUDY-COUNT", Tag.NumberOfPatientRelatedStudies, VR.IS)
  
  public static val DEFAULT = #[ID, NAME, SEX, BIRTHDATE] as List<? extends DField<?>>
}

class DStudy {
  public static val RL = DQuery.RetrieveLevel.STUDY
  
  public static val UID = new DField(String, "S-UID", Tag.StudyInstanceUID, VR.UI)
  public static val DATE = new DField(LocalDate, "S-DATE", Tag.StudyDate, VR.DA)
  public static val TIME = new DField(LocalTime, "S-TIME", Tag.StudyTime, VR.TM)
  public static val DESCRIPTION = new DField(String, "S-DESCRIPTION", Tag.StudyDescription, VR.LO)
  public static val SERIES_COUNT = new DField(Integer, "S-SERIE-COUNT", Tag.NumberOfStudyRelatedSeries, VR.IS)
  
  public static val DEFAULT = #[DPatient.ID, UID, DATE] as List<? extends DField<?>>
}

class DSeries {
  public static val RL = DQuery.RetrieveLevel.SERIES
  
  public static val UID = new DField(String, "E-UID", Tag.SeriesInstanceUID, VR.UI)
  public static val NUMBER = new DField(Integer, "E-NUMBER", Tag.SeriesNumber, VR.IS)
  public static val DATE = new DField(LocalDate, "S-DATE", Tag.SeriesDate, VR.DA)
  public static val TIME = new DField(LocalTime, "S-TIME", Tag.SeriesTime, VR.TM)
  public static val MODALITY = new DField(String, "E-MODALITY", Tag.Modality, VR.CS)
  
  public static val LATERALITY = new DField(String, "E-LATERALITY", Tag.Laterality, VR.CS)
  public static val MANUFACTURER = new DField(String, "E-MANUFACTURER", Tag.Manufacturer, VR.LO)
  public static val MODEL = new DField(String, "E-MODEL", Tag.ManufacturerModelName, VR.LO)
  
  public static val DESCRIPTION = new DField(String, "E-DESCRIPTION", Tag.SeriesDescription, VR.LO)
  public static val IMAGE_COUNT = new DField(Integer, "E-IMAGE-COUNT", Tag.NumberOfSeriesRelatedInstances, VR.IS)
  
  public static val DEFAULT = #[DPatient.ID, DStudy.UID, UID, NUMBER, DATE, TIME, MODALITY, LATERALITY] as List<? extends DField<?>>
}

class DImage {
  public static val RL = DQuery.RetrieveLevel.IMAGE
  
  public static val UID = new DField(String, "I-UID", Tag.SOPInstanceUID, VR.UI)
  public static val NUMBER = new DField(Integer, "I-NUMBER", Tag.InstanceNumber, VR.IS)
  
  public static val CONTENT_DATE = new DField(LocalDate, "I-CONTENT-DATE", Tag.ContentDate, VR.DA)
  public static val CONTENT_TIME = new DField(LocalTime, "I-CONTENT-TIME", Tag.ContentTime, VR.TM)
  
  public static val ACQ_DATE = new DField(LocalDate, "I-ACQ-DATE", Tag.AcquisitionDate, VR.DA)
  public static val ACQ_TIME = new DField(LocalTime, "I-ACQ-TIME", Tag.AcquisitionTime, VR.TM)
  
  public static val DEFAULT = #[DPatient.ID, DStudy.UID, DSeries.UID, UID, NUMBER] as List<? extends DField<?>>
}