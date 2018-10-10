package dicom.model

import org.dcm4che2.data.Tag
import org.dcm4che2.data.VR
import org.dcm4che2.data.BasicDicomObject

class DPatient extends DQuery {
  public static val ID = new DField(String, "P-ID", Tag.PatientID, VR.LO)
  public static val NAME = new DField(String, "P-NAME", Tag.PatientName, VR.PN)
  public static val GENDER = new DField(String, "P-GENDER", Tag.PatientSex, VR.CS)
  public static val BIRTHDATE = new DField(String, "P-BIRTHDATE", Tag.PatientBirthDate, VR.DA)
  public static val STUDY_COUNT = new DField(Integer, "P-STUDY-COUNT", Tag.NumberOfPatientRelatedStudies, VR.IS)
  
  public static val ALL = #[ID, NAME, GENDER, BIRTHDATE, STUDY_COUNT]
  public static val QUERY_RETRIEVE_LEVEL = "PATIENT"
  
  new() {
    super(new BasicDicomObject())
    obj.putString(Tag.QueryRetrieveLevel, VR.CS, QUERY_RETRIEVE_LEVEL)
  }
  
  override getAllFields() { ALL }
}