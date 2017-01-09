# 1. 配置VIM

首先，安装vim，一般情况下在安装redhat时，默认就安装了vim。你可以用vim -v来查看你的系统是否安装了vim。如果显示了vim版本就表示已经安装了vim，否则你可以通过“从这里开始”-->“系统设置”-->“添加/删除应用程序”，然后选中“编辑器”来更新你的软件。安装之后就要通过配置.vimrc配置符合自己风格的vim了。接下来就要找到.vimrc，如果你上网查找一些相关的资料时，他们会告诉你：在用户主目录——/home/root/下有一个.vimrc文件，在/etc/目录下也有一个vimrc。但是，也许你找了很久都没有找到这两个文件，这很正常，因为在刚安装上vim时，在以上两个目录中确实没有这两个文件，换句话说，这两个文件是认为加上去的。要找到你的vimrc，首先用vim打开一个文件，然后在vim中输入指令":version" ，你会看到"系统vimrc配置文件：/usr/share/vim/vim61/macros/vimrc"，然后将这个文件拷贝到你的主目录下，cp  /usr/share/vim/vim61/macros/vimrc  /root/ ，将vimrc改名为隐藏文件，mv vimrc .vimrc。接下来打开.vimrc，在里面添加几个条目：

在 /etc/vimrc添加下面的条目  
set number    " turn on line number——开启行号显示  
// set mouse     " use mouse everywhere——开启鼠标功能  
set cindent    " do c-style indenting——使用C风格缩进  
这样，vim基本就配置完成了。当然在编辑.vimrc时可以根据个人的喜好设置，具体的设置项可以使用:help命令查看，或者上网查查吧。  

 
# 2. 配置ctags
首先到http://ctags.sourceforge.net/下载ctags-5.8.tar.gz ，注意：有些浏览器（例如IE8）会阻止文件下载，这时只需要解除阻止即可进入下载界面。然后安装ctags.

    #tar xzvf ctags-5.8.tar.gz
    #cd ctags-5.8
    #./configure
    #make
    #make install

注意：如果你在执行./configure时出现错误，那么很有可能就是你的gcc没有安装完全，解决方法——“从这里开始”-->“系统设置”-->“添加/删除应用程序”，然后选择“开发工具”，更新你的gcc编译器。安装完成后就可以使用ctags命令了。

	`# ctags -R *`
或  

	`# ctag -R    // 在需要参加 tag 的目录里面执行。`

"-R"表示递归创建，也就包括源代码根目录下的所有子目录下的源程序。"tags"文件中包括这些对象的列表：  
l         用#define定义的宏  
l         枚举型变量的值  
l         函数的定义、原型和声明  
l         名字空间（namespace）  
l         类型定义（typedefs）  
l         变量（包括定义和声明）  
l         类（class）、结构（struct）、枚举类型（enum）和联合（union）  
l         类、结构和联合中成员变量或函数  

注意：运行vim的时候，必须在"tags"文件所在的目录下运行。否则，运行vim的时候还要用":set tags="命令设定"tags"文件的路径，这样vim才能找到"tags"文件。

VIM用这个"tags"文件来定位上面这些做了标记的对象，下面介绍一下定位这些对象的方法： 

1) 用命令行。在运行vim的时候加上"-t"参数，例如：

    # vim -t foo_bar
    这个命令将打开定义"foo_bar"（变量或函数或其它）的文件，并把光标定位到这一行。

2)在vim编辑器内用":ta"命令，例如：

    :tag  foo_bar

3)最方便的方法是把光标移到变量名或函数名上，然后按下"Ctrl-]"。用"Ctrl-o"退回原来的地方。  
4) 变量定义和光标移到    
- ‘gd’  转到当前光标所指的局部变量的定义  
- ‘*’    转到当前光标所指的单词下一次出现的地方  
- ‘#’    转到当前光标所指的单词上一次出现的地方  


# 3. 配置taglist #
首先下载taglist_45.zip，下载地址http://www.vim.org/scripts/script.php?script_id=273
解压文件：unzip -d taglist taglist_42.zip    -d 表示要把文件解压到某个目录下。
解压得到两个文件。./taglist/doc/taglist.txt; ./taglist/plugin/taglist.vim
分别复制到各自的目录下：
    
    cp ./taglist/doc/taglist.txt /usr/share/vim/vim61/doc/
    cp ./taglist/plugin/taglist.vim /usr/share/vim/vim61/plugin/

