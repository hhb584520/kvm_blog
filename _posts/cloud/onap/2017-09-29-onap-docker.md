# docker

## 1. docker introduction 



## 2. docker use
### 2.1 list docker

	$ sudo docker ps
	CONTAINER ID  IMAGE         COMMAND                 CREATED      STATUS      PORTS       NAMES
	446e617a61c0  feb92fc22799  "/bin/sh -c '/bin/sh "  2 days ago   Up 2 days   9006/tcp    ocata-test

### 2.2 connect docker

	$ sudo docker exec -ti 446e617a61c0 bash



## 参考资料
https://yeasy.gitbooks.io/docker_practice/content/introduction/what.html