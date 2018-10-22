package service

import java.io.FileOutputStream
import java.io.OutputStream
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.nio.file.Paths
import java.nio.file.Files

@FinalFieldsConstructor
class DPush {
  enum Status { OK, COMPLETED, ERROR }
  
  public val Status status
  //public val Integer error
}

class TransmitService {
  def OutputStream push(String targetUDI, Long pushID) {
    val path = "./data/target/" + targetUDI
    
    val dir = Paths.get(path)
    Files.createDirectories(dir)
    
    val file = dir.resolve('''push«pushID».zip''').toFile
    file.delete
    file.createNewFile
    
    new FileOutputStream(file)
  }
  
  // (DPush) => void onPush
  def void transmit() {
    
  }
}