
# GIT Essentials

Author		: Jike Song <jike.song@intel.com>
Last Update	: 05/04/2016

# 1. GENESIS: THE BIRTH OF GIT


	* The 1st DVCS: Sun WorkShop TeamWare

		- 1990's
		- Larry McVoy


	* BitKeeper

		- Born 1998
		- Larry McVoy
		- Used to maintain Linux Kernel during 2002~2005


	* The 2005 Storm

		- Challenge from Richard Stallman et al.
		- Andrew Tridgell's Reverse Engineering
		- Larry: BitKeeper became unavailable
		- People tried to develop alternatives:

			1) Git. By Linus Torvalds, 7 April 2005
			2) Mercurial. By Matt Mackall, 19 April 2005


	* Initial GIT

		* taken ~10 days to take shape

		* the name explanation from README:

			GIT - the stupid content tracker

		  "git" can mean anything, depending on your mood.

		   - random three-letter combination that is pronounceable, and not
		     actually used by any common UNIX command.  The fact that it is a
		     mispronounciation of "get" may or may not be relevant.
		   - stupid. contemptible and despicable. simple. Take your pick from the
		     dictionary of slang.
		   - "global information tracker": you're in a good mood, and it actually
		     works for you. Angels sing, and a light suddenly fills the room.
		   - "goddamn idiotic truckload of sh*t": when it breaks


# 2. ECCLESIASTES: GIT ESSENTIALS

## 2.1 basic background

	- Git is a DVCS(Distributed Version Control System)

	- All copies of a repo are *exactly* the same

	- Git is highly integrated with a lot of utilities in shell environment

	- Always install the all-in-one package:

		# apt-get install git-all
		# yum install git-all

	- Unfriendly for beginners

		"You can do things so many ways." - Linus Torvalds on Git

		"His latest cruel act is to create a revision control system
		which is expressly designed to make you feel less intelligent
		than you thought you were."  - Andrew Morton on Linus





## 2.2 basic glossary
FYI:	man 7 gitglossary


	- working tree

		Dirs & Files you actually see in the filesystem.


	- DAG (commit object database)

		The metadata of your git repository. All objects are linked
		together in a DAG (Directed Acyclic Graph).

	- INDEX

		The cache between your working tree and DAG.

	- HEAD

		The newest commit of *current* branch.



	To illustrate:



			+----------+
			| working  |
			| tree     |----------+
			+----------+          |
			     |                |
			     | add            |
			     |                |
			     v                |
			+----------+          |
			|  INDEX   |          | commit -a
			+----------+          |
			     |                |
			     | commit         |
			     |                |
			     v                |
			+----------+          |
			| commit   |          |
			| object   |<---------+
			| database |
			+----------+


		Figure 1: How your "add/commit" works

		"git add"	-  add your changes from working tree, to index
		"git commit"	- commit your changes in index, to DAG, thereby form a new HEAD
		"git commit -a"	- commit your changes in both working tree and index




			+----------+
			| working  |
			| tree     |----------+
			+----------+          |
			     |                |
			     | diff           |
			     |                |
			+----------+          |
			| INDEX    |          | diff HEAD
			+----------+          |
			     |                |
			     | diff --cached  |
			     |                |
			+----------+          |
			| commit   |          |
			| object   |----------+
			| database |
			+----------+

		Figure 2: How your "diff" works

		"git diff"		- diff your working tree against index
		"git diff --cached"	- diff your index with HEAD
		"git diff HEAD"		- diff your working tree with HEAD

## 2.3 basic workflow

	To illustrate, let's assume that there are 2 machines:

		* The machine "server", with a git repository: "warehouse",
                  with a branch: "twig";

		* The machine "client", on which we cloned "warehouse";



	              +---------------+
	              | local branch  |<---.
	              | "twig"        |---. \
	              +---------------+    \ \
	                        |           \ \
	                        |            \ \
	                        |             \ \
	"warehouse" on server   |              \ \
	------------------------|---------------\-\------------------------
	"warehouse" on client   |                \ \ push
	                        | fetch      pull \ \
	                        |          (fetch+ \ \
	                        v           merge)  \ \    +--------------+
	             +---------------+               \ *---| local branch |
	             | remote branch |   merge        *--->| "twig"       |
	             | "origin/twig" |-------------------->|              |
	             +---------------+                     +--------------+
	              remote "origin"


			Figure 3: Basic remote tracking workflow

		* "remote" is a git keyword, a "remote" stands for a remote
		  git repo (an URL);

		* "origin" is not a keyword: it's simply the default
		  "remote" (determined at "git clone");

		* "origin/twig" of client, is the mirror of "twig" of server;

		* on client, "git pull" ==

			git fetch + git merge origin/twig	//by default
			git fetch + git rebase origin/twig	//pull --rebase

