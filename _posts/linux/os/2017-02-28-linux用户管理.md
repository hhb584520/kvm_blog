1.创建用户

    `# useradd -s /bin/sh -g group –G adm,root -d /usr/sam/ -m gem`

此命令新建了一个用户gem，该用户的登录Shell是/bin/sh，它属于group用户组，同时又属于adm和root用户组，其中group用户组是其主组。其中-d和-m选项用来为登录名sam产生一个主目录/usr/sam（/usr为默认的用户主目录所在的父目录）。
