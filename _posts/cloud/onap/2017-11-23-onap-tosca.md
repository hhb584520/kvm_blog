# TOSCA 简介

http://qinghua.github.io/tosca/

TOSCA（Topology and Orchestration Specification for Cloud Applications）是由OASIS组织制定的云应用拓扑编排规范。通俗地说，就是制定了一个标准，用来描述云平台上应用的拓扑结构。目前支持XML和YAML，Cloudiy的蓝图就是基于这个规范而来。这个规范比较庞大，本文尽量浓缩了TOSCA的YAML版前两章，以便用尽量少的时间了解尽量多的规范内容。

## 1. 简介
TOSCA的基本概念只有两个：节点（node）和关系（relationship）。节点有许多类型，可以是一台服务器，一个网络，一个计算节点等等。关系描述了节点之间是如何连接的。举个栗子：一个nodejs应用（节点）部署在（关系）名为host的主机（节点）上。节点和关系都可以通过程序来扩展和实现。
目前它的开源实现有OpenStack (Heat-Translator，Tacker，Senlin)，Alien4Cloud，Cloudify等。

## 2. 示例
### 2.1 Hello World
首先登场的是广大程序猿和攻城狮们都喜闻乐见的Hello World，但是其实里面并没有Hello World，只是比较简单而已。先看下面这段描述文件：

	tosca_definitions_version: tosca_simple_yaml_1_0
	
	description: Template for deploying a single server with predefined properties.
	
	topology_template:
	  node_templates:
	    my_server:
	      type: tosca.nodes.Compute
	      capabilities:
	        host:
	          properties:
	            num_cpus: 1
	            disk_size: 10 GB
	            mem_size: 4096 MB
	        os:
	          properties:
	            architecture: x86_64
	            type: linux 
	            distribution: rhel 
	            version: 6.5 

除了TOSCA的版本tosca_definitions_version和描述信息description以外，就是这个topology_template了。这里我们看到有一个名为my_server的节点，它的类型是tosca.nodes.Compute。这个类型预置了两个capabilities信息，一个是host，定义了硬件信息；另一个是os，定义了操作系统信息。

## 3. 代码

**tosca parser**
https://github.com/openstack/tosca-parser