package db.mng

import db.NeoDB
import java.io.PrintWriter
import java.io.StringWriter
import java.time.LocalDateTime
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory

@FinalFieldsConstructor
class Log {
  static val logger = LoggerFactory.getLogger("LOGGER")
  enum Type { ERROR, EXCEPTION }
  
  val NeoDB db
  public static val NODE = Log.simpleName
  
  public static val TYPE                = "type"
  public static val CLASS               = "class"
  public static val STAMP               = "stamp"
  
  public static val MSG                 = "msg"
  public static val STACK               = "stack"
  
  def void exception(Class<?> clazz, Throwable ex) {
    val stack = new StringWriter()
    ex.printStackTrace(new PrintWriter(stack))
    
    val map = #{ CLASS -> clazz.name, STAMP -> LocalDateTime.now, MSG -> ex.message, STACK -> stack.toString }
    db.cypher('''
      CREATE (n:Log {
        «TYPE»: "«Type.EXCEPTION»",
        «CLASS»: $«CLASS»,
        «STAMP»: $«STAMP»,
        «MSG»: $«MSG»,
        «STACK»: $«STACK»
      })
    ''', map)
  }
  
  def void error(Class<?> clazz, String msg) {
    logger.error(msg)
    val map = #{ CLASS -> clazz.name, STAMP -> LocalDateTime.now, MSG -> msg }
    db.cypher('''
      CREATE (n:Log {
        «TYPE»: ""«Type.ERROR»",
        «CLASS»: $«CLASS»,
        «STAMP»: $«STAMP»,
        «MSG»: $«MSG»
      })
    ''', map)
  }
  
  def all() {
    db.cypher('''MATCH (n:«NODE») RETURN
      n.«TYPE» as «TYPE»,
      n.«CLASS» as «CLASS»,
      n.«STAMP» as «STAMP»,
      n.«MSG» as «MSG»,
      n.«STACK» as «STACK»
    ''')
  }
}