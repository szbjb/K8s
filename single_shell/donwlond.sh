#下载最新版本
#定义下载官方地址列表
Link_A="
https://github.com/cloudflare/cfssl
https://github.com/etcd-io/etcd
https://github.com/coreos/flannel
https://github.com/heketi/heketi
https://github.com/helm/helm
"

#取直连下载+最新版本号+历史版本
_done_new_always ()  {
#cfssl,etcd,flannel,heketi
Link_A="
https://github.com/cloudflare/cfssl
https://github.com/etcd-io/etcd
https://github.com/coreos/flannel
https://github.com/heketi/heketi
"
for  VAR_Link_A in $(echo  $Link_A)
    do 
    link_a=$(curl  -s   ${VAR_Link_A}/tags| grep 'releases/tag/'| egrep   "muted-link" |grep  -v  "\-rc"|awk   -F '"'  '{print $4}'|head -n1)
    tags=$(echo $link_a|awk -F   '/'  '{print  $NF}')
    link_b=$(curl  -s  https://github.com${link_a}| egrep  "linux[-_.]amd64"|egrep "href="|awk -F '"'  '{print  $2}'| egrep -v "heketi-client|cfssl-bundle|cfssl-newkey|cfssl-scan|mkbundle|multirootca")
    soft_name=$(echo $link_b| xargs -n 1|awk   -F  '/'  '{print  $NF}'|xargs|sed  's/ /,/g')
    rm -fv {${soft_name}}
    for var in  $(echo  ${link_b});do rm -fv $(echo $var|awk   -F  '/'  '{print  $NF}')*; link_c=https://github.com${var};wget -t10    ${link_c} ;done
sleep  0.2
echo "$link_c"
done    

#k8s,
#取最新版本号
kubernetes_version_list=$(curl  -s https://github.com/kubernetes/kubernetes/tags  | grep 'releases/tag/'| egrep   "muted-link" |egrep  -v  "\-rc|alpha"|awk   -F '"'  '{print $4}'| head   -n 1|awk   -F  '/'  '{print  $NF}'|awk   -F  '.' '{print  $1"."$2}')
kubernetes_version_num=$(curl -s https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.19.md |grep 'Downloads for' |grep   "^<li><a"|awk  '{print  $NF}'|awk   -F '<'  '{print  $1}'|egrep   -  -v|head  -n 1)
rm -fv  ./${kubernetes_version_num}_kubernetes-server-linux-amd64.tar.gz
wget -O  ./${kubernetes_version_num}_kubernetes-server-linux-amd64.tar.gz  https://dl.k8s.io/${kubernetes_version_num}/kubernetes-server-linux-amd64.tar.gz
#helm
helm_version=$(curl  -s   https://github.com/helm/helm/tags| grep 'releases/tag/'| egrep   "muted-link" |grep  -v  "\-rc"|awk   -F '"'  '{print $4}'|head -n1  |awk   -F  '/'  '{print  $NF}')
rm -fv  helm-${helm_version}-linux-amd64.tar.gz   ;wget   https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz 



}

# link_a=$(curl  -s   https://github.com/cloudflare/cfssl/tags| grep 'releases/tag/'| egrep   "muted-link" |grep  -v  "\-rc"|awk   -F '"'  '{print $4}'|head -n1)
# link_b=https://github.com${link_a}

releases_version=$(echo $link_b|awk -F  '/' '{print  $NF}'|sed  's/v//g' )
link_cfssl=https://github.com/cloudflare/cfssl/releases/download/v${releases_version}/cfssl_${releases_version}_linux_amd64
link_cfssl_certinfo=https://github.com/cloudflare/cfssl/releases/download/v${releases_version}/cfssl-certinfo_${releases_version}_linux_amd64
link_cfssljson=https://github.com/cloudflare/cfssl/releases/download/v${releases_version}/cfssljson_${releases_version}_linux_amd64
# https://github.com/cloudflare/cfssl/releases/tag/v1.4.1
echo  -e "${link_cfssl}\n${link_cfssl_certinfo}\n${link_cfssljson} "
#download
for link_var  in  $(echo  -e "${link_cfssl}  ${link_cfssl_certinfo}  ${link_cfssljson} ")
do 
sleep  0.3
echo $link_var
link_cfssl_name=$(echo $link_var|awk -F   '/'  '{print  $NF}')
rm -fv ./${link_cfssl_name} 2>/dev/null
wget   ${link_var}
done 
clear
ls -l cfssl* && md5sum  cfssl*





https://github.com/cloudflare/cfssl/tags
https://github.com/cloudflare/cfssl/releases/tag/v1.4.1
curl -s https://github.com/cloudflare/cfssl/releases/tag/v1.4.1| egrep  "linux[-_.]amd64"|egrep "href="|awk -F '"'  '{print  $2}'


https://github.com/etcd-io/etcd/tags
         https://github.com/etcd-io/etcd/releases/tag/v3.4.13
curl -s  https://github.com/etcd-io/etcd/releases/tag/v3.4.13| egrep  "linux[-_.]amd64"|egrep "href="|awk -F '"'  '{print  $2}'

https://github.com/coreos/flannel/tags
         https://github.com/coreos/flannel/releases/tag/v0.12.0
curl -s  https://github.com/coreos/flannel/releases/tag/v0.12.0| egrep  "linux[-_.]amd64"|egrep "href="|awk -F '"'  '{print  $2}'


https://github.com/heketi/heketi/tags
         https://github.com/heketi/heketi/releases/tag/v10.0.0
curl -s  https://github.com/heketi/heketi/releases/tag/v10.0.0| egrep  "linux[-_.]amd64"|egrep "href="|awk -F '"'  '{print  $2}'
                           /heketi/heketi/releases/download/v10.0.0/heketi-v10.0.0.linux.amd64.tar.gz






https://github.com/cloudflare/cfssl/releases/download/v${releases_version}/cfssl_${releases_version}_linux_amd64
https://github.com/cloudflare/cfssl/releases/download/v${releases_version}/cfssl-certinfo_${releases_version}_linux_amd64
https://github.com/cloudflare/cfssl/releases/download/v${releases_version}/cfssljson_${releases_version}_linux_amd64





https://github.com/etcd-io/etcd/tags
https://github.com/coreos/flannel/tags
https://github.com/heketi/heketi/tags


https://github.com/etcd-io/etcd/releases/download/v${releases_version}/etcd-v${releases_version}-linux-amd64.tar.gz
https://github.com/coreos/flannel/releases/download/v${releases_version}/flannel-v${releases_version}-linux-amd64.tar.gz  
https://github.com/heketi/heketi/releases/download/v${releases_version}/heketi-v${releases_version}.linux.amd64.tar.gz

https://github.com/helm/helm
https://get.helm.sh/helm-v${releases_version}-linux-amd64.tar.gz