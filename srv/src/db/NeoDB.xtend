package db

import java.io.File
import java.util.Map
import org.neo4j.graphdb.GraphDatabaseService
import org.neo4j.graphdb.Label
import org.neo4j.graphdb.Node
import org.neo4j.graphdb.RelationshipType
import org.neo4j.graphdb.factory.GraphDatabaseFactory
import org.neo4j.graphdb.factory.GraphDatabaseSettings
import org.slf4j.LoggerFactory

class NeoDB {
  static val logger = LoggerFactory.getLogger(NeoDB)
  
  public val String path
  public val GraphDatabaseService db
  
  new(String path) { this(path, false) }
  
  new(String path, boolean readOnly) {
    this.path = path
    
    val dbFile = new File(path)
    val builder = new GraphDatabaseFactory().newEmbeddedDatabaseBuilder(dbFile)
    builder.setConfig(GraphDatabaseSettings.read_only, readOnly.toString)
    
    db = builder.newGraphDatabase
    Runtime.runtime.addShutdownHook(new Thread[shutdown])
    logger.info('''Opening Neo4j database «path» in «IF readOnly»read-only«ELSE»read-write«ENDIF» mode''')
  }
  
  def void shutdown() {
    logger.info('''Shuting down database «path»''')
    db.shutdown
  }
  
  def node(String label, Map<String, String> props) {
    db.createNode(Label.label(label)) => [
      for (kv: props.entrySet)
        setProperty(kv.key, kv.value)
    ]
  }
  
  def edge(Node left, Node right, String name) {
    left.createRelationshipTo(right, RelationshipType.withName(name))
  } 
  
  def void tx((NeoDB)=>void txHandler) {
    val tx = db.beginTx
    try {
      txHandler.apply(this)
      tx.success
    } catch(Throwable err) {
      logger.error('''Transaction error: «err.message»''')
    } finally {
      tx.close
    }
  }
  
  def cypher(String cypher) {
    logger.debug('''Cypher: «cypher»''')
    db.execute(cypher)
  }
  
  def cypher(String cypher, Map<String, Object> params) {
    logger.debug('''Cypher: «cypher»''')
    db.execute(cypher, params)
  }
}