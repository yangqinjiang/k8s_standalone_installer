#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail
echo -e "\033[42;37m-----------正在安装ETCD组件-----------\033[0m"
#远程下载地址
remote_dl_url="https://github.com/coreos/etcd/releases/download/v3.2.20/etcd-v3.2.20-linux-amd64.tar.gz"
etcd_filename="etcd.tar.gz"
dir_filename="etcd-v3.2.20-linux-amd64"

if [[ -e /usr/bin/etcd ]]; then
    echo -e "\033[41;37m 已存在文件  /usr/bin/etcd \033[0m" >&2
    exit 1
fi

if [[ -e $etcd_filename ]];then
	echo -e "\033[44;37m已存在etcd.tar.gz\033[0m" >&2
else
	echo -e "\033[44;37m下载文件...\033[0m" >&2
	if [[ $(which wget) ]]; then
		echo "正在下载etcd压缩包文件"  >&2
		wget $remote_dl_url -O $etcd_filename
	else
	    echo -e "\033[41;37mCouldn't find wget . Bailing out.\033[0m" >&2
	    exit 1
	fi
fi

mkdir -p etcd
echo -e "\033[44;37m解压文件...\033[0m" >&2
tar xf $etcd_filename
cd $dir_filename
echo -e "\033[44;37mCOPY文件...\033[0m" >&2
cp etcd etcdctl  /usr/bin/
mkdir -p /var/lib/etcd
mkdir -p /etc/etcd
echo -e "\033[44;37m保存文件  etcd.service\033[0m" >&2
cat > /usr/lib/systemd/system/etcd.service <<EOF
[Unit]
Description=Etcd Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd

[Install]
WantedBy=multi-user.target
EOF
echo -e "\033[44;37m启动服务...\033[0m , 显示 \033[32m active (running) \033[0m 说明安装成功"  >&2
systemctl daemon-reload
systemctl start etcd
systemctl status etcd.service

sleep 1
echo -e "\033[44;37m查看服务状态...\033[0m"  >&2
netstat -lntp|grep etcd
sleep 1
etcdctl  cluster-health

echo -e "\033[42;37m-----------ETCD DONE-----------\033[0m"