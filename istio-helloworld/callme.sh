#!/bin/bash
url=$(kubectl get po -l app=helloworld -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc helloworld -o 'jsonpath={.spec.ports[0].nodePort}')
while true
do 
    curl $url/hello
    sleep .1
done
