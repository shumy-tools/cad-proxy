package service

import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream
import java.nio.file.Files
import java.nio.file.Paths
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class TransmitStream extends ByteArrayOutputStream {
  val OutputStream os
  
  override close() throws IOException {
    //TODO: replace the test code with data transmission: (Encrypt-then-MAC, Channel-Transmit)
    
    os.write(buf, 0, count)
    os.close
    println("CLOSE-STREAM")
  }
}

class TransmitService {
  def OutputStream push(String targetUDI, Long pushID) {
    val path = "./data/target/" + targetUDI
    
    val dir = Paths.get(path)
    Files.createDirectories(dir)
    
    val file = dir.resolve('''push«pushID».zip''').toFile
    file.delete
    file.createNewFile
    
    val fos = new FileOutputStream(file)
    return new TransmitStream(fos)
  }
}