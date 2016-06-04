CLUSTER_NAME=${CLUSTER_NAME:-Theistareykjarbunga}
ETCD_ADDR=10.20.2.4:2379
NETWORK_NAME=${CLUSTER_NAME}_net

docker network create -d overlay $NETWORK_NAME

# get cluster IP
clusterip=$(docker run cap10morgan/etcdctl -C $ETCD_ADDR  get $CLUSTER_NAME)

if [ -z "$clusterip" ]; then
  echo "Bootstraping new cluster..."
  docker run -d -p 3306 --name=${CLUSTER_NAME}_node1 --net=$NETWORK_NAME -e MYSQL_ALLOW_EMPTY_PASSWORD=1 perconalab/percona-xtradb-cluster --wsrep_cluster_name=$CLUSTER_NAME
  #clusterip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CLUSTER_NAME}_node1)
  clusterip=$(docker inspect --format "{{ .NetworkSettings.Networks.${NETWORK_NAME}.IPAddress }}" ${CLUSTER_NAME}_node1)
  echo "New cluster ip: $clusterip"
  # register IP in the discovery service
  docker run cap10morgan/etcdctl -C $ETCD_ADDR set $CLUSTER_NAME $clusterip
else
  echo "Joining new node to $clusterip"
  docker run -d -p 3306 --net=$NETWORK_NAME -e MYSQL_ALLOW_EMPTY_PASSWORD=1 perconalab/percona-xtradb-cluster --wsrep_cluster_name=$CLUSTER_NAME --wsrep_cluster_address="gcomm://$clusterip" --wsrep_sst_method=xtrabackup-v2 --wsrep_sst_auth="root:"
 
fi

# --wsrep_cluster_address="gcomm://$QCOMM"