配置 ~/.vimrc文件。

    filetype plugin on 
    let Tlist_Ctags_Cmd = '/usr/bin/ctags' “设置ctags命令目录
    let Tlist_Show_One_File = 1 "不同时显示多个文件的tag，只显示当前文件的 
    let Tlist_Exit_OnlyWindow =  1 "如果taglist窗口是最后一个窗口，则退出vim 
    let Tlist_Use_Right_Window = 1 “让taglist窗口在右侧显示

命令与用法：  
在vim中命令模式下使用：  
:Tlist              // 打开或者关闭当前文件的索引；  
:TlistSync     // 立即在打开的索引窗口中定位当前的光标所在位置属于哪个函数或者结构定义中。  
在Taglist窗口按  
F1:打开帮助  
回车键: 跳到光标所在的标记的定义处(如将光标移到main函数,按回车键)  
o: 新建一个窗口,跳到标记定义处  
p: 预览标记定义(仍然在taglist窗口)  
空格:显示标记的原型(如函数原型)  
u:更新标记列表(比如源文件新增了一个函数,并在保存后,可在taglist窗口按u)  
s:选择排序字段  
d:删除光标所在的taglist文件(如用vi打开了两个文件f1.c,f2.c可以删除f1.c的标记)  
x:放大/缩小taglist窗口  
+:展开(指标记)  
-:折叠  
*:全部展开  
=:全部折叠  
[[:将光标移到前一个文件的起点  
]]:将光标移到后一个文件的起点  
q:退出taglist窗口  
F1:关闭帮助   

# 4. tmux #
tmux是一个优秀的终端复用软件，即使非正常掉线，也能保证当前的任务运行，这一点对于 远程SSH访问特别有用，网络不好的情况下仍然能保证工作现场不丢失!此外，tmux完全使用键盘 控制窗口，实现窗口的切换功能。
简单地说，tmux对于我主要有两个功能（这应该也是tmux的主要功能）:
split窗口。可以在一个terminal下打开多个终端，也可以对当前屏幕进行各种split，即可以 同时打开多个显示范围更小的终端。
在使用SSH的环境下，避免网络不稳定，导致工作现场的丢失。想象以下场景， 你在执行一条命令的过程中，由于网络不稳定，SSH连接断开了。这个时候，你就不知道之前 的那条命令是否执行成功。如果此时你打开了很多文件，进入了较深层次的目录，由于网络 不稳定，SSH连接断开。重新连接以后，你又不得不重新打开那些文件，进入那个深层次的 目录。如果使用了tmux，重新连接以后，就可以直接回到原来的工作环境，不但提高了工作 效率，还降低了风险，增加了安全性。
## 4.1安装 ##
sudo apt-get install tmux
安装完成后输入命令tmux即可打开软件，界面十分简单，类似一个下方带有状态栏的终端控制台； 不出意外，这时候你会跟我第一次一样，觉得tmux没什么牛逼的。根据tmux的定义，在开启了tmux服务器后，会首先创建一个会话，而这个会话则会首先创建一个 窗口，其中仅包含一个面板；也就是说，这里看到的所谓终端控制台应该称作tmux的一个面板， 虽然其使用方法与终端控制台完全相同。
tmux使用C/S模型构建，主要包括以下单元模块：  

- server服务器。输入tmux命令时就开启了一个服务器。
- session会话。一个服务器可以包含多个会话
- window窗口。一个会话可以包含多个窗口。
- pane面板。一个窗口可以包含多个面板。

## 4.2常用按键 ##
这里需要说明一点的是，tmux的任何指令，都包含一个前缀，也就是说，你按了前缀(一组按键， 默认是Ctrl+b)以后，系统才知道你接下来的指令是发送给tmux的。

