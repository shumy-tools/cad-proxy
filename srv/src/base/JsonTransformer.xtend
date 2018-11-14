package base

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializer
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import spark.ResponseTransformer
import java.time.LocalTime

class JsonTransformer implements ResponseTransformer {
  val Gson gson
  
  val dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
  val df = DateTimeFormatter.ofPattern("yyyy-MM-dd")
  val tf = DateTimeFormatter.ofPattern("HH:mm:ss.SSS")
  
  val JsonSerializer<LocalDateTime> ldtSer = [src, type, ctx |
    val str = src?.format(dtf)
    return new JsonPrimitive(str)
  ]
  
  val JsonSerializer<LocalDate> ldSer = [src, type, ctx |
    val str = src?.format(df)
    return new JsonPrimitive(str)
  ]
  
  val JsonSerializer<LocalTime> ltSer = [src, type, ctx |
    val str = src?.format(tf)
    return new JsonPrimitive(str)
  ]
  
  new() {
    gson = new GsonBuilder()
      .registerTypeAdapter(LocalDateTime, ldtSer)
      .registerTypeAdapter(LocalDate, ldSer)
      .registerTypeAdapter(LocalTime, ltSer)
      .create
  }
  
  def <T> T parse(String body, Class<T> type) {
    gson.fromJson(body, type)
  }
  
  override render(Object model) throws Exception {
    gson.toJson(model)
  }
}