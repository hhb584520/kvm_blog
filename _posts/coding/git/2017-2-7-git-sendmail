# Git send patch mail #

## 1. 先配置git send-mail 的 smtp服务器 ##
### 1.1 安装git-email ###

  $ apt-get install git git-core git-email
  $ vim ~/.gitconfig

[color]
ui = auto
[commit]
template = ~/.commit_template
[user]
name = ***
email = ***@***.com
[alias]
pretty = log --branches --remotes --tags --graph --oneline
--decorate
[sendemail]
smtpencryption = tls
smtpserver = smtp.intel.com
smtpuser = haibin.huang@intel.com
smtpserverport = 587
smtppass = abcdef
 
suppresscc = all //will suppress all auto cc values
confirm = always
to = *****.****@gmail.com //Specify the primary recipient
cc = s***linux@freelists.org //CC list

### 1.2 Then edit the .git/hooks/pre-commit ###
#!/bin/sh
exec git diff --cached | scripts/checkpatch.pl --no-signoff - || true

## 2.commit and send mail ##
### 2.1 按功能分类提交commit 
提交之前先执行脚本 ./scripts/cleanfile xx.   
加-s选项，自动Signed-off-by. 
git commit --amend --author " Xxx Zhang "(添加实际的author,如果author是本人，则不要写)
commit message 第一行要是patch的主题(包括patch的从属子系统，和概述)，第二行是patch的详细描述。
如果想修改其中的一个commit：
     a）git format-patch -n
     b）git reset到那个commit，如要更改或添加某个文件，git add; 如要删除某个commit的文件，(git reset HEAD^ file),然后 commit --amend
     c）git am *.patch (不用git apply，因为apply命令只将patch应用到index，而不会将commit message同时应用到git仓库上。如果当前目录下之前执行过git-am，而没有发送email，需要先执行git am --abort放弃掉之前的am信息。遇到了一次abort不掉的时候，执行rm -rf .git/rebase-apply/就可以了，参照如下Linkhttp://git.661346.n2.nabble.com/Dangerous-quot-git-am-abort-quot-behavior-td5853324.html)
### 2.2 生成patch ### 
git format-patch -2 --cover-letter//2表示从HEAD的commit开始，向前生成两个commit的patch。--cover-letter会生成一个0000-cover-letter.patch，格式和commit message类似，第一行是patchset的主题，第二行描述这组patchset的详细信息，它就是邮件中的【PATCH 0/n】(有必要的话，将测试结果和基于的主线版本写在0000-cover-letter.patch中的详细描述中)。
git format-patch -numbered --cover-letter --subject-prefix="PATCH v2" （如果不是第一版   patch需要添加版本号，以v2为例）

### 2.3 检查patch ### 
  ./scripts/checkpatch.pl 0001-nfs-add-a-pr_info.patch （不用检查0000-cover-letter.patch）

### 2.4 发邮件列表 ### 
  git send-email *.patch
  如果想要编辑patch邮件内容，加--annotate选项。
  编辑完一个退出vim用:wn命令,编辑下一个patch，直到最后一个直接wq退出vim即可。

$ git send-email *.patch
/tmp/59yD80Mjvb/0000-cover-letter.patch
/tmp/59yD80Mjvb/0001-clone-patch-test-001.patch
/tmp/59yD80Mjvb/0002-revised-text.patch
3 files to edit
Who should the emails appear to be from? [chunyan.zhang ]zh**.****@gmail.com//输入发件人邮箱
Emails will be sent from: zhang.lyra@gmail.com
Who should the emails be sent to? z***@gmail.com //输入收件人邮箱
Message-ID to be used as In-Reply-To for the first email?for_test//随便输入一个ID
