#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

#远程下载地址
remote_dl_url="https://github.com/coreos/etcd/releases/download/v3.2.20/etcd-v3.2.20-linux-amd64.tar.gz"
etcd_filename="etcd.tar.gz"

if [[ -e /usr/bin/etcd ]]; then
    echo "/usr/bin/已存在文件 etcd" >&2
    exit 1
fi

if [[ -e $etcd_filename ]];then
	echo "已存在etcd.tar.gz" >&2
else
	echo "使用已存在的文件..." >&2
fi

if [[ $(which wget) ]]; then
	echo "正在下载etcd压缩包文件"  >&2
	wget $remote_dl_url -O $etcd_filename
else
    echo "Couldn't find wget . Bailing out." >&2
    exit 1
fi
echo "解压文件..." >&2
tar xf $etcd_filename
cd etcd
cp etcd etcdctl  /usr/bin/
mkdir -p /var/lib/etcd
mkdir -p /etc/etcd
echo "保存文件  etcd.service" >&2
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
echo "启动服务..."  >&2
systemctl daemon-reload
systemctl start etcd
systemctl status etcd.service