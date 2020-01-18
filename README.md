# PingDemo


## 简介

1. ping用于确定本地主机是否能与另一台主机成功交换(发送与接收)数据包，再根据返回的信息，就可以推断TCP/IP参数是否设置正确，以及运行是否正常、网络是否通畅等。

    - 通过将ICMP(Internet控制消息协议)回显数据包发送到计算机并侦听回显回复数据包来验证与一台或多台远程计算机的连接
    
    - 每个发送的数据包最多等待一秒
    
    - 打印已传输和接收的数据包数
    
> 需要注意的是，Ping成功并不一定就代表TCP/IP配置正确，有可能还要执行大量的本地主机与远程主机的数据包交换，才能确信TCP/IP配置的正确性。如果执行ping成功而网络仍无法使用，那么问题很可能出在网络系统的软件配置方面，ping成功只保证当前主机与目的主机间存在一条连通的物理路径。

## 如何使用SimplePing



## 终端

1. 打开终端，输入`ping域名`

2. 如果想要停止的话，组合键:`control+c`

## Mac自带"网络使用工具"

1. `Spotlight`搜索"网络使用工具"

2. 选择"ping页面"

## 参考资料
 [苹果ping官方Demo](https://developer.apple.com/library/archive/samplecode/SimplePing/Listings/Common_SimplePing_m.html#//apple_ref/doc/uid/DTS10000716-Common_SimplePing_m-DontLinkElementID_4)
 
  [CFNetWork框架详解](https://www.jianshu.com/p/e9d29d142a5c)
  
  [CFSocket](https://www.jianshu.com/p/9353105a9129)
  [ICMP](https://baike.baidu.com/item/ICMP/572452)
  [Ping](https://baike.baidu.com/item/ping/6235?fr=aladdin)
  [SimplePing源码详解](https://dongqihouse.github.io/2018/09/11/ping/)
