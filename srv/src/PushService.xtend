import db.Store
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import java.util.Set
import java.util.HashSet
import java.util.List

@FinalFieldsConstructor
class PushService {
  static val logger = LoggerFactory.getLogger(PushService)
  
  val Store store
  
  def Set<Long> push() {
    val requests = new HashSet<Long>
    store.TARGET.pendingData.forEach[
      val targetID = get("id") as Long
      val seriesIDs = get("series") as List<Long>
      requests.add(store.PUSH.create(targetID, seriesIDs.toSet))
    ]
    
    return requests
  }
}