package base

import java.io.File
import java.lang.reflect.ReflectPermission
import java.security.AllPermission
import java.security.CodeSource
import java.security.Permission
import java.security.Permissions
import java.security.Policy
import java.security.SecurityPermission
import java.util.PropertyPermission
import java.net.SocketPermission
import java.io.FilePermission
import java.net.NetPermission
import java.lang.management.ManagementPermission

class SecurityPolicy extends Policy {  
  static val all = new Permissions => [
    add = new AllPermission
  ]
  
  static val global = #[
    new PropertyPermission("*", "read"),
    new SocketPermission("localhost:0", "listen")
  ]
  
  // adding policies: use the same order as in the gradle file
  
  static val org_eclipse_xtend = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  static val ch_qos_logback = new Permissions => [
    addGlobal
    add = new FilePermission("logback.xml","read")
    
    add = new RuntimePermission("getClassLoader")
    //add = new AllPermission //*
  ]
  
  static val info_picocli = new Permissions => [
    addGlobal
    
    add = new RuntimePermission("getenv.TERM")
    add = new RuntimePermission("getenv.OSTYPE")
    add = new RuntimePermission("writeFileDescriptor")
    add = new RuntimePermission("readFileDescriptor")
    add = new RuntimePermission("accessDeclaredMembers")
    
    add = new ReflectPermission("suppressAccessChecks")
  ]
  
  static val org_bouncycastle = new Permissions => [
    addGlobal
    add = new RuntimePermission("accessClassInPackage.sun.security.provider")
    
    add = new SecurityPermission("putProviderProperty.BC")
  ]
  
  static val dcm4che = new Permissions => [
    addGlobal
    add = new SocketPermission("*:0", "listen,resolve")
  ]
  
  static val org_neo4j = new Permissions => [
    addGlobal
    /*add = new PropertyPermission("*", "read,write")
    
    add = new RuntimePermission("getClassLoader")
    add = new RuntimePermission("accessClassInPackage.sun.misc")
    add = new RuntimePermission("accessDeclaredMembers")
    add = new RuntimePermission("modifyThread")
    
    add = new ReflectPermission("suppressAccessChecks")
    
    add = new ManagementPermission("monitor")
    
    add = new SecurityPermission("insertProvider")
    add = new SecurityPermission("insertProvider.BC")
    
    add = new FilePermission("/sys/block","read")
    add = new FilePermission("/sys/block/-","read")
    
    add = new NetPermission("getNetworkInformation")
    
    add = new SocketPermission("127.0.0.1", "resolve")
    add = new SocketPermission("[0:0:0:0:0:0:0:1%lo]", "resolve")
    */
    
    add = new AllPermission
  ]
  
  // transitive
  static val org_slf4j = new Permissions => [
    addGlobal
    add = new FilePermission("logback.xml","read")
    //add = new FilePermission("/home/micael/git/cad-proxy/srv/build/libs/deps/ch.qos.logback/logback-classic-1.2.3.jar", "read")
    
    add = new AllPermission //*
  ]
  
  static val io_netty = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  static val org_apache_lucene = new Permissions => [
    addGlobal
    add = new AllPermission
  ]
  
  static val org_eclipse_xtext = new Permissions => [
    addGlobal
    add = new AllPermission
  ]
  
  static val org_apache_commons = new Permissions => [
    addGlobal
    add = new PropertyPermission("*", "read")
    //add = new AllPermission //*
  ]
  
  static val com_google_guava = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  static val org_jprocesses = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  static val net_sf_opencsv = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  static val org_ow2_asm = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  static val org_parboiled = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  static val com_profesorfalken = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  static val org_scala_lang = new Permissions => [
    addGlobal
    add = new AllPermission
  ]
  
  static val com_github_ben_manes_caffeine = new Permissions => [
    addGlobal
    add = new AllPermission
  ]
  
  static val com_googlecode_concurrentlinkedhashmap = new Permissions => [
    addGlobal
    //add = new AllPermission //*
  ]
  
  
  // <group> - <Permissions>
  val perms = #{
    "org.eclipse.xtend" -> org_eclipse_xtend,
    "ch.qos.logback" -> ch_qos_logback,
    "info.picocli" -> info_picocli,
    "org.bouncycastle" -> org_bouncycastle,
    "dcm4che" -> dcm4che,
    "org.neo4j" -> org_neo4j,
    
    // transitive
    "org.slf4j" -> org_slf4j,
    "io.netty" -> io_netty,
    "org.apache.lucene" -> org_apache_lucene,
    "org.eclipse.xtext" -> org_eclipse_xtext,
    "org.apache.commons" -> org_apache_commons,
    "com_google_guava" -> com_google_guava,
    "org.parboiled" -> org_parboiled,
    "org.jprocesses" -> org_jprocesses,
    "net.sf.opencsv" -> net_sf_opencsv,
    "org.ow2.asm" -> org_ow2_asm,
    "com.profesorfalken" -> com_profesorfalken,
    "org.scala-lang" -> org_scala_lang,
    "com.github.ben-manes.caffeine" -> com_github_ben_manes_caffeine,
    "com.googlecode.concurrentlinkedhashmap" -> com_googlecode_concurrentlinkedhashmap
  }
  
  public static val CURRENT = new SecurityPolicy
  
  override getPermissions(CodeSource codesource) {
    if (codesource.location.toString.startsWith("file:/usr/lib/jvm/"))
      return all
    
    val splits = codesource.location.toString.split(File.separator)
    val group = splits.get(splits.size - 2)
    
    //println(group + ": " + perms.get(group))
    
    return perms.get(group)
  }
  
  def SecurityPolicy addPermission(String group, Permission perm) {
    perms.get(group)?.add(perm)
    return this
  }
  
  private static def addGlobal(Permissions perms) {
    global.forEach[perms.add(it)]
  }
}