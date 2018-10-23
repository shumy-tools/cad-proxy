package crypto

import com.google.common.io.BaseEncoding

class Base64Helper {
  val static b64Codec = BaseEncoding.base64
  
  def static String encode(byte[] bytes) {
    b64Codec.encode(bytes)
  }
  
  def static byte[] decode(String data) {
    b64Codec.decode(data)
  }
}