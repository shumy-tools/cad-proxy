import dicom.DLocal
import dicom.model.DStudy
import org.slf4j.LoggerFactory

class Server {
  static val log = LoggerFactory.getLogger(Server)
  
  def static void main(String[] args) {
    val port = 1104
    
    val dSrv = new DLocal("MICAEL", port)
    val con = dSrv.connect("DICOOGLE-STORAGE", "192.168.21.250", 1045)
    
    val query = new DStudy()
    val result = con.find(query, DStudy.ALL)
    
    println("RESULTS: " + result.length)
    result.forEach[
      println(it)
    ]
  }
}