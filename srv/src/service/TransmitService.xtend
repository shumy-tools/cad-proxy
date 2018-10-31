package service

import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream
import java.nio.file.Files
import java.nio.file.Paths
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

// TODO: the TransmitStream must be rewrite to handle transmission and big file sizes, i.e. the count var is only an int!
@FinalFieldsConstructor
class TransmitStream extends ByteArrayOutputStream {
  val OutputStream os
  
  override close() throws IOException {
    os.write(buf, 0, count)
    os.close
  }
}

class TransmitService {
  def OutputStream streamFor(String targetUDI, Long pushID) {
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