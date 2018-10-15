package db

class Store {
  val NeoDB db
  
  public val Target TARGET
  
  new() {
    db = new NeoDB("data/db") => [
      cypher('''CREATE CONSTRAINT ON (n:«Target.NODE») ASSERT n.«Target.UDI» IS UNIQUE''')
    ]
    
    TARGET = new Target(db)
  }
}