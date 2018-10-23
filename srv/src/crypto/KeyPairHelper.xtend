package crypto

import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.PublicKey
import java.security.SecureRandom
import org.bouncycastle.jce.ECNamedCurveTable
import org.bouncycastle.jce.interfaces.ECPrivateKey
import org.bouncycastle.jce.interfaces.ECPublicKey
import org.bouncycastle.jce.spec.ECNamedCurveParameterSpec
import org.bouncycastle.jce.spec.ECPrivateKeySpec
import org.bouncycastle.jce.spec.ECPublicKeySpec

class KeyPairHelper {
  val ECNamedCurveParameterSpec ecSpec
  val KeyPairGenerator kpg
  
  //new() { this("secp384r1") }
  
  new() { this("curve25519") }
  new(String curve) {
    ecSpec = ECNamedCurveTable.getParameterSpec(curve)
    
    kpg = KeyPairGenerator.getInstance("EC", "BC")
    kpg.initialize(ecSpec, new SecureRandom)
  }
  
  def KeyPair genKeyPair() { kpg.generateKeyPair }
  
  def PublicKey bytesToPublicKey(byte[] data) {
    val pubKey = new ECPublicKeySpec(ecSpec.curve.decodePoint(data), ecSpec)
    val kf = KeyFactory.getInstance("ECDH", "BC")
    
    return kf.generatePublic(pubKey)
  }
  
  def PrivateKey bytesToPrivateKey(byte[] data) {
    val prvkey = new ECPrivateKeySpec(new BigInteger(data), ecSpec)
    val kf = KeyFactory.getInstance("ECDH", "BC")
    
    return kf.generatePrivate(prvkey)
  }
  
  def static byte[] keyToBytes(PublicKey key) {
    val eckey = key as ECPublicKey
    return eckey.q.getEncoded(true)
  }
  
  def static byte[] keyToBytes(PrivateKey key) {
    val eckey = key as ECPrivateKey 
    return eckey.d.toByteArray
  }
}