- C-b ? 显示快捷键帮助
- C-b C-o 调换窗口位置，类似与vim 里的C-w
- C-b 空格键 采用下一个内置布局
- C-b ! 把当前窗口变为新窗口
- C-b “ 横向分隔窗口
- C-b % 纵向分隔窗口
- C-b q 显示分隔窗口的编号
- C-b o 跳到下一个分隔窗口
- C-b 上下键 上一个及下一个分隔窗口
- C-b C-方向键 调整分隔窗口大小
- C-b c 创建新窗口
- C-b 0~9 选择几号窗口
- C-b c 创建新窗口
- C-b n 选择下一个窗口
- C-b l 切换到最后使用的窗口
- C-b p 选择前一个窗口
- C-b w 以菜单方式显示及选择窗口
- C-b t 显示时钟
- C-b ; 切换到最后一个使用的面板
- C-b x 关闭面板
- C-b & 关闭窗口
- C-b s 以菜单方式显示和选择会话
- C-b d 退出tumx，并保存当前会话，这时，tmux仍在后台运行，可以通过tmux attach进入 到指定的会话

## 4.3 配置 ##
我们先来看一下几个配置。tmux的配置文件是 ~/.tmux.conf，这个文件可能不存在，你可以自己新建。下面开始配置，首先，有没有 觉得tmux的前缀按起来太不方便了，ctrl与b键隔得太远，很多人把它映射成C+a，也就 是在配置文件(~/.tmux.conf)中加入下面这条语句：

	#设置前缀为Ctrl + a
	set -g prefix C-a
	与此同时，取消默认的前缀按键：
	#解除Ctrl+b 与前缀的对应关系
	unbind C-b

配置完以后，重启tmux起效，或者先按C+b，然后输入：，进入命令行模式， 在命令行模式下输入：
source-file ~/.tmux.conf
你也可以跟我一样，在配置文件中加入下面这句话，以后改了只需要按前缀+r了。

	#将r 设置为加载配置文件，并显示"reloaded!"信息
	bind r source-file ~/.tmux.conf \; display "Reloaded!"

关于前缀，很多人都喜欢改成Ctrl+a，不过我个人更喜欢Ctrl+x，如果你是vim用户，你一定懂 的。还有就是面板的切换很不方便，需要先按前缀，再按方向键，还记得vim里面怎么切换各个 面板的吗？tmux也可以，因为它支持映射。把前缀映射改成Ctrl+x，再加入如下几条语句， 现在切换窗口就和vim一摸一样了，顿时觉得亲切了很多。

	#up
	bind-key k select-pane -U
	#down
	bind-key j select-pane -D
	#left
	bind-key h select-pane -L
	#right
	bind-key l select-pane -R

上面的最后一条语句会更改C-x l的功能，我挺喜欢这个功能的，因为我们很时候都是在两个窗 口或这两个面板中切换，所以我又加入如下语句

	#select last window
	bind-key C-l select-window -l

现在我的l键可不能随便按了，Ctrl+x l是切换面板，Ctrl+x Ctrl+l切换窗口，Ctrl+l清屏。
复制模式copy-mode
前缀 [ 进入复制模式
按 space 开始复制，移动光标选择复制区域
按 Enter 复制并退出copy-mode。
将光标移动到指定位置，按 PREIFX ] 粘贴
如果把tmux比作vim的话，那么我们大部分时间都是处于编辑模式，我们复制的时候可不可以像 vim一样移动呢？只需要在配置文件(~/.tmux.conf)中加入如下行即可。

	#copy-mode 将快捷键设置为vi 模式
	setw -g mode-keys vi

## 4.4 会话 ##
- C-x s 以菜单的方式查看并选择会话
- C-x :new-session 新建一个会话
- C-x d 退出并保存会话

终端运行 tmux attach 返回会话

	#命名会话
	tmux new -s session
	tmux new -s session -d #在后台建立会话
	tmux ls #列出会话
	tmux attach -t session #进入某个会话

使当前pane 最大化

	# zoom pane <-> window
	#http://tmux.svn.sourceforge.net/viewvc/tmux/trunk/examples/tmux-zoom.sh
	bind ^z run "tmux-zoom"

