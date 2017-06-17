//
//  YPWebSocketBase.m
//  Pods
//
//  Created by 辛亚鹏 on 2017/6/17.
//
//

#import <PocketSocket/PSWebSocket.h>

#import "YPWebSocketBase.h"

#if defined(__OPTIMIZE__)
#define NSLog(fmt, ...) {}
#endif


static inline void dispatch_sync_main_queue(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@interface YPWebSocketBase() <PSWebSocketDelegate>

@property (nonatomic, strong) PSWebSocket *ws;
@property (nonatomic, readwrite) YPWSConnectState state;

@property (nonatomic, assign) NSInteger backupAddrIndex;
@property (nonatomic, strong, readwrite) NSMutableArray *requestQueue;

@end

@implementation YPWebSocketBase

- (instancetype)init {
    return [self initWithIpAddr:nil];
}

- (instancetype)initWithIpAddr:(NSString *)ipAddr {
    return [self initWithIpAddr:ipAddr port:0];
}

- (instancetype)initWithIpAddr:(NSString *)ipAddr port:(NSUInteger)port {
    self = [super init];
    if (self) {
        self.wsServerAddress = ipAddr;
        self.wsServerPort = port;
        self.timeoutInterval = - 1.0;
        _requestQueue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSString *)getCurrentIpAddress {
    return [self getCurrentIpAddressWithIpAddr:self.wsServerAddress port:self.wsServerPort];
}

- (NSString *)getCurrentIpAddressWithIpAddr:(NSString *)ipAddr port:(NSUInteger)port {
    if (!ipAddr) {
        return nil;
    }
    if (![ipAddr hasPrefix:@"ws:"]
        && ![ipAddr hasPrefix:@"wss:"]) {
        ipAddr = [@"ws://" stringByAppendingString:ipAddr];
    }
    return (port > 0
            ? [NSString stringWithFormat:@"%@:%tu", ipAddr, port]
            : [NSString stringWithFormat:@"%@", ipAddr]);
}

- (void)connect {
    NSString *urlString = [self getCurrentIpAddress];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    if (self.timeoutInterval >= 0) {
        request.timeoutInterval = self.timeoutInterval;
    }
    self.ws = [PSWebSocket clientSocketWithRequest:request];
    self.ws.delegateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    self.ws.delegate = self;
    
    [self.ws open];
    [self updateState:YP_WS_STATE_Connecting notifyChange:YES];
    
    NSLog(@"\n************ %@ 发起连接 \nip: %@\n************",
          NSStringFromClass([self class]),
          [self getCurrentIpAddress]);
}

- (void)disconnect {
    [self.ws closeWithCode:PSWebSocketStatusCodeNormal reason:nil];
    
    NSLog(@"\n************ %@ 关闭连接\nip: %@\n************",
          NSStringFromClass([self class]),
          [self getCurrentIpAddress]);
}

- (void)reconnect {
    dispatch_sync_main_queue(^{
        [self onWillReconnect];
    });
    NSLog(@"\n************ %@ 重新连接\nip: %@\n************",
          NSStringFromClass([self class]),
          [self getCurrentIpAddress]);
    
    [self disconnect];
    [self connect];
}

- (BOOL)sendRequest:(id)request {
    return [self sendRequest:request requestType:self.requestType];
}

- (BOOL)sendRequest:(id)request requestType:(YP_WS_RequestType)requestType {
    NSLog(@"\n************ %@ 发起请求\nrequest: %@\n************",
          NSStringFromClass([self class]),
          request);
    
    if (self.state != YP_WS_STATE_Connected) {
        [_requestQueue addObject:request];
        return NO;
    }
    
    @autoreleasepool {
        id message = request;
        
        if ([message isKindOfClass:[NSDictionary class]]) {
            message = [NSJSONSerialization dataWithJSONObject:message
                                                      options:0 // NSJSONWritingPrettyPrinted
                                                        error:nil];
        }
        
        if ([message isKindOfClass:[NSData class]]) {
            if (requestType == YP_WS_RequestType_Text) {
                message = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
            }
            /* if (!((NSString *)request).length) {
             request = nil;
             } */
        }
        else if ([message isKindOfClass:[NSString class]]) {
            if (requestType == YP_WS_RequestType_Binary) {
                message = [message dataUsingEncoding:NSUTF8StringEncoding];
            }
            /* if (!((NSData *)request).length) {
             request = nil;
             } */
        }
        else {
            NSAssert(NO, @"Request must be NSString or NSData");
            return NO;
        }
        
        if (message) {
            [self.ws send:message];
        }
        else {
            return YES;
        }
    }
    
    BOOL suc = (self.state == YP_WS_STATE_Connected);
    if (!suc) {
        [_requestQueue addObject:request];
    }
    return suc;
}

- (void)onResponseWithString:(NSString *)response {
    NSLog(@"\n************ %@ 返回数据\nresponse: %@\n************",
          NSStringFromClass([self class]),
          response);
}

- (void)onResponseWithDictionary:(NSDictionary *)response {
    NSLog(@"\n************ %@ 返回数据\nresponse: %@\n************",
          NSStringFromClass([self class]),
          response);
}

- (void)onResponseWithData:(NSData *)response {
    NSLog(@"\n************ %@ 返回数据\nresponse: %@\n************",
          NSStringFromClass([self class]),
          response);
}

- (void)onStateChanged:(YPWSConnectState)state {
    if (state != YP_WS_STATE_Connected) return;
    
    // 连接成功后处理缓存任务
    NSInteger count = [self.requestQueue count];
    while (count > 0) {
        if ([self.requestQueue count] > 0) {
            id request = [self.requestQueue objectAtIndex:0];
            [self.requestQueue removeObjectAtIndex:0];
            [self sendRequest:request];
        }
        else {
            break;
        }
        count--;
    }
}

- (void)onWillReconnect {
}

- (void)onWillDisconnectWithCode:(YPWSDisconnectCode)code {
}

- (void)onDisconnectWithCode:(YPWSDisconnectCode)code {
}

#pragma mark - getter & setter

/* - (BJWSConnectState)state {
 switch (self.ws.readyState) {
 case PSWebSocketReadyStateConnecting:
 return BJ_WS_STATE_Connecting;
 case PSWebSocketReadyStateOpen:
 return BJ_WS_STATE_Connected;
 case PSWebSocketReadyStateClosing:
 return BJ_WS_STATE_Offline;
 case PSWebSocketReadyStateClosed:
 return BJ_WS_STATE_Offline;
 default:
 return BJ_WS_STATE_Offline;
 }
 } */

- (void)updateState:(YPWSConnectState)state notifyChange:(BOOL)notifyChange {
    dispatch_sync_main_queue(^{
        if (state != self.state) {
            self.state = state;
            if (notifyChange) {
                [self onStateChanged:self.state];
            }
        }
    });
}

#pragma mark - <PSWebSocketDelegate>

- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    if (self.responseType == YP_WS_ResponseType_String
        || (self.responseType == YP_WS_ResponseType_Auto && [message isKindOfClass:[NSString class]])) {
        NSString *string = nil;
        if ([message isKindOfClass:[NSString class]]) {
            string = message;
        }
        else if ([message isKindOfClass:[NSData class]]) {
            string = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
        }
        
        if (string) {
            [self onResponseWithString:string];
        }
        else {
            NSLog(@"\n************ %@ 返回数据解析失败 - text\nresponse: %@\n************",
                  NSStringFromClass([self class]),
                  message);
        }
    }
    else {
        NSData *data = nil;
        if ([message isKindOfClass:[NSString class]]) {
            data = [message dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([message isKindOfClass:[NSData class]]) {
            data = message;
        }
        
        if (self.responseType == YP_WS_ResponseType_Dictionary) {
            NSError *error = nil;
            NSDictionary *json = data ? [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] : nil;
            if (json) {
                [self onResponseWithDictionary:json];
            }
            else {
                NSLog(@"\n************ %@ 返回数据解析失败 - json\nresponse: %@\n************",
                      NSStringFromClass([self class]),
                      message);
            }
        }
        else {
            if (data) {
                [self onResponseWithData:data];
            }
            else {
                NSLog(@"\n************ %@ 返回数据解析失败 - data\nresponse: %@\n************",
                      NSStringFromClass([self class]),
                      message);
            }
        }
    }
}

- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
    NSLog(@"\n************ %@ 连接成功\nip: %@\n************",
          NSStringFromClass([self class]),
          [self getCurrentIpAddress]);
    
    [self updateState:YP_WS_STATE_Connected notifyChange:YES];
}

- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"\n************ %@ 连接失败\nip: %@\nerror: %@\n************",
          NSStringFromClass([self class]),
          [self getCurrentIpAddress],
          error);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reconnect) object:nil];
    
    [self onWillDisconnectWithCode:YP_WS_DisconnectCode_failedToConnect];
    [self updateState:YP_WS_STATE_Offline notifyChange:YES];
    [self onDisconnectWithCode:YP_WS_DisconnectCode_failedToConnect];
    
    if (self.autoReconnect) {
        [self performSelector:@selector(reconnect) withObject:nil afterDelay:1.0];
    }
}

- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"\n************ %@ 连接关闭\nip: %@\ncode: %td, reason: %@\n************",
          NSStringFromClass([self class]),
          [self getCurrentIpAddress],
          code,
          reason);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reconnect) object:nil];
    
    if (code == PSWebSocketStatusCodeNormal) {
        [self onWillDisconnectWithCode:YP_WS_DisconnectCode_disconnect];
        [self updateState:YP_WS_STATE_Offline notifyChange:NO];
        [self onDisconnectWithCode:YP_WS_DisconnectCode_disconnect];
    }
    else {
        [self onWillDisconnectWithCode:YP_WS_DisconnectCode_disconnect];
        [self updateState:YP_WS_STATE_Offline notifyChange:YES];
        [self onDisconnectWithCode:YP_WS_DisconnectCode_disconnected];
        
        if (self.autoReconnect) {
            [self performSelector:@selector(reconnect) withObject:nil afterDelay:1.0];
        }
    }
}



@end
