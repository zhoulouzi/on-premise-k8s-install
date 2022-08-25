# This a project for sre to build a kubernetes cluster with kubeadmin in china
# 如何创建一个集群
# step to create a kubernetes cluster
1. 申请机器：
例如机器规格：

按照sre要求初始化

etcd机器：  4c8g            512GB HDD * 1 - /apps (初始化)
master机器：8c16g           512GB HDD * 1 - /apps (初始化)
node机器    16c32g(或者更大) 512GB HDD * 1 - /apps (初始化)

2. 申请slb：

私有云： 采用自建slb的方案
本安装包自带lvs-dr+keepalived 模式的4层负载均衡 安装办法

期提前按照yaml跑好

阿里云：
apiserver： 内网slb  6443 到 master机器 6443

申请一个域名供api-server使用，先解析到第一个master节点，待所有master节点初始化完毕，切换到apiserver 的 slb
    这里说下为什么，阿里云slb缺陷，加上kubeadm启动集群的机制，导致需要一个域名来做操作
没有想到特别好的办法绕过去

3. 在 cluster 目录新建 集群目录（集群名称）
创建 hosts 文件 并编辑相关信息 （参考sre-kubernetes 集群）

4. 在跳板机 执行脚本命令：
cd /root/zhouzichen/torres/setup

# 生成 etcd ssl证书
ansible-playbook -i ../cluster/sre-kubernetes/hosts 1.etcd-tls.yaml

# 安装 etcd
ansible-playbook -i ../cluster/sre-kubernetes/hosts 2.etcd.yaml

# 检测 etcd 集群状态
ansible-playbook -i ../cluster/sre-kubernetes/hosts 3.etcd-check.yaml

# 给kubernetes节点装docker kubeadm kubelet kubectl 初始化配置
ansible-playbook -i ../cluster/sre-kubernetes/hosts 4.kubernetes.yaml

# 启动第一个master节点
ansible-playbook -i ../cluster/sre-kubernetes/hosts 5.master-start.yaml

# 在一个节点执行
kubeadm init --config /etc/kubernetes/init/kubeadm-config.yaml --upload-certs --v=5
# 加入其他master节点
kubeadm join sre-kubernetes.example.com:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:fb5b7da34f112860a0ce3de9786ac59fb5942bff2f4f762f82da80e244a01e51 \
    --control-plane --certificate-key 485f07bd01e024aecd1e6bce5ca49211129e1d96d1d9d9aacd402a4e66a9ae80
# 加入其他node节点cd
kubeadm join sre-kubernetes.example.com.com:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:fb5b7da34f112860a0ce3de9786ac59fb5942bff2f4f762f82da80e244a01e51
# kubeadm 配置文件可以在master机器找到 /etc/kubernetes/admin.config

# 回收 admin 配置
ansible -i ../cluster/sre-kubernetes/hosts kube-master-start -m fetch -a "src=/etc/kubernetes/admin.conf dest=/root/zhouzichen/torres/cluster/sre-kubernetes/admin.conf flat=yes"

# 打 label 标签
ansible-playbook -i ../cluster/sre-kubernetes/hosts 6.label.yaml

# 请移步 torres-9 项目安装插件

5. 扩容node节点步骤

    修改hosts文件  添加 new-node组 成员

    ansible-playbook -i ../cluster/sre-kubernetes/hosts 7.add-nodes.yaml

	 master 节点执行：
	 kubeadm token create --print-join-command

	 拿到命令 在node节点执行