# patroni setup

installation on rhel linux

example setup with 2 servers
do not use for production systems

server1: postgres, patroni, etcd
server2: postgres, patroni, haproxy



## install postgres software

```bash
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql13-server
sudo dnf install -y postgresql13-contrib

#### make sure the postgres service is stopped
sudo systemctl stop postgresql-13

## install patroni

dnf install -y patroni

## install etcd

### download and install etcd
mkdir /tmp/etcd 

ETCD_VER=v3.5.0
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GITHUB_URL}

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

sudo cp /tmp/etcd/etcd /usr/local/bin/
sudo cp /tmp/etcd/etcdctl /usr/local/bin/

check binary
etcd --version
```

### create config file

cat /etc/etcd.conf
ETCD_LISTEN_PEER_URLS="http://192.168.36.131:2380,http://localhost:2380"
ETCD_LISTEN_CLIENT_URLS="http:////192.168.36.131:2379,http://localhost:2379"

[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http:////192.168.36.131:2380"
ETCD_ADVERTISE_CLIENT_URLS="http:////192.168.36.131:2379"
ETCD_INITIAL_CLUSTER="default=http:////192.168.36.131:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"


### create data dir
mkdir -p /var/lib/etcd/
sudo useradd -s /sbin/nologin --system -g etcd etcd
sudo groupadd --system etcd
sudo chown -R etcd:etcd /var/lib/etcd/

create systemd file /etc/systemd/system/etcd3.service with following contents

[Unit]
Description=etcd key-value store
Documentation=https://github.com/etcd-io/etcd
After=network-online.target local-fs.target remote-fs.target time-sync.target
Wants=network-online.target local-fs.target remote-fs.target time-sync.target

[Service]
User=etcd
Type=notify
Environment=ETCD_DATA_DIR=/var/lib/etcd
Environment=ETCD_NAME=%m
ExecStart=/usr/local/bin/etcd
Restart=always
RestartSec=10s
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target

### start etcd 
sudo systemctl daemon-reload
systemctl start etcd3








