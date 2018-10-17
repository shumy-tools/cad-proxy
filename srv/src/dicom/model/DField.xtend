package dicom.model

import org.dcm4che2.data.VR
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class DField<T> {
  public val Class<T> type
  public val String name
  public val int tag
  public val VR vr
}