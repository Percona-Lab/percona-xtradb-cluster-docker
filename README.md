Percona XtraDB Cluster docker image
===================================

Right now the docker image is available at perconalab/percona-xtradb-cluster.
The image supports work in Docker Network, including overlay network,
so you can install Percona XtraDB Cluster nodes on different boxes.
There is an initial support for the discovery service Etcd

Basic usage
-----------

For the exampl see `start_node.sh` script

`CLUSTER_NAME` enviroment variable should be set, the easiest to do is
`export CLUSTER_NAME=cluster1`

The script will try to create overlay network `${CLUSTER_NAME}_net`.
If you want to have a bridge network or network with specific parameter,
create it in advance.
For example:
`docker network create -d bridge ${CLUSTER_NAME}_net`

Docker image accept following parameters
* One of `MYSQL_ROOT_PASSWORD`, `MYSQL_ALLOW_EMPTY_PASSWORD` or `MYSQL_RANDOM_ROOT_PASSWORD` must be defined
* The image will create user `xtrabackup@localhost` for xtrabackup SST method. If you want to use password for `xtrabackup` user - set `XTRABACKUP_PASSWORD`. 
* If you want to use the discovery service (right now only `etcd` is supported) - set the address to `DISCOVERY_SERVICE`. The image will automatically find running cluser by `CLUSTER_NAME` and join to existing cluster or start a new one.
* If you want to start without discovery service, use `CLUSTER_JOIN` variable. Empty variable will start new cluster, to join existing cluster set `CLUSTER_JOIN` to the list of IP addresses running cluster nodes.


Discovery service
-----------------

The cluster will try to register itself in the discovery service so new nodes or ProxySQL can easily find running nodes.

Assuming you have variable `ETCD_HOST` set to `IP:PORT` of running etcd, e.g. `export ETCD_HOST=10.20.2.4:2379`, you can explore current settings by
`curl http://$ETCD_HOST/v2/keys/pxc-cluster/$CLUSTER_NAME/?recursive=true  | jq`

Example output:
```
{
  "action": "get",
  "node": {
    "key": "/pxc-cluster/cluster4",
    "dir": true,
    "nodes": [
      {
        "key": "/pxc-cluster/cluster4/10.0.5.2",
        "dir": true,
        "nodes": [
          {
            "key": "/pxc-cluster/cluster4/10.0.5.2/ipaddr",
            "value": "10.0.5.2",
            "modifiedIndex": 19600,
            "createdIndex": 19600
          },
          {
            "key": "/pxc-cluster/cluster4/10.0.5.2/hostname",
            "value": "2af0a75ce0cb",
            "modifiedIndex": 19601,
            "createdIndex": 19601
          }
        ],
        "modifiedIndex": 19600,
        "createdIndex": 19600
      },
      {
        "key": "/pxc-cluster/cluster4/10.0.5.3",
        "dir": true,
        "nodes": [
          {
            "key": "/pxc-cluster/cluster4/10.0.5.3/ipaddr",
            "value": "10.0.5.3",
            "modifiedIndex": 26420,
            "createdIndex": 26420
          },
          {
            "key": "/pxc-cluster/cluster4/10.0.5.3/hostname",
            "value": "cfb29833f1d6",
            "modifiedIndex": 26421,
            "createdIndex": 26421
          }
        ],
        "modifiedIndex": 26420,
        "createdIndex": 26420
      }
    ],
    "modifiedIndex": 19600,
    "createdIndex": 19600
  }
}
```

Right now there is no automatic cleanup from discovery service registry, you can remove all entries by
`curl http://10.20.2.4:2379/v2/keys/pxc-cluster/$CLUSTER_NAME?recursive=true -XDELETE`

Starting discovery service
--------------------------

For the full documentation please check https://coreos.com/etcd/docs/latest/docker_guide.html

The simple script to start 1-node etcd (assuming `ETCD_HOST` variable is defined) is:

```
ETCD_HOST=${ETCD_HOST:-10.20.2.4:2379}
docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 4001:4001 -p 2380:2380 -p 2379:2379 \
 --name etcd quay.io/coreos/etcd \
 -name etcd0 \
 -advertise-client-urls http://${ETCD_HOST}:2379,http://${ETCD_HOST}:4001 \
 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
 -initial-advertise-peer-urls http://${ETCD_HOST}:2380 \
 -listen-peer-urls http://0.0.0.0:2380 \
 -initial-cluster-token etcd-cluster-1 \
 -initial-cluster etcd0=http://${ETCD_HOST}:2380 \
 -initial-cluster-state new
``` 

Running Docker overlay network
------------------------------

The great intro with easy steps how to run Docker overlay network is here http://chunqi.li/2015/11/09/docker-multi-host-networking/


Running with ProxySQL
---------------------

ProxySQL image https://hub.docker.com/r/perconalab/proxysql/
provides an integration with Percona XtraDB Cluster and discovery service.

You can start proxysql image by
```
docker run -d -p 3306:3306 -p 6032:6032 --net=$NETWORK_NAME --name=${CLUSTER_NAME}_proxysql \
        -e CLUSTER_NAME=$CLUSTER_NAME \
        -e ETCD_HOST=$ETCD_HOST \
        -e MYSQL_ROOT_PASSWORD=Theistareyk \
        -e MYSQL_PROXY_USER=proxyuser \
        -e MYSQL_PROXY_PASSWORD=s3cret \
        perconalab/proxysql
```

where `MYSQL_ROOT_PASSWORD` is root password for MySQL nodes, it is needed to register the proxy user. The user `MYSQL_PROXY_USER` with password `MYSQL_PROXY_PASSWORD` will be registered on all Percona XtraDB Cluster nodes


Running `docker exec -it ${CLUSTER_NAME}_proxysql add_cluster_nodes.sh` it will register all nodes in the ProxySQL

