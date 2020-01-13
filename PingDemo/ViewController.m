//
//  ViewController.m
//  PingDemo
//
//  Created by 贺文杰 on 2020/1/13.
//  Copyright © 2020 贺文杰. All rights reserved.
//

#import "ViewController.h"
#import "SimplePing.h"
#include <netdb.h>

@interface ViewController ()<SimplePingDelegate>

@property(nonatomic,strong)SimplePing *ping;
@property(nonatomic)dispatch_source_t timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self start:NO forceIPv6:NO];
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
    self.ping = [[SimplePing alloc] initWithHostName:@"www.apple.com"];
    
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
    [self.ping stop];
    self.ping = nil;
    //暂停定时器
    dispatch_suspend(_timer);
    //取消定时器
    dispatch_source_cancel(_timer);
}

- (void)displayAddress:(NSData *)address
{
    char hostStr[NI_MAXHOST];
    
    NSAssert(address != nil, @"address is nil");
    int i = getnameinfo([address bytes], (socklen_t)[address length], hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
    if (i == 0) {
        NSLog(@"result = %@", [NSString stringWithCString:hostStr encoding:NSUTF8StringEncoding]);
    }
}

- (void)showError:(NSError *)error
{
    NSAssert(error != nil, @"error is nil");
    if ([error.domain isEqual:(__bridge NSString *)kCFErrorDomainCFNetwork] && error.code == kCFHostErrorUnknown) {
        NSLog(@"error.userInfo = %@", error.userInfo);
        NSNumber *addr = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
    }
    if (error.localizedFailureReason) {
        NSLog(@"error.localizedFailureReason = %@", error.localizedFailureReason);
    }
}

#pragma mark -- SimplePingDelegate
/// ping启动后调用，如果没有启动成功则调用simplePing:didFailWithError:
/// @param pinger 发送的实例对象
/// @param address IP地址或者域名
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
    [self displayAddress:address];
    [self gcdTimer];
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
    NSLog(@"#%u sent", sequenceNumber);
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
    NSLog(@"%s #%u", __FUNCTION__, sequenceNumber);
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
    NSLog(@"%s", __FUNCTION__);
}


@end