## 2.4 basic glossary continued

	fast-forward

		Your local branch "twig", is a proper subset of the remote branch "origin/twig".
		Merging "twig" with "origin/twig" will be called "fast-forward": it simply
		update "twig" to "origin/twig", not generating a merge commit.


	refspec

		You want to push "twig" of client, to "twig" of server:

			$ git push origin twig:twig

		However, if you want to push it to generate a new branch "new_twig" on server:

			$ git push origin twig:new_twig

		Add if you want to push a particular commit to generate a new branch:

			$ git push origin master~10:new_twig

		Here "origin" specifies which remote the target is;
		"foo:bar" is the refspec: "foo" identifies the source revision of the client;
		"bar" identifies the target branch name oof the server.

		To delete the "twig" branch from server:

			$ git push origin :twig



	bare repo

		A git repo without working tree or INDEX, only metadata.
		If a repo is to be shared by multiple users, it should be bare.

		git init --bare
		git clone --bare


	To illustrate:


		origin/twig	A1--A2--A3-|-B1--B2--B3
					   |
		twig		A1--A2--A3-|-[X]

			[X] If you do a "git merge" here, it's a fast-forward.


		origin/twig	A1--A2--A3-|-B1--B2--B3
					   |           \
					   |            \
		twig		A1--A2--A3-|-C1--C2--C3--[X]--M1--

			[X] If you do a "git merge" here, it's a merge, will generate
			    a "merge commit" M1, with 2 parents: B3 and C3.


		origin/twig	A1--A2--A3-|-B1--B2--B3
					   |           \
					   |            \
		twig		A1--A2--A3-|-C1--C2--C3--[X]--
					   |-B1--B2--B3--(C1)--(C2)--(C3)

			[X] if you do a "git rebase" here, by default it will get
			    B1-B2-B3 at first, then take it as the new "base", and
			    place C1-C2-C3 upon that.


				Figure 4: fast-forward, merge, rebase

# 3. GOSPELS: GIT ADVANCED

## 3.1 stash your WIP
FYI	WIP == Work In Progress

	//to save the changes
	$ git stash [save]

	//to list your stashes
	$ git stash list

	//show a particular stash
	$ git stash show -p stash@{2}

	//apply a particular stash
	$ git stash apply stash@{2}

	//drop a particular stash
	$ git stash drop stash@{2}

	//pop from the stash stack
	//== git stash apply stash@{0} + git stash drop stash@{0}
	$ git stash pop

	//drop all stashes
	$ git stash clear


## 3.2 backup your repository

	"git bundle" backups your repository *with* metadata:

		//backup your repo into a single file
		$ git bundle create /tmp/warehouse.bundle --all

		//restore your repo from a single file
		$ git clone /tmp/warehouse.bundle


	"git archive" exports your repository *without* metadata:

		//archive your code as a bzipped tarball
		$ git archive --format=tar --prefix=linux-4.5/ v4.5 | bzip2 > /tmp/linux-4.5.tar.bz2

		//archive your code to a directory
		$ mkdir /tmp/linux-4.5
		$ git archive v4.5 | tar -xf - -C /tmp/linux-4.5

		NOTE: Use "HEAD" instead of the tag to archive current branch.


## 3.3 commit template

	$ cat .git/COMMIT_TEMPLATE
	FIX BUG: PLACEHOLDER(remove this line if this is *NOT* a bugfix)

	$ grep template .git/config
	template = .git/COMMIT_TEMPLATE

	With configurations above, whenever you run "git commit -e", the editor
	will have the template file read in.


## 3.4 track an empty dir

	Git tracks regular files only. To track an empty directory, you need to do
	something like:

		$ mkdir emptydir
		$ echo "!.gitignore" > emptydir/.gitignore
		$ git add emptydir

	That is, tell git to track a ".gitignore" file, which tells git to ignore
	everything but itself.


	FYI	".gitignore" is a regular file tracked by git; ".git/info/exclude"
		is a git configuration file without being tracked.


## 3.5 remove untracked files

	//before removal, backup your files
	$ mkdir /tmp/backup
	$ git ls-files --others --exclude-stardard -z |cpio -pmd0 /tmp/backup

	//remove untracked files
	$ git clean -d -f


## 3.6 diff effectively

	//diff a particular file between 2 branches
	$ git diff master staging fs/ext4/inode.c

	//diff two branches
		$ git diff master staging
	or:
		$ git diff master..staging

	//diff what's in staging since it divorced from master
	$ git diff master...staging


## 3.7 show current branch in bash

	Adding the following function to your ~/.bashrc:

		parse_git_branch()
		{
			git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'
		}
		export PS1="\$(parse_git_branch)$PS1"

	If you enter a dir or subdir of a git repo, bash will show:

			(staging) [user@host dir]$

## 3.8 my gitconfig
FYI	$HOME/.gitconfig is global, while ".git/config" is repository wide.

	$ cat ~/.gitconfig
	[user]
		name = Jike Song
		email = jike.song@intel.com
	[core]
		filemode = true
		bare = false
		pager = less -NFL
		editor = vim -c 'set ft=diff' -c 'set spell'
		gitproxy = none for intel.com
		gitproxy = /usr/bin/socks-gw
		quotepath = false
	[color]
		diff = true
		status = true
		interactive = true
		branch = true
		grep = true
	[daemon]
		receivepack = false
	[gc]
		auto = true
	[alias]
		co = checkout
		br = branch
		st = status
		df = diff
		desc = describe
		changelog = log ORIG_HEAD.. --no-merges
		outgoing = log origin/master..HEAD
		shrink = gc --aggressive --prune=all
		ignored = ls-files --others -i --exclude-standard
	[push]
		default = current
	[sendemail]
		smtpserver = smtp.intel.com
		smtpport = 25
		thread = true
		chainreplyto = false


## 3.9 other advanced topics

	git rebase

	git reset

	git reflog

	git am, git cherry-pick

	git send-email

	git grep

	git ls-files

	git merge-base

	git submodule

# 4. REVELATION: BIBLIOGRAPHY

	Wikipedia:

		https://en.wikipedia.org/wiki/Git_(software)

	10 years git interview:

		https://www.linux.com/blog/10-years-git-interview-git-creator-linus-torvalds

	Google Tech Talk: Linus Torvalds on Git:

		https://www.youtube.com/watch?v=4XpnKHJAok8

	Pro Git:

		https://git-scm.com/book/en/v2

	RTFM
		man git

		{git source}/Documentation
	
	rypress
	http://rypress.com/tutorials/git/index
