package crypto

import java.security.PrivateKey
import java.security.Signature
import java.security.PublicKey
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class SignatureHelper {
  public val String algorithm
  
  new() { this("SHA3-256withECDSA") }
  
  def sign(PrivateKey prvKey, byte[] plaintext) {
    val dsa = Signature.getInstance(algorithm, "BC")
    dsa.initSign(prvKey)
    dsa.update(plaintext)
    
    return dsa.sign
  }
  
  def verifySignature(PublicKey pubKey, byte[] plaintext, byte[] signature) {  
    val dsaVerify = Signature.getInstance(algorithm, "BC")
    dsaVerify.initVerify(pubKey)
    dsaVerify.update(plaintext)
    
    return dsaVerify.verify(signature)
  }
}