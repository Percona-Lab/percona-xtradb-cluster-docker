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

Cluster will try to register itself in the discovery service so new nodes or ProxySQL can easily find running nodes.


