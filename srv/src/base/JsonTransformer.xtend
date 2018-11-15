package base

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializer
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import org.neo4j.graphdb.Node
import spark.ResponseTransformer

class JsonTransformer implements ResponseTransformer {
  val Gson gson
  
  val dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
  val df = DateTimeFormatter.ofPattern("yyyy-MM-dd")
  val tf = DateTimeFormatter.ofPattern("HH:mm:ss.SSS")
  
  val JsonSerializer<LocalDateTime> ldtSer = [src, type, ctx |
    new JsonPrimitive(src.format(dtf))
  ]
  
  val JsonSerializer<LocalDate> ldSer = [src, type, ctx |
    new JsonPrimitive(src.format(df))
  ]
  
  val JsonSerializer<LocalTime> ltSer = [src, type, ctx |
    new JsonPrimitive(src.format(tf))
  ]
  
  val JsonSerializer<Node> nodeSer = [src, type, ctx |
    new JsonPrimitive('''Node[«src.id»]''')
  ]
  
  new() {
    gson = new GsonBuilder()
      .registerTypeAdapter(LocalDateTime, ldtSer)
      .registerTypeAdapter(LocalDate, ldSer)
      .registerTypeAdapter(LocalTime, ltSer)
      .registerTypeHierarchyAdapter(Node, nodeSer)
      .create
  }
  
  def <T> T parse(String body, Class<T> type) {
    gson.fromJson(body, type)
  }
  
  override render(Object model) throws Exception {
    gson.toJson(model)
  }
}