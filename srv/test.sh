#!/bin/bash
# -Djava.security.debug="access,failure"
# -Djava.security.manager -Djava.security.policy=security.policy
java -jar -Dlogback.configurationFile=logback.xml -Djava.security.manager -Djava.security.policy=security.policy  ./build/libs/cad-proxy-0.1.0.jar "$@"

# ./test.sh -s 2>&1 >/dev/null | grep -A50 'denied'
