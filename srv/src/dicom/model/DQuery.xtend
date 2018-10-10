package dicom.model

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
abstract class DQuery extends DObject {
  abstract def List<DField> getAllFields()
}