
#!/bin/bash
java -jar -Dlogback.configurationFile=logback.xml ./build/libs/cad-proxy-0.1.0.jar "$@"
