import base.SecurityPolicy
import base.Server
import db.Store
import db.mng.Key
import java.io.File
import java.security.Policy
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters

import static java.security.Policy.*

@Command(
  name = "cadp", footer = "Copyright(c) 2017",
  description = "CAD-Proxy CLI Helper"
)
class RCommand {
  @Parameters(arity = "0..1", paramLabel = "DATA-PATH", description = "Relative path of the data directory.")
  public String path
  
  @Option(names = #["-h", "--help"], help = true, description = "Display this help and exit.")
  public boolean help
  
  @Option(names = #["--stack"], help = true, description = "Display the stack-trace error if any.")
  public boolean stack
  
  @Option(names = #["-s", "--server"], help = true, description = "Run the server.")
  public boolean server
  
  @Option(names = #["-ns", "--no-schedule"], help = true, description = "Disable pull/push scheduled tasks.")
  public boolean noSchedule
  
  @Option(names = #["--key-list"], help = true, description = "List all configuration keys. Order by group.")
  public boolean keyList
  
  @Option(names = #["--eth"], help = true, description = "Ethernet interface to use for the local DICOM storage service.")
  public String ethName
}

class CadProxyCLI {
  def static void main(String[] args) {
    Policy.policy = SecurityPolicy.CURRENT
    
    val cmd =  try {
      CommandLine.populateCommand(new RCommand, args)
    } catch (Throwable ex) {
      CommandLine.usage(new RCommand, System.out)
      return
    }
    
    val basePath = (cmd.path?: "data")
    if (basePath.startsWith(File.separator))
      throw new RuntimeException("DATA-PATH is a relative path!")
    
    val dataPath = System.getProperty("user.dir") + "/" + basePath
    val dbPath = dataPath + "/db"
    
    System.setProperty("dataPath", dataPath)
    System.setProperty("dbPath", dbPath)
    
    try {
      if (cmd.help) {
        CommandLine.usage(cmd, System.out)
        return
      }
      
      if (cmd.keyList) {
        keyList
        return
      }
      
      if (cmd.server) {
        new Server(cmd.ethName).run(cmd.noSchedule)
        return
      }
    } catch (Throwable ex) {
      if (cmd.stack)
        ex.printStackTrace
      else
        println(ex.message)
    }
  }
  
  def static void keyList() {
    val store = Store.setup
    store.KEY.all.forEach[
      println('''(«Key.GROUP»=«get(Key.GROUP)», «Key.KEY»=«get(Key.KEY)», «Key.VALUE»=«get(Key.VALUE)»), «Key.ACTIVE»=«get(Key.ACTIVE)»)''')
    ]
  }
}