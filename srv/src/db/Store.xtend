package db

import base.SecurityPolicy
import db.mng.Key
import db.mng.Log
import java.io.FilePermission
import java.util.Map

class Store {
  val NeoDB db
  
  public val Target   TARGET
  public val Source   SOURCE
  public val Subject  SUBJECT
  public val Patient  PATIENT
  public val Study    STUDY
  public val Series   SERIES
  public val Item     ITEM
  public val Pull     PULL
  public val Push     PUSH
  
  public val Log      LOG
  public val Key      KEY
  
  static def Store setup() {
    val dbPath = System.getProperty("dbPath")
    
    SecurityPolicy.CURRENT
      .addPermission("org.neo4j", new FilePermission(dbPath + "/-", "read,write,delete"))
    
    return new Store(new NeoDB(dbPath))
  }
  
  def cypher(String cypher) {
    db.cypher(cypher)
  }
  
  def cypher(String cypher, Map<String, ?> params) {
    db.cypher(cypher, params)
  }
  
  private new(NeoDB db) {
    this.db = db
    db => [
      cypher('''CREATE CONSTRAINT ON (n:«Target.NODE») ASSERT n.«Target.UDI» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Target.NODE») ASSERT n.«Target.NAME» IS UNIQUE''')
      
      cypher('''CREATE CONSTRAINT ON (n:«Source.NODE») ASSERT n.«Source.AET» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Subject.NODE») ASSERT n.«Subject.UDI» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Study.NODE») ASSERT n.«Study.UID» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Series.NODE») ASSERT n.«Series.UID» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Item.NODE») ASSERT n.«Item.UID» IS UNIQUE''')
      
      cypher('''CREATE INDEX ON :«Patient.NODE»(«Patient.PID»)''')
      cypher('''CREATE INDEX ON :«Series.NODE»(«Series.MODALITY»)''')
      
      cypher('''CREATE INDEX ON :«Log.NODE»(«Log.TYPE», «Log.CLASS», «Log.STAMP»)''')
      cypher('''CREATE INDEX ON :«Key.NODE»(«Key.GROUP», «Key.KEY»)''')
    ]
    
    TARGET = new Target(db)
    SOURCE = new Source(db)
    SUBJECT = new Subject(db)
    PATIENT = new Patient(db)
    STUDY = new Study(db)
    SERIES = new Series(db)
    ITEM = new Item(db)
    PULL = new Pull(db)
    PUSH = new Push(db)
    
    LOG = new Log(db)
    KEY = new Key(db)
    
    KEY.setupDefault
  }
}