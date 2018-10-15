import dicom.DLocal
import dicom.model.DImage
import dicom.model.DQuery
import dicom.model.DSeries
import dicom.model.DStudy
import java.util.HashSet
import org.slf4j.LoggerFactory
import db.Store

class Server {
  static val log = LoggerFactory.getLogger(Server)
  
  def static void main(String[] args) {
    val store = new Store()
    
    //val target = new Target(db)
    //val id = target.create(UUID.randomUUID.toString, "t1", #{"MR", "TC"})
    //println("NEW: " + id)
    
    store.TARGET.modalities.forEach[
      println(it)
    ]
    
  }
  
  def void test() {
    //val storePath = "./dcm-store"
    val port = 1104
    
    val dSrv = new DLocal("MICAEL", "192.168.21.250", port) [
      println('''STORE: «get(DImage.UID)» - «get(DSeries.MODALITY)»''')
      //println("STORE: ")
      //println(it)
    ]
    
    val con = dSrv.connect("DICOOGLE-STORAGE", "192.168.21.250", 1045)
    
    val query = new DQuery(DImage.RL) => [
      //set(DStudy.DATE, "20170207")
      set(DStudy.UID, "1.2.826.0.1.3680043.2.1174.4.1.5.2376752")
    ]
    
    val rep = new HashSet<String>
    val result = con.find(query, DStudy.UID, DSeries.UID, DImage.UID, DSeries.MODALITY, DSeries.NUMBER, DSeries.DATE, DSeries.TIME)
    println("RESULTS: " + result.length)
    result.forEach[
      //if (rep.contains(get(DSeries.UID)))
      //  println(it)
      //rep.add(get(DSeries.UID))
      println(it)
    ]
    
    con.pull("1.2.826.0.1.3680043.2.1174.4.1.5.2376752")[
      println('''STATUS: «status»''')
    ]
      
    
    /*val t1 = new Thread[
      con.pull("1.2.826.0.1.3680043.2.1174.4.1.5.2376752")[
        println('''STATUS: «status»''')
      ]
    ]
    
    val t2 = new Thread[
      con.pull("1.2.826.0.1.3680043.2.1174.4.1.5.2584739")
    ]
    
    t1.run
    t2.run
    */
  }
}