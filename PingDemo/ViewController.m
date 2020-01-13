//
//  ViewController.m
//  PingDemo
//
//  Created by 贺文杰 on 2020/1/13.
//  Copyright © 2020 贺文杰. All rights reserved.
//

#import "ViewController.h"
#import "SimplePing.h"

@interface ViewController ()<SimplePingDelegate>

@property(nonatomic,strong)SimplePing *ping;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)start:(BOOL)forceIPv4 forceIPv6:(BOOL)forceIPv6
{
    self.ping = [[SimplePing alloc] initWithHostName:@"www.apple.com"];
    
    if (forceIPv4 && !forceIPv6) {
        self.ping.addressStyle = SimplePingAddressStyleICMPv4;
    }else if (forceIPv6 && !forceIPv4){
        self.ping.addressStyle = SimplePingAddressStyleICMPv6;
    }
    
    self.ping.delegate = self;
    [self.ping start];
}

- (void)stop
{
    [self.ping stop];
    self.ping = nil;
}

#pragma mark -- SimplePingDelegate
/// ping启动后调用，如果没有启动成功则调用simplePing:didFailWithError:
/// @param pinger 发送的实例对象
/// @param address IP地址或者域名
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
    
}
    
/// 当发送失败时调用
/// @param pinger 发送的实例对象
/// @param error 错误信息
- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
{
    
}

/// 发送ping数据包时连续调用
/// @param pinger 发送的实例对象
/// @param packet 包含ICMP
/// @param sequenceNumber ICMP序列号
- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    
}

/// 发送数据包失败时调用
/// @param pinger 发送的实例对象
/// @param packet 没有发送的数据包
/// @param sequenceNumber 数据包中的ICMP序列号
/// @param error 错误信息
- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error
{
    
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
    
}


@end
