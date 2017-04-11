## 1. 栈的介绍 ##

**确定入栈顺序，如何求出不正确的出栈顺序**

-  找出数组中在 某个元素前面的所有元素。
-  从某个元素开始，寻找所有在在入栈顺序之前的元素。
-  与入栈元素对比，看是否顺序相同，如果全部相同，说明是正确的出栈顺序，否则就是错误的出栈顺序.

## 2. 散列 ##
### 2.1 定理 ###
   使用平方探测，且表的大小是素数，那么当表至少有一半是空的时候，总能够插入一个新的元素。

### 2.2 再散列  ###
   建立另外一个大约两倍大的表（而且使用一个相关的新散列函数），扫描整个原始散列表，计算每个元素的新散列值并将其插入到新表中。

### 2.3 hi(x) = (Hash(x) + F(i)) mod TableSize ###

### 2.4 双散列  ###
-  F(i) = i * hash2(x);
-  函数不要算的 0 值；
-  hash2(x) = R （X mod R)，其中R为小于 TableSize的素数。

## 3. 树 ##
### 3.1 树的遍历 ###
遍历分分先(前)序、中序、后序
先序：先访问根结点、左结点、右结点
中序：先访问左结点、根结点、右结点
后序：先访问左结点、右结点、根结点
﻿
利用堆栈实现中序排序，实现的文件见附件：tst.c
设计思路： 
 
首先，一直往左边搜索，一路压栈，直到左节点为空，当前节点为当前节点的左节点。
判断该节点右孩子是否为空，如果不为空，则打印出当前节点，并将其右节点压入堆栈，同时置标志位为1，表示需要搜索左节点；当前节点为当前节点的右节点。
否则，打印当前节点，当前节点等于弹出的栈的数据。
else
{
    printf("now=%d\n", now->data);
    if(sh->next != NULL)
        now = popStack(&sh);
    else
        now = NULL;

    flag = 0;
}

### 3.2 树的相关定义 ###
#### 深度　####
root-->node 叫深度，node --> 自身最低叶子节点， 叫高度

#### 伸展树 ####
伸展树是一种二叉排序树，它能在O(logn)内完成插入、查找和删除操作。它的优势在于不需要记录用于平衡树的冗余信息。

- 获得摊平效率的一种方法就是使用“自调整”的数据结构，自调整有以下优点：
所需空间更小
它们查找和更新算法概念简单，易于实现。
从摊平角度而言，它们忽略常量因子，因此绝对不会比有明确限制的数据结构差。而且由于它们可以根据使用情况进行调整，于是在使用模式不均匀的情况下更加有效。
- 缺点
它们需要更多的局部调整，尤其是在查找期间。
一系列查找操作中的某一个可能耗时较长，这在实时应用程序中可能是个不足之处。

# 4. 结构体打包技艺 #

![](/kvm_blog/img/structure_package.gif)

http://blog.csdn.net/21aspnet/article/details/6729724





 