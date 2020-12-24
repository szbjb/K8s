#!/bin/bash
ansible all  -m copy  -a  "src=/root/K8s/Uninstall/k8sdel   dest=/root/"
for  var in  $(ansible  all -m ping| grep SUCCESS|awk   '{print  $1}')  
        do 
        sleep 1 
        ssh   $var chmod  +x  /root/k8sdel
        ssh   $var   ./k8sdel
        ssh   $var hostnamectl  set-hostname  $RANDOM
done
