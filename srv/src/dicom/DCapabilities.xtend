package dicom

import org.dcm4che2.data.UID
import org.dcm4che2.net.ExtQueryTransferCapability
import org.dcm4che2.net.TransferCapability

class DCapabilities {
  public static val STORE_CUIDS = #[
    UID.VLPhotographicImageStorage,
    UID.MRImageStorage
  ]
  
  static val nativeLeTs = #[UID.ExplicitVRLittleEndian, UID.ImplicitVRLittleEndian]
  
  static val findCUIDS = #[
    UID.StudyRootQueryRetrieveInformationModelFIND,
    UID.PatientRootQueryRetrieveInformationModelFIND,
    UID.PatientStudyOnlyQueryRetrieveInformationModelFINDRetired
  ]
  
  static val moveCUIDS = #[
    UID.StudyRootQueryRetrieveInformationModelMOVE,
    UID.PatientRootQueryRetrieveInformationModelMOVE,
    UID.PatientStudyOnlyQueryRetrieveInformationModelMOVERetired
  ]
  
  static val findTCS = findCUIDS.map[ new ExtQueryTransferCapability(it, nativeLeTs, TransferCapability.SCU) ]
  static val moveTCS = moveCUIDS.map[ new ExtQueryTransferCapability(it, nativeLeTs, TransferCapability.SCU) ]
  static val storeTCS = STORE_CUIDS.map[ new ExtQueryTransferCapability(it, nativeLeTs, TransferCapability.SCP) ]
  
  public static val TCS = (findTCS + moveTCS + storeTCS).toList
}