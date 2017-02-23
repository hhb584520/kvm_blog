# Git send patch mail #

## 1. Install and config git send-mail smtp ##
### 1.1 Install git-email ###
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

## 2.send mail and apply ##
### 2.1 Create patch ###

git format-patch -v 2 -2 --cover-letter --subject-prefix="GET v2" -o PATH

	-v : add version
	--subject-prefix : --subject-prefix="PATCH v2"
	--cover-letter: create 0000-cover-letter.patch
	-n : patch count
	-o : save patch path


### 2.2 send mail ###

  git send-email --confirm=never --to haibin.huang@intel.com --cc haibin.huang@intel.com *.patch
  
	-n : patch count
	--to: maillist
	--cc: maillist
	--confirm: never | always
  
### 2.3 apply patch ###
  save mail txt and change file *.patch

	git am -3 -i -s -u *.patch
  
## 3.Reference ##
  https://git-scm.com/docs/git-send-email

  
