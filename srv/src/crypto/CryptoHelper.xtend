package crypto

import java.security.PrivateKey
import java.security.PublicKey
import javax.crypto.Cipher
import javax.crypto.KeyAgreement
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

class CryptoHelper {
  val String spec
  val SecretKeySpec sKeySpec
  
  new(byte[] key) { this("AES/GCM/PKCS7PADDING", key) }
  new(String spec, byte[] key) {
    this.spec = spec
    this.sKeySpec = new SecretKeySpec(key, "AES")
  }
  
  def byte[] encrypt(byte[] initVector, byte[] plaintext) {
    val iv = new IvParameterSpec(initVector)
    
    val cipher = Cipher.getInstance(spec)
    cipher.init(Cipher.ENCRYPT_MODE, sKeySpec, iv)
    
    return cipher.doFinal(plaintext)
  }
  
  def byte[] decrypt(byte[] initVector, byte[] encrypted) {
    val iv = new IvParameterSpec(initVector)
    
    val cipher = Cipher.getInstance(spec)
    cipher.init(Cipher.DECRYPT_MODE, sKeySpec, iv)
    
    return cipher.doFinal(encrypted)
  }
  
  static def byte[] keyAgreement(PrivateKey prvKey, PublicKey pubKey) {
    val ka = KeyAgreement.getInstance("ECDH", "BC")
    ka.init(prvKey)
    ka.doPhase(pubKey, true)
    
    return ka.generateSecret
  }
}