Build image

  `docker build -t percona-xtradb-cluster Dockerfile`

or

  `docker build --build-arg PXC_VERSION=5.6.29 -t percona-xtradb-cluster Dockerfile`

Tag image
  
  `docker tag <NNNNN> perconalab/percona-xtradb-cluster:5.6`

Push to hub

  `docker push perconalab/percona-xtradb-cluster:5.6`
  
Usage
=====

