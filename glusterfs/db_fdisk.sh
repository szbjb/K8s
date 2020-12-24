#/bin/bash
#存储集群分区专用脚本
#检测可用的块设备
cd /root/K8s/glusterfs/
var_03=$(ansible  db -m shell -a  "lsblk | grep "disk"" |grep -v CHANGED |awk '{print $1}' |sort -n |uniq |grep  -v "^fd*")
> /root/K8s/ip_db.txt


for var_ip in $(ansible  db -m ping |grep  SUCCESS|awk   '{print $1}')
    do
      echo "================$var,检测裸块设备,该设备下以下ip可用于glusterfs分布式存储使用,默认分出40%,剩余60%挂载到 /data目录作为数据目录使用============================"
      echo
     for var_db_01 in $var_03
     do
     ansible $var_ip -m shell -a  "lsblk  /dev/${var_db_01}|grep  -v NAME|wc   -l"|xargs  -n 1|egrep   -v  "CHANGED|rc|>|\|"|xargs  -n 2  | grep " 1$" &&  echo $var_ip  >> /root/K8s/ip_db.txt
     done
     
     for var_db in $var_03
    do
      echo "================$var,检测裸块设备,该设备下以下ip可用于glusterfs分布式存储使用,默认分出40%,剩余60%挂载到 /data目录作为数据目录使用============================"
      echo
     ansible $var_ip -m shell -a  "lsblk  /dev/${var_db}|grep  -v NAME|wc   -l"|xargs  -n 1|egrep   -v  "CHANGED|rc|>|\|"|xargs  -n 2  | grep " 1$" && echo  $var_db >> /root/K8s/ip_db.txt
      done
done

grep  "\."  /root/K8s/ip_db.txt||{
echo  "所选存储节点无可用块设备,k8s集群持久化部署终止Heketi+GlusterFS"
exit 4
}


disk_var01=$(tail -n 1 /root/K8s/ip_db.txt)
#40%作为k8s存储
cat > db.sh <<  'EHF'
##节点磁盘分区检测
rm -rfv  /dev/mapper/vg_*  2>/dev/null
var_04=$(lsblk | grep "disk" |grep -v CHANGED |awk '{print $1}' |sort -n |uniq |grep  -v "^fd*")
for var in $var_04
    do
      echo "================$var,检测裸块设备,该设备下以下ip可用于glusterfs分布式存储使用,默认分出40%,剩余60%挂载到 /data目录作为数据目录使用============================"
      echo
    lsblk  /dev/${var}|grep  -v NAME|wc   -l|xargs  -n 1|egrep   -v  "CHANGED|rc|>|\|"|xargs  -n 2  | grep "1$" && var_data_db=$var
    lsblk  /dev/${var}|grep  -v NAME|wc   -l|xargs  -n 1|egrep   -v  "CHANGED|rc|>|\|"|xargs  -n 2  | grep "1$"|awk '{print  $1}' > /root/K8s/ip_db_011.txt
    # echo  $var >> /root/K8s/ip_db.txt
    echo "当前环境$var_data_db是裸磁盘"
done
[ ! -n "${var_data_db}" ] &&  exit  4
_cc ()  {
/usr/bin/expect << EOF
spawn /usr/sbin/parted  /dev/${var_data_db}     mklabel gpt
expect {
        "Yes" {send "Yes\r";}
}
expect eof
EOF
}
_cc01  () {
/usr/bin/expect << EOF
spawn /usr/sbin/pvcreate  /dev/${var_data_db}1
expect {
        "Wipe" {send "y\r";}
}
expect eof
EOF
}
###############
_cc
/usr/sbin/parted  /dev/${var_data_db}    mkpart primary 0%  55%
/usr/sbin/parted  /dev/${var_data_db}    mkpart primary 55%  100%
/usr/sbin/parted  /dev/${var_data_db}    p
while  [ true ]; do sleep 0.5; dmsetup remove   $(lsblk  -r /dev/${var_data_db}   |awk   '{print  $1}' |tac |  grep  "^vg_");   lsblk  -r /dev/${var_data_db}     | grep "^vg_" || break  1   ;done
sleep 3
mkfs.xfs  /dev/${var_data_db}1  -f
mkfs.xfs /dev/${var_data_db}2  -f
_cc01
mkdir -pv /data
echo  "/dev/${var_data_db}2      /data      xfs       defaults            0        0  "  >>  /etc/fstab
mount  /dev/${var_data_db}2   /data
EHF

sleep 1
# sed  "s/${var_data_db}/${disk_var01}/g"   db.sh  -i
#分区
# ansible db -m copy -a 'src=./db.sh dest=/opt/db.sh mode=755'
figlet  BEGIN  $(date +" %H : %M : %S") 2>/dev/null
ansible db -m script -a "chdir=/tmp ./db.sh"
figlet  E N D $(date +" %H : %M : %S") 2>/dev/null
# ansible db  -m shell  -a  "test -s /opt/db.sh" || {
# ehco "文件为空,持久化存储失败"
# exit 2
# }
# ansible db -m shell -a  "sh /opt/db.sh"
ansible db -m shell -a   "df -h| grep /data"
