#!/bin/bash

_A01 () {
OPTION=$(whiptail --title "Menu Dialog" --menu "Choose your favorite programming language." 15 60 4 \
"1" "Python" \
"2" "Java" \
"3" "C" \
"4" "PHP"  3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your favorite programming language is:" $OPTION
else
    echo "You chose Cancel."
fi
    

}






_K8s_list  ()  {
#获取kubernetes二进制包包列表
echo  "获取kubernetes二进制包包列表"
curl  -s     http://192.168.123.110:42344/K8s_list/|awk  -F  '">'    '{print $1}'|egrep  -v  "pre"|awk  -F '"'   '{print  $NF}'

K8s_list=$(curl  -s     http://192.168.123.110:42344/K8s_list/|awk  -F  '">'    '{print $1}'|egrep  -v  "pre"|awk  -F '"'   '{print  $NF}')
K8s_list_name=$(curl  -s     http://192.168.123.110:42344/K8s_list/|awk  -F  '">'    '{print $1}'|egrep  -v  "pre"|awk  -F '"'   '{print  $NF}'|awk   -F  '_'  '{print $1}')

all_k8s_list=" $(echo $K8s_list_name |xargs)"    
echo $all_k8s_list
Default_version="v1.15.7"
#choose_version=$(whiptail --title "指定媒体节点IP地址" --inputbox "集群数量充足情况不建议指定到master或者gpu节点?" 10 60 ${IP} 3>&1 1>&2 2>&3)
var_dan="单选==默认1.14.8不需要在线下载,其余的都会联网在线下载==单选"
ppp=$(echo  $all_k8s_list |xargs  -n 1|awk '{print " "$0}' |awk '{print $0"  单选==默认1.14.8不需要在线下载,其余的都会联网在线下载==单选  OFF"}')
choose_version=$(whiptail --title "选择需要安装的kubernetes版本" --radiolist "集群数量充足情况不建议指定到master或者gpu节点?" 20 65 13 ${Default_version} ${var_dan} ON ${ppp}  3>&1 1>&2 2>&3)
echo "选定媒体节点为 ${choose_version}"
echo ${choose_version}   > /root/K8s/k8s_Default_version.txt 
}



_k8s_dwon (){


mv -v /root/K8s/Software_package/kubernetes-server-linux-amd64.tar.gz   /root/K8s/Software_package/bak_kubernetes-server-linux-amd64.tar.gz 2> /dev/null
curl  -o /root/K8s/Software_package/kubernetes-server-linux-amd64.tar.gz  http://192.168.123.110:42344/K8s_list/$(echo  $K8s_list|xargs -n1 | grep  $choose_version )
}