#!/bin/bash
set +x
sleep 7s
if [ "$(curl -X GET http://172.18.0.1:80/health)" = "ok" ] ; then echo "test OK";exit 0;  else echo "test KO" ;exit 1; fi
