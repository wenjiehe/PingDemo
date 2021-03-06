//
//  ViewController.m
//  PingDemo
//
//  Created by 贺文杰 on 2020/1/13.
//  Copyright © 2020 贺文杰. All rights reserved.
//

#import "ViewController.h"
#import "SimplePing.h"
#include <netdb.h> //为Unix和Linux特有的头文件，主要定义了与网络有关的结构、变量类型、宏、函数等
#import <CFNetwork/CFNetwork.h>

#define kTIME 0.5 //间隔时间


//以ping操作进行判断网络真实连接状态
@interface ViewController ()<SimplePingDelegate>

@property(nonatomic,strong)SimplePing *ping;
@property(nonatomic)dispatch_source_t timer;

@property(nonatomic)NSTimeInterval startTime; /**< 开始发送数据的时间 */
@property(nonatomic)NSTimeInterval delayTime; /**< 消耗的时间 */
@property(nonatomic,copy)NSString *ip; /**<  ip地址 */
@property(nonatomic)NSInteger sendPacketsIndex; /**< 发送出去的数据包计数 */
@property(nonatomic)NSInteger receivePacketsIndex; /**< 收到的数据包计数 */
@property(nonatomic)double packetLoss; /**< 丢包率 */
@property(nonatomic,strong)NSData *sendPacket; /**< 发送成功时的数据包 */
@property(nonatomic,strong)NSData *receivePacket; /**< 接收成功时的数据包 */
@property(nonatomic)uint16_t sendSeqNumber; /**< 记录发送数据包的序列号 */
@property(nonatomic)uint16_t receivedSeqNumber; /**< 记录收到数据包的序列号 */

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self start:YES forceIPv6:NO];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self stop];
}

- (void)gcdTimer
{
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), 1 * NSEC_PER_SEC, 5 * NSEC_PER_SEC);
    
    dispatch_source_set_event_handler(_timer, ^{
        //发送数据进行监测
        [self.ping sendPingWithData:nil];
    });
    //启动定时器
    dispatch_resume(_timer);
}

- (void)start:(BOOL)forceIPv4 forceIPv6:(BOOL)forceIPv6
{
    _startTime = 0;
    _delayTime = 0;
    _sendPacketsIndex = -1;
    _receivePacketsIndex = -1;

    self.ping = [[SimplePing alloc] initWithHostName:@"www.baidu.com"];
    
    if (forceIPv4 && !forceIPv6) {
        self.ping.addressStyle = SimplePingAddressStyleICMPv4;
    }else if (forceIPv6 && !forceIPv4){
        self.ping.addressStyle = SimplePingAddressStyleICMPv6;
    }else{
        self.ping.addressStyle = SimplePingAddressStyleAny;
    }
    
    self.ping.delegate = self;
    [self.ping start];
}

- (void)stop
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendTime) object:nil];
    [self.ping stop];
    self.ping = nil;
    if (_timer) {
        //暂停定时器
        dispatch_suspend(_timer);
        //取消定时器
        dispatch_source_cancel(_timer);
    }
}

- (void)displayAddress:(NSData *)address
{
    char hostStr[NI_MAXHOST];
    
    NSAssert(address != nil, @"address is nil");
    int i = getnameinfo([address bytes], (socklen_t)[address length], hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
    if (i == 0) {
        self.ip = [NSString stringWithCString:hostStr encoding:NSUTF8StringEncoding];
        NSLog(@"result = %@", self.ip);
    }
}

- (void)showError:(NSError *)error
{
    NSAssert(error != nil, @"error is nil");
    if ([error.domain isEqual:(__bridge NSString *)kCFErrorDomainCFNetwork] && error.code == kCFHostErrorUnknown) {
        NSNumber *addr = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
        NSLog(@"error.userInfo = %@, gai_strerror = %@", error.userInfo, [NSString stringWithUTF8String:gai_strerror(addr.intValue)]);
    }
    if (error.localizedFailureReason) {
        NSLog(@"error.localizedFailureReason = %@", error.localizedFailureReason);
    }
}

- (void)sendPing
{
    [self.ping sendPingWithData:nil];
}

#pragma mark -- SimplePingDelegate
/// ping启动后调用，如果没有启动成功则调用simplePing:didFailWithError:
/// @param pinger 发送的实例对象
/// @param address IP地址或者域名
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
    [self displayAddress:address];
//    [self gcdTimer];
    [self sendPing];
}
    
/// 当发送失败时调用
/// @param pinger 发送的实例对象
/// @param error 错误信息
- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
{
    [self showError:error];
    [self.ping stop];
}

/// 发送ping数据包成功时调用
/// @param pinger 发送的实例对象
/// @param packet 包含ICMP
/// @param sequenceNumber ICMP序列号
- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    _startTime = CFAbsoluteTimeGetCurrent();
    _sendPacketsIndex++;
    _sendPacket = packet;
    _sendSeqNumber = sequenceNumber;
    [self performSelector:@selector(sendTime) withObject:nil afterDelay:kTIME];
}

- (void)sendTime
{
    if (_delayTime < _startTime) {
        NSLog(@"Request timeout for icmp_seq %ld-%u", _sendPacketsIndex, _sendSeqNumber);
        
        [self performSelector:@selector(sendPing)];
    }else if (_delayTime == _startTime){
        NSLog(@"相等了想登陆");
    }else{
        NSTimeInterval time = (_delayTime - _startTime) * 1000;
        _packetLoss = (double)((_sendPacketsIndex - _receivePacketsIndex) * 1.f / _sendPacketsIndex * 100);
        //ip=ip地址,received=序列号,size=响应数据包的大小为64字节,time=请求往返耗时,loss=丢包率,_sendSeqNumber=发送序列号,_receivedSeqNumber=接收序列号
        NSLog(@"ip = %@，%ld send， size = %zu，time = %fms，loss = %.f%%, _sendSeqNumber = %u, _receivedSeqNumber = %u", self.ip, _sendPacketsIndex, self.receivePacket.length, time, _packetLoss, _sendSeqNumber, _receivedSeqNumber);
        [self performSelector:@selector(sendPing)];
    }
}

/// 发送数据包失败时调用
/// @param pinger 发送的实例对象
/// @param packet 没有发送的数据包
/// @param sequenceNumber 数据包中的ICMP序列号
/// @param error 错误信息
- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error
{
    [self showError:error];
    NSLog(@"#%u send failed %@", sequenceNumber, error);
}

/// 发送数据包之后收到响应
/// @param pinger 发送的实例对象
/// @param packet 发送的数据包
/// @param sequenceNumber 数据包中的ICMP序列号
- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    _receivePacketsIndex++;
    _delayTime = CFAbsoluteTimeGetCurrent();
    _receivedSeqNumber = sequenceNumber;
    self.receivePacket = packet;
    [self sendTime];
}

//收到未知的数据包
- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
    NSLog(@"%s", __FUNCTION__);
//    _receivePackets++;
//    _delayTime = CFAbsoluteTimeGetCurrent();
//    self.packet = packet;
//    [self sendTime];
}


@end
