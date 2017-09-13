# Git Server #

## 1. start daemon ##
- install git daemon
  
	$ yum install git-daemon.x86_64

- start daemon
	
	$ git daemon --verbose --export-all --base-path=/home/ --reuseaddr & 
	
注意，我们也可以把这句话加到 /etc/rc.local 里面让其开机自动启动，另外如果是 ssh 方式，无须此步骤

## 2. create repo
### 2.1 my repo
	$ cd /home/
	$ mkdir mygit.git
	$ cd mygit.git
	$ git init --bare
	$ vim .git/config
		[core]
		        repositoryformatversion = 0
		        filemode = true
		        bare = true
		        logallrefupdates = true
		[branch "master"]
		        remote = origin
		        merge = refs/heads/master
		[daemon]
		        receivepack = true
		
		[receive]
		        denyCurrentBranch = ignore

### 2.2 remote repo

	$ cd /home/
	$ git clone https://git.kernel.org/pub/scm/virt/kvm/kvm.git kvm.git

这样最好 crontab 做一个定期同步，例如下面方法，当然可以 rsync 同步，当然直接 pull 也可以。

	$ cd /tmp 
	$ rm -rf kvm.git 
	$ git clone https://git.kernel.org/pub/scm/virt/kvm/kvm.git kvm.git
	$ rsync -av --delete /tmp/kvm.git  /home/ >> /tmp/tst.log 2>&1

## 3. git clone
### 3.1 git protocol
	git clone git://[ip/dnsname]/mygit.git

### 3.2 ssh protocol

	ssh://root@[ip/dnsname]/home/mygit.git