CLUSTER_NAME=${CLUSTER_NAME:-Theistareykjarbunga}

# get cluster IP
clusterip=$(docker exec etcd /etcdctl get $CLUSTER_NAME)

if [ -z "$clusterip" ]; then
  echo "Bootstraping new cluster..."
  docker run -d -p 3306 --name=${CLUSTER_NAME}_node1 -e MYSQL_ALLOW_EMPTY_PASSWORD=1 perconalab/percona-xtradb-cluster --wsrep_cluster_name=$CLUSTER_NAME
  clusterip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CLUSTER_NAME}_node1)
  echo "New cluster ip: $clusterip"
  docker exec etcd /etcdctl set $CLUSTER_NAME $clusterip
else
  echo "Starting new node"
  # get current cluster size
  clustersize=$(docker exec -it ${CLUSTER_NAME}_node1 mysql -Bse "select VARIABLE_VALUE from information_schema.global_status where VARIABLE_NAME='wsrep_cluster_size'")
  clustersize=${clustersize//[[:space:]]/}

  if [ -z "$clustersize" ]; then
	echo "Can't detect the cluster size, exiting."
	exit 1
  fi
  echo "Current cluster size: ==${clustersize}=="
  clustersize=$(( clustersize + 1 ))
  docker run -d -p 3306 -e MYSQL_ALLOW_EMPTY_PASSWORD=1 perconalab/percona-xtradb-cluster --wsrep_cluster_name=$CLUSTER_NAME --wsrep_cluster_address="gcomm://$clusterip" --wsrep-sst-method=rsync
 

fi

# --wsrep_cluster_address="gcomm://$QCOMM"
