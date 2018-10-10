package dicom.model

import org.dcm4che2.data.Tag
import org.dcm4che2.data.VR
import org.dcm4che2.data.BasicDicomObject

class DSerie extends DQuery {
  public static val UID = new DField(String, "E-UID", Tag.SeriesInstanceUID, VR.UI)
  public static val NUMBER = new DField(Integer, "E-NUMBER", Tag.SeriesNumber, VR.IS)
  public static val DESCRIPTION = new DField(String, "E-DESCRIPTION", Tag.SeriesDescription, VR.LO)
  public static val IMAGE_COUNT = new DField(Integer, "E-IMAGE-COUNT", Tag.NumberOfSeriesRelatedInstances, VR.IS)
  
  public static val ALL = #[DPatient.ID, DStudy.UID, UID, NUMBER, DESCRIPTION, IMAGE_COUNT]
  public static val QUERY_RETRIEVE_LEVEL = "SERIES"
  
  new() {
    super(new BasicDicomObject())
    obj.putString(Tag.QueryRetrieveLevel, VR.CS, QUERY_RETRIEVE_LEVEL)
  }
  
  override getAllFields() { ALL }
}