滚屏
	滚屏要进入copy-mode，即前缀+[，然后就可以用上下键来滚动屏幕，配置了vi快捷键模式，就 可以像操作vi一样来滚动屏幕，非常的方便。退出直接按‘q’键即可。


## 4.5 快速启动tmux ##
如果觉得每次都要打开tmux，然后在打开几个窗口和面板很麻烦，那么下面这个脚本你一定会 喜欢。参考这里
	#!/bin/sh
	#
	
	cmd=$(which tmux) # tmux path
	session=codefun   # session name
	
	if [ -z $cmd ]; then
	  echo "You need to install tmux."
	  exit 1
	fi
	
	$cmd has -t $session
	
	if [ $? != 0 ]; then
	  $cmd new -d -n vim -s $session "vim"
	  $cmd splitw -v -p 20 -t $session "pry"
	  $cmd neww -n mutt -t $session "mutt"
	  $cmd neww -n irssi -t $session "irssi"
	  $cmd neww -n cmus -t $session "cmus"
	  $cmd neww -n zsh -t $session "zsh"
	  $cmd splitw -h -p 50 -t $session "zsh"
	  $cmd selectw -t $session:5
	fi
	
	$cmd att -t $session
	
	exit 0


# 5. 附录 #
## 5.1 vim 配置文件
### 5.1.1 vim 配置文件介绍
在终端下使用vim进行编辑时，默认情况下，编辑的界面上是没有显示行号、语法高亮度显示、智能缩进
等功能的。为了更好的在vim下进行工作，需要手动设置一个配置文件：.vimrc。
在启动vim时，当前用户根目录下的.vimrc文件会被自动读取，该文件可以包含一些设置甚至脚本，
所以，一般情况下把.vimrc文件创建在当前用户的根目录下比较方便，即创建的命令为：
$vi ~/.vimrc

设置完后
$:x 或者 $wq 
进行保存退出即可。
下面给出一个例子，其中列出了经常用到的设置，详细的设置信息请参照参考资料：
“双引号开始的行为注释行，下同
“去掉讨厌的有关vi一致性模式，避免以前版本的一些bug和局限
set nocompatible
“显示行号
set number
“检测文件的类型
filetype on 
“记录历史的行数
set history=1000 
“背景使用黑色
set background=dark 
“语法高亮度显示
syntax on 
“下面两行在进行编写代码时，在格式对起上很有用；
“第一行，vim使用自动对起，也就是把当前行的对起格式应用到下一行；
“第二行，依据上面的对起格式，智能的选择对起方式，对于类似C语言编
“写上很有用
set autoindent
set smartindent
“第一行设置tab键为4个空格，第二行设置当行之间交错时使用4个空格
set tabstop=4
set shiftwidth=4
“设置匹配模式，类似当输入一个左括号时会匹配相应的那个右括号
set showmatch
“去除vim的GUI版本中的toolbar
set guioptions=T
“当vim进行编辑时，如果命令错误，会发出一个响声，该设置去掉响声
set vb t_vb=
“在编辑过程中，在右下角显示光标位置的状态行
set ruler
“默认情况下，寻找匹配是高亮度显示的，该设置关闭高亮显示
set nohls
“查询时非常方便，如要查找book单词，当输入到/b时，会自动找到第一
“个b开头的单词，当输入到/bo时，会自动找到第一个bo开头的单词，依
“次类推，进行查找时，使用此设置会快速找到答案，当你找要匹配的单词
“时，别忘记回车
set incsearch
“修改一个文件后，自动进行备份，备份的文件名为原文件名加“~“后缀
if has(“vms”) //注意双引号要用半角的引号"　"
set nobackup
else
set backup
endif
如果去除注释后，一个完整的.vimrc配置信息如下所示：
set nocompatible
set number
filetype on 
set history=1000 
set background=dark 
syntax on 
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set showmatch
set guioptions-=T
set vb t_vb=
set ruler
set nohls
set incsearch
if has("vms")
set nobackup
else
set backup
endif

如果设置完后，发现功能没有起作用，检查一下系统下是否安装了vim-enhanced包，查询命令为：
$rpm –q vim-enhanced

### 5.1.2 中文编码

vim编码方面的基础知识：

**1. 存在3个变量**

encoding—-该选项使用于缓冲的文本(你正在编辑的文件)，寄存器，Vim 脚本文件等等。你可以把 ‘encoding’ 选项当作是对 Vim 内部运行机制的设定。
fileencoding—-该选项是vim写入文件时采用的编码类型。
termencoding—-该选项代表输出到客户终端（Term）采用的编码类型。

**2.此3个变量的默认值**

encoding—-与系统当前locale相同，所以编辑文件的时候要考虑当前locale，否则要设置的东西就比较多了。
fileencoding—-vim打开文件时自动辨认其编码，fileencoding就为辨认的值。为空则保存文件时采用encoding的编码，如果没有修改encoding，那值就是系统当前locale了。
termencoding—-默认空值，也就是输出到终端不进行编码转换。
由此可见，编辑不同编码文件需要注意的地方不仅仅是这3个变量，还有系统当前locale和、文件本身编码以及自动编码识别、客户运行vim的终端所使用的编码类型3个关键点，这3个关键点影响着3个变量的设定。
如果有人问：为什么我用vim打开中文文档的时候出现乱码？
答案是不确定的，原因上面已经讲了，不搞清楚这3个关键点和这3个变量的设定值，出现乱码是正常的，倒是不出现乱码那反倒是凑巧的。

再来看一下常见情况下这三个关键点的值以及在这种情况下这3个变量的值：

- locale—-目前大部分Linux系统已经将utf-8作为默认locale了，不过也有可能不是，例如有些系统使用中文locale zh_CN.GB18030。在locale为utf-8的情况下，启动vim后encoding将会设置为utf-8，这是兼容性最好的方式，因为内部 处理使用utf-8的话，无论外部存储编码为何都可以进行无缺损转换。locale决定了vim内部处理数据的编码，也就是encoding。

- 文件的编码以及自动编码识别—-这方面牵扯到各种编码的规则，就不一一细讲了。但需要明白的是，文件编码类型并不是保存在文件内的，也就是说没有任何 描述性的字段来记录文档是何种编码类型的。因此我们在编辑文档的时候，要么必须知道这文档保存时是以什么编码保存的，要么通过另外的一些手段来断定编码类 型，这另外的手段，就是通过某些编码的码表特征来断定，例如每个字符占用的字节数，每个字符的ascii值是否都大于某个字段来断定这个文件属于何种编 码。这种方式vim也使用了，这就是vim的自动编码识别机制了。但这种机制由于编码各式各样，不可能每种编码都有显著的特征来辨别，所以是不可能 100%准确的。对于我们GB2312编码，由于其中文是使用了2个acsii值高于127的字符组成汉字字符的，因此不可能把gb2312编码的文件与 latin1编码区分开来，因此自动识别编码的机制对于gb2312是不成功的，它只会将文件辨识为latin1编码。此问题同样出现在gbk，big5 上等。因此我们在编辑此类文档时，需要手工设定encoding和fileencoding。如果文档编码为utf-8时，一般vim都能自动识别正确的 编码。

- 客户运行vim的终端所使用的编码类型—-同第二条一样，这也是一个比较难以断定的关键点。第二个关键点决定着从文件读取内容和写入内容到文件 时使用的编码，而此关键点则决定vim输出内容到终端时使用的编码，如果此编码类型和终端认为它收到的数据的编码类型不同，则又会产生乱码问题。在 linux本地X环境下，一般终端都认为其接收的数据的编码类型和系统locale类型相符，因此不需关心此方面是否存在问题。但如果牵涉到远程终端，例 如ssh登录服务器，则问题就有可能出现了。例如从1台locale为GB2310的系统（称作客户机）ssh到locale为utf-8的系统（称作服 务器）并开启vim编辑文档，在不加任何改动的情况下，服务器返回的数据为utf-8的，但客户机认为服务器返回的数据是gb2312的，按照 gb2312来解释数据，则肯定就是乱码了，这时就需要设置termencoding为gb2312来解决这个问题。此问题更多出现在我们的 windows desktop机远程ssh登录服务器的情况下，这里牵扯到不同系统的编码转换问题。所以又与windows本身以及ssh客户端有很大相关性。在 windows下存在两种编码类型的软件，一种是本身就为unicode编码方式编写的软件，一种是ansi软件，也就是程序处理数据直接采用字节流，不 关心编码。前一种程序可以在任何语言的windows上正确显示多国语言，而后一种则编写在何种语言的系统上则只能在何种语言的系统上显示正确的文字。对 于这两种类型的程序，我们需要区别对待。以ssh客户端为例，我们使用的putty是unicode软件，而secure CRT则是ansi 软件。对于前者，我们要正确处理中文，只要保证vim输出到终端的编码为utf-8即可，就是termencoding=utf-8。但对于后者，一方面 我们要确认我们的windows系统默认代码页为cp936（中文windows默认值），另一方面要确认vim设置的termencoding=cp936。

**最后来看看处理中文文档最典型的几种情况和设置方式：**  

- 系统locale是utf-8（很多linux系统默认的locale形式），编辑的文档是GB2312或GBK形式的（Windows记事本 默认保存形式，大部分编辑器也默认保存为这个形式，所以最常见），终端类型utf-8（也就是假定客户端是putty类的unicode软件）
则vim打开文档后，encoding=utf-8（locale决定的），fileencoding=latin1（自动编码判断机制不准导致的），termencoding=空（默认无需转换term编码），显示文件为乱码。
解决方案1：首先要修正fileencoding为cp936或者euc-cn（二者一样的，只不过叫法不同），注意修正的方法不是:set fileencoding=cp936，这只是将文件保存为cp936，正确的方法是重新以cp936的编码方式加载文件为:edit ++enc=cp936，可以简写为:e ++enc=cp936。
解决方案2：临时改变vim运行的locale环境，方法是以LANG=zh_CN vim abc.txt的方式来启动vim，则此时encoding=euc-cn（locale决定的），fileencoding=空（此locale下文件 编码自动判别功能不启用，所以fileencoding为文件本身编码方式不变，也就是euc-cn），termencoding=空（默认值，为空则等 于encoding）此时还是乱码的，因为我们的ssh终端认为接受的数据为utf-8，但vim发送数据为euc-cn，所以还是不对。此时再用命令: set termencoding=utf-8将终端数据输出为utf-8，则显示正常。

- 情况与1基本相同，只是使用的ssh软件为secure CRT类ansi类软件。
vim打开文档后，encoding=utf-8（locale决定的），fileencoding=latin1（自动编码判断机制不准导致的），termencoding=空（默认无需转换term编码），显示文件为乱码。
解决方案1：首先要保证运行secure CRT的windows机器的默认代码页为CP936，这一点中文windows已经是默认设置了。其他的与上面方案1相同，只是要增加一步，:set termencoding=cp936
解决方案2：与上面方案2类似，不过最后一步修改termencoding省略即可，在此情况下需要的修改最少，只要以locale为zh_CN开 启vim，则encoding=euc-cn，fileencoding和termencoding都为空即为encoding的值，是最理想的一种情 况。
可见理解这3个关键点和3个参数的意义，对于编码问题有很大助力，以后就可以随心所欲的处理文档了，同时不仅仅是应用于vim，在其他需要编码转换的环境里，都可以应用类似的思路来处理问题解决问题。
最后推荐一款功能强大的windows下的ssh客户端—-xshell，它具有类似secure CRT一样的多tab 的ssh窗口的能力，但最为方便的是这款工具还有改变Term编码的功能，这样我们就可以不用频繁调整termencoding，只需在ssh软件里切换 编码即可，这是我用过的最为方便的ssh工具。它是商业软件，但非注册用户使用没有任何限制，只是30天试用期超出后会每次启动都提示注册，对于功能没有 丝毫影响。

**备注**：  
最后看到ubuntu中文站上一个完美解决的方法：在.vimrc加两句设置
"设定文件编码类型，彻底解决中文编码问题 
let &termencoding=&encoding 
set fileencodings=utf-8,gbk,ucs-bom,cp936 
加上发现没有作用，那就是vim的哪个包没有安装，试试把包安完全一些。

### 5.1.3 参考资料

- vim的完全翻译版在下面连接处可以找到

	http://vimcdoc.sourceforge.net/  
	可以下栽其中的一个PDF版本，里面介绍的很详细，强烈推荐：）

- 更详细的vim信息可以访问：

	http://www.vim.org/

- 一个带有英文注释的.vimrc例子  
	http://www.vi-improved.org/vimrc.php  
	此文讲解的是vim编辑多字节编码文档（中文）所要了解的一些基础知识，注意其没有涉及gvim，纯指字符终端下的vim。
