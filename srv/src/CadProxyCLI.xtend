import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters
import java.security.Policy
import java.io.File
import org.slf4j.LoggerFactory

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
}

class CadProxyCLI {
  def static void main(String[] args) {
    Policy.policy = base.SecurityPolicy.CURRENT
    
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
    
    //NetworkInterface.getInetAddresses
    
    // /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext:/usr/java/packages/lib/ext
    LoggerFactory.getLogger("TEST").info("TEST")
    
    try {
      if (cmd.help) {
        CommandLine.usage(cmd, System.out)
        return
      }
      
      if (cmd.server) {
        base.Server.run
        return
      }
    } catch (Throwable ex) {
      if (cmd.stack)
        ex.printStackTrace
      else
        println(ex.message)
    }
  }
}