Percona XtraDB Cluster docker image
===================================

Right now the docker image is available at perconalab/percona-xtradb-cluster.
The image supports work in Docker Network, including overlay network,
so you can install Percona XtraDB Cluster nodes on different boxes.
There is an initial support for the discovery service Etcd

Basic usage
-----------

For the exampl see `start_node.sh` script

CLUSTER_NAME enviroment variable should be set, the easiest to do is
`export CLUSTER_NAME=cluster1`

The script will try to create overlay network ${CLUSTER_NAME}_net.
If you want to have a bridge network or network with specific parameter,
create it in advance.
For example:
`docker network create -d bridge ${CLUSTER_NAME}_net`

