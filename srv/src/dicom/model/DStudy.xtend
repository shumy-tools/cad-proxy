package dicom.model

import org.dcm4che2.data.Tag
import org.dcm4che2.data.VR
import org.dcm4che2.data.BasicDicomObject

class DStudy extends DQuery {
  public static val UID = new DField(String, "S-UID", Tag.StudyInstanceUID, VR.UI)
  public static val DESCRIPTION = new DField(String, "S-DESCRIPTION", Tag.StudyDescription, VR.LO)
  public static val DATE = new DField(String, "S-DATE", Tag.StudyDate, VR.DA)
  public static val TIME = new DField(String, "S-TIME", Tag.StudyTime, VR.TM)
  public static val SERIE_COUNT = new DField(Integer, "S-SERIE-COUNT", Tag.NumberOfStudyRelatedSeries, VR.IS)
  
  public static val ALL = #[DPatient.ID, UID, DESCRIPTION, DATE, TIME, SERIE_COUNT]
  public static val QUERY_RETRIEVE_LEVEL = "STUDY"
  
  new() {
    super(new BasicDicomObject())
    obj.putString(Tag.QueryRetrieveLevel, VR.CS, QUERY_RETRIEVE_LEVEL)
  }
  
  override getAllFields() { ALL }
}