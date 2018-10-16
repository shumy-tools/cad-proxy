package db

import java.util.Map

class Store {
  val NeoDB db
  
  public val Target   TARGET
  public val Source   SOURCE
  public val Subject  SUBJECT
  public val Study    STUDY
  public val Series   SERIES
  public val Item     ITEM
  public val Pull     PULL
  public val Push     PUSH
  
  static def Store setup(boolean isProd) {
    val db = if (isProd) new NeoDB("data/db") else new NeoDB("test/db")
    return new Store(db)
  }
  
  def cypher(String cypher) {
    db.cypher(cypher)
  }
  
    def cypher(String cypher, Map<String, ?> params) {
    db.cypher(cypher, params)
  }
  
  private new(NeoDB db) {
    this.db =db
    db => [
      cypher('''CREATE CONSTRAINT ON (n:«Target.NODE») ASSERT n.«Target.UDI» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Source.NODE») ASSERT n.«Source.AET» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Subject.NODE») ASSERT n.«Subject.UDI» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Study.NODE») ASSERT n.«Study.UID» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Series.NODE») ASSERT n.«Series.UID» IS UNIQUE''')
      cypher('''CREATE CONSTRAINT ON (n:«Item.NODE») ASSERT n.«Item.UID» IS UNIQUE''')
    ]
    
    TARGET = new Target(db)
    SOURCE = new Source(db)
    SUBJECT = new Subject(db)
    STUDY = new Study(db)
    SERIES = new Series(db)
    ITEM = new Item(db)
    PULL = new Pull(db)
    PUSH = new Push(db)
  }
}