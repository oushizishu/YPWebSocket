//
//  YPViewController.m
//  YPWebSocket
//
//  Created by oushizishu on 06/17/2017.
//  Copyright (c) 2017 oushizishu. All rights reserved.
//

#import "YPViewController.h"

#import <YPWebSocket/YPWebSocketBase.h>

@interface BJIMSocketBase : YPWebSocketBase

@end

@implementation BJIMSocketBase

- (void)onWillDisconnectWithCode:(YPWSDisconnectCode)code {
    if (code == YP_WS_DisconnectCode_failedToConnect) {
        if (self.wsServerPort == 0) {
            self.wsServerPort = 8887;
        }else {
            self.wsServerPort = 0;
        }
    }
}

@end

#pragma mark -

@interface YPViewController ()
{
    NSTimeInterval _receiveMessageNewTime; // 用于标识收到 messageNew 信号的时间。 屏蔽调同时收到大量的 messageNew 信号
}

@property (nonatomic, strong) NSMutableDictionary *requestQueue;
@property (nonatomic, assign) NSInteger retryConnectCount;
@property (nonatomic, copy) NSString *device;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, nonnull, strong) BJIMSocketBase *webSocketClient;
//@property (nonatomic, strong) RACDisposable *heartBeatDispose;
//@property (nonatomic, strong) TimeOutTaskQueue *sendMsgQueue;
//@property (nonatomic, strong) TimeOutTaskQueue *sendMsgResponseQueue; //发消息响应线程

@end

@implementation YPViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
//        WS(weakSelf);
//        [[RACObserve(self, retryConnectCount) distinctUntilChanged] subscribeNext:^(id x) {
//            [weakSelf checkNetworkEfficiency];
//        }];
//        
//        _sendMsgQueue = [[TimeOutTaskQueue alloc] init];
//        _sendMsgResponseQueue = [[TimeOutTaskQueue alloc] init];
//        _sendMsgResponseQueue.timeOutAtSeconds = 10;
    }
    return self;
}

- (void)syncConfig
{
//    __WeakSelf__ weakSelf = self;
//    [NetWorkTool hermesSyncConfig:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
//        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
//        if (result != nil && result.code == RESULT_CODE_SUCC)
//        {
//            NSError *error;
//            SyncConfigModel *model = [IMJSONAdapter modelOfClass:[SyncConfigModel class] fromJSONDictionary:result.dictionaryData error:&error];
//            [weakSelf.syncConfigDelegate onSyncConfig:model];
//        }
//        else
//        {
//            DDLogWarn(@"Sync Config Fail [url:%@][params:%@]", params.url, params.urlPostParams);
//            [self callbackErrorCode:result.code errMsg:result.msg];
//        }
//    } failure:^(NSError *error, BJCNRequestParams *params) {
//        DDLogError(@"Sync Config Fail [%@]", error.userInfo);
//    }];
}

- (void)start
{
    [self.webSocketClient connect];
    
//    self.device = [NSUserDefaults deviceString];
//    self.token = [NSString stringWithFormat:@"%@Hermes%lld%ld", self.device, [IMEnvironment shareInstance].owner.userId, (long)[IMEnvironment shareInstance].owner.userRole];
//    self.token = [self.token bjcf_stringFromMD5];
    
    [self doLogin];
}

- (void)stop
{
    [self.webSocketClient disconnect];
//    self.engineActive = NO;
}

- (NSString *)URLEncodedString:(NSString*)str
{
    __autoreleasing NSString *encodedString;
    NSString *originalString = (NSString *)str;
    encodedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                          NULL,
                                                                                          (__bridge CFStringRef)originalString,
                                                                                          NULL,
                                                                                          (CFStringRef)@":!*();@/&?#[]+$,='%’\"",
                                                                                          kCFStringEncodingUTF8
                                                                                          );
    return encodedString;
}

//- (void)postMessage:(IMMessage *)message
//{
//    if (! [[IMEnvironment shareInstance] isLogin]) return;
//    [message.msgStatictis markStartSendServer];
//    
//    WS(weakSelf);
//    TimeOutTask *task = [[TimeOutTask alloc] initWithRun:^{
//        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
//        [dic setObject:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
//        [dic setObject:[weakSelf URLEncodedString:[NSString stringWithFormat:@"%lld", message.sender]] forKey:@"sender"];
//        [dic setObject:[weakSelf URLEncodedString:[NSString stringWithFormat:@"%ld", (long)message.senderRole]] forKey:@"sender_r"];
//        [dic setObject:[weakSelf URLEncodedString:[NSString stringWithFormat:@"%lld", message.receiver]] forKey:@"receiver"];
//        [dic setObject:[weakSelf URLEncodedString:[NSString stringWithFormat:@"%ld", (long)message.receiverRole]] forKey:@"receiver_r"];
//        [dic setObject:[weakSelf URLEncodedString:[message.messageBody description]] forKey:@"body"];
//        if (message.ext)
//        {
//            NSString *ext = [message.ext jsonString];
//            if (ext)
//                [dic setObject:[weakSelf URLEncodedString:ext] forKey:@"ext"];
//        }
//        [dic setObject:[weakSelf URLEncodedString:[NSString stringWithFormat:@"%ld", (long)message.chat_t]] forKey:@"chat_t"];
//        [dic setObject:[weakSelf URLEncodedString:[NSString stringWithFormat:@"%ld", (long)message.msg_t]] forKey:@"msg_t"];
//        [dic setObject:message.sign forKey:@"sign"];
//        [dic setObject:[weakSelf URLEncodedString:[[IMEnvironment shareInstance] getCurrentVersion]] forKey:@"im_version"];
//        
//        NSString *uuid = [weakSelf uuidString];
//        
//        NSDictionary *data = [weakSelf construct_req_param:dic messageType:SOCKET_API_REQUEST_MESSAGE_SEND sign:uuid];
//        
//        [weakSelf.webSocketClient sendRequest:data];
//        
//        RequestItem *item = [[RequestItem alloc] initWithRequestPostMessage:message];
//        [weakSelf.requestQueue setObject:item forKey:uuid];
//        
//        // 检查消息发送回执
//        TimeOutTask *responseCheckTask = [[TimeOutTask alloc] initWithRun:^{
//        } timeOut:^{
//            RequestItem *_item = [weakSelf.requestQueue objectForKey:uuid];
//            if (_item) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSError *error = [NSError bjim_errorWithReason:@"网络连接超时，请稍后重试" code:-2];
//                    [weakSelf.postMessageDelegate onPostMessageFail:_item.message error:error];
//                });
//                
//                [_item.message.msgStatictis markFinishSendWithResult:NO];
//                [_item.message.msgStatictis printMessageStatictis];
//                [weakSelf.requestQueue removeObjectForKey:uuid];
//            }
//        }];
//        [weakSelf.sendMsgResponseQueue offerTask:responseCheckTask];
//    } timeOut:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSError *error = [NSError bjim_errorWithReason:@"网络连接超时，请稍后重试" code:-2];
//            [weakSelf.postMessageDelegate onPostMessageFail:message error:error];
//        });
//        [message.msgStatictis markFinishSendWithResult:NO];
//        [message.msgStatictis printMessageStatictis];
//        
//    }];
//    
//    [self.sendMsgQueue offerTask:task];
//}

- (void)postPullRequest:(int64_t)max_user_msg_id
        excludeUserMsgs:(NSString *)excludeUserMsgs
       groupsLastMsgIds:(NSString *)group_last_msg_ids
           currentGroup:(int64_t)groupId
{
//    _receiveMessageNewTime = 0;
//    if (![[IMEnvironment shareInstance] isLogin]) return;
//    
//    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
//    [dic setObject:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
//    [dic setObject:[NSString stringWithFormat:@"%lld", max_user_msg_id] forKey:@"user_last_msg_id"];
//    [dic setObject:[self URLEncodedString:[[IMEnvironment shareInstance] getCurrentVersion]] forKey:@"im_version"];
//    if ([group_last_msg_ids length] > 0)
//    {
//        [dic setObject:group_last_msg_ids forKey:@"groups_last_msg_id"];
//    }
//    if (groupId > 0)
//    {
//        [dic setObject:[NSString stringWithFormat:@"%lld", groupId] forKey:@"current_group_id"];
//    }
//    
//    if ([excludeUserMsgs length] > 0)
//    {
//        [dic setObject:excludeUserMsgs forKey:@"exclude_msg_ids"];
//    }
//    
//    NSString *uuid = [self uuidString];
//    NSDictionary *data = [self construct_req_param:dic messageType:SOCKET_API_REQUEST_MESSAGE_PULL sign:uuid];
//    [self.webSocketClient sendRequest:data];
//    // 所有请求都需要临时缓存起来
//    RequestItem *item = [[RequestItem alloc] initWithRequestPullMessage];
//    [self.requestQueue setObject:item forKey:uuid];
}

- (void)didReciveMessage:(NSDictionary *)result
{
//    if (! self.isEngineActive) return;
//    if (!result) return;
//    
//    NSString *messageType = [result objectForKey:@"message_type"];
//    NSString *sign = [result objectForKey:@"sign"];
//    NSString *response = [result objectForKey:@"response"];
//    
//    if ([messageType isEqualToString:SOCKET_API_RESPONSE_LOGIN])
//    { // 登陆成功回调
//        // 每次登陆完成后，拉一次消息。
//        [self.pollingDelegate onShouldStartPolling];
//    }
//    else if ([messageType isEqualToString:SOCKET_API_RESPONSE_HEART_BEAT])
//    { // 心跳回调
//        self.engineActive = YES;
//    }
//    else if ([messageType isEqualToString:SOCKET_API_RESPONSE_MESSAGE_PULL])
//    { // 拉消息回调
//        [self dealPullMessage:[response jsonValue] sign:sign];
//    }
//    else if ([messageType isEqualToString:SOCKET_API_RESPONSE_MESSAGE_SEND])
//    { // 发消息回调
//        [self dealPostMessage:[response jsonValue] sign:sign];
//    }
//    else if ([messageType isEqualToString:SOCKET_API_RESPONSE_MESSAGE_NEW])
//    { // 有新消息
//        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
//        if (_receiveMessageNewTime == 0 || (currentTime - _receiveMessageNewTime) > 5) { // 保险起见， 5s 内如果标志位都没有置回来，则可以继续发送
//            _receiveMessageNewTime = currentTime;
//            [self.pollingDelegate onShouldStartPolling];
//        }
//    }
    
}

- (void)dealPostMessage:(NSDictionary *)response sign:(NSString *)uuid
{
//    NSError *error;
//    BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
//    RequestItem *item = [self.requestQueue objectForKey:uuid];
//    if (!item) return; // 已经超时了
//    if (result && result.code == RESULT_CODE_SUCC)
//    {
//        SendMsgModel *model = [IMJSONAdapter modelOfClass:[SendMsgModel class] fromJSONDictionary:result.data error:&error];
//        
//        [self.postMessageDelegate onPostMessageSucc:item.message result:model];
//        [item.message.msgStatictis markFinishSendWithResult:YES];
//    }
//    else
//    {
//        [self callbackErrorCode:result.code errMsg:result.msg];
//        NSError *error = [NSError bjim_errorWithReason:result.msg code:result.code];
//        [self.postMessageDelegate onPostMessageFail:item.message error:error];
//        [item.message.msgStatictis markFinishSendWithResult:NO];
//    }
//    
//    [item.message.msgStatictis printMessageStatictis];
//    [self.requestQueue removeObjectForKey:uuid];
}

- (void)dealPullMessage:(NSDictionary *)response sign:(NSString *)uuid
{
//    NSError *error;
//    BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
//    if (result && result.code == RESULT_CODE_SUCC)
//    {
//        PollingResultModel *model = [IMJSONAdapter modelOfClass:[PollingResultModel class] fromJSONDictionary:result.data error:&error];
//        [self.pollingDelegate onPollingFinish:model];
//    }
//    else
//    {
//        [self callbackErrorCode:result.code errMsg:result.msg];
//    }
//    
//    // 从缓存中清除请求
//    [self.requestQueue removeObjectForKey:uuid];
}

/**
 *  发送心跳
 */
-  (void)doHeartbeat
{
    NSDictionary *data = [self construct_heart_beat];
    [self.webSocketClient sendRequest:data];
}

/**
 *  发起重连
 */
- (void)reconnect
{
//    if (!self.engineActive) return;
    [self.webSocketClient performSelector:@selector(reconnect) withObject:nil afterDelay:2];
    [self performSelector:@selector(doLogin) withObject:nil afterDelay:2];
    //    if (self.retryConnectCount > COUNT_SOCKET_MAX_RECONNECT)
    //    { //重连了五次没有成功
    //        DDLogError(@"BJIMSocketEngine 多次重练失败！！！！！！");
    //
    //        [self stop];
    //        return;// 重连了5次还没有成功，不再重连了
    //    }
    //
    //    self.retryConnectCount ++ ;
    
    //    [self stop];
    //    [self start];
}

- (void)checkNetworkEfficiency
{
//    if (self.retryConnectCount > COUNT_SOCKET_MAX_RECONNECT && [self.networkEfficiencyDelegate respondsToSelector:@selector(networkEfficiencyChanged:engine:)])
//    {
//        [self.networkEfficiencyDelegate networkEfficiencyChanged:IMNetwork_Efficiency_Low engine:self];
//    }
}

- (void)cancelAllRequest
{
//    NSArray *array = [self.requestQueue allValues];
//    
//    for (NSInteger index = 0; index < array.count; ++ index)
//    {
//        RequestItem *item = [array objectAtIndex:index];
//        if ([item.requestType isEqualToString:SOCKET_API_REQUEST_MESSAGE_SEND])
//        {
//            [self.postMessageDelegate onPostMessageFail:item.message error:[NSError bjim_errorWithReason:@"网络异常" code:404]];
//        }
//        else if ([item.requestType isEqualToString:SOCKET_API_REQUEST_MESSAGE_PULL])
//        {
//            [self.pollingDelegate onPollingFinish:nil];
//        }
//    }
//    
//    [self.requestQueue removeAllObjects];
    
}

- (void)doLogin
{
//    NSDictionary *data = [self construct_login_req];
//    [self.webSocketClient sendRequest:data];
//    self.engineActive = YES;
//    self.retryConnectCount = 0; // 连上之后标志位重置
}

#pragma mark construct data
- (NSDictionary *)construct_login_req
{
    NSDictionary *dic = @{
//                          @"message_type":SOCKET_API_REQUEST_LOGIN,
//                          @"user_number":[NSString stringWithFormat:@"%lld", [IMEnvironment shareInstance].owner.userId],
//                          @"user_role":[NSString stringWithFormat:@"%ld", (long)[IMEnvironment shareInstance].owner.userRole],
//                          @"device":self.device,
//                          @"token":self.token,
//                          @"end_type":@(eEndType_iPhone),
//                          @"im_version":[[IMEnvironment shareInstance] getCurrentVersion]
                          };
    
    return dic;
}

- (NSDictionary *)construct_heart_beat
{
    NSDictionary *dic = @{
//                          @"message_type":SOCKET_API_REQUEST_HEART_BEAT,
//                          @"user_number":[NSString stringWithFormat:@"%lld", [IMEnvironment shareInstance].owner.userId],
//                          @"user_role":[NSString stringWithFormat:@"%ld", (long)[IMEnvironment shareInstance].owner.userRole],
//                          @"token":self.token,
//                          @"end_type":@(eEndType_iPhone),
//                          @"im_version":[[IMEnvironment shareInstance] getCurrentVersion]
                          };
    return dic;
}

- (NSDictionary *)construct_req_param:(NSDictionary *)params messageType:(NSString *)messageType sign:(NSString *)uuid
{
    NSDictionary *dic = @{
//                          @"message_type":messageType,
//                          @"user_number":[NSString stringWithFormat:@"%lld", [IMEnvironment shareInstance].owner.userId],
//                          @"user_role":[NSString stringWithFormat:@"%ld", (long)[IMEnvironment shareInstance].owner.userRole],
//                          @"param":[params socketParamsString],
//                          @"sign":uuid,
//                          @"token":self.token,
//                          @"end_type":@(eEndType_iPhone),
//                          @"im_version":[[IMEnvironment shareInstance] getCurrentVersion]
                          };
    return dic;
}

- (NSString *)uuidString
{
    double time = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%lf", time];
}

- (NSMutableDictionary *)requestQueue
{
    if (_requestQueue == nil)
    {
        _requestQueue = [[NSMutableDictionary alloc] init];
    }
    return _requestQueue;
}

- (BJIMSocketBase *)webSocketClient
{
    if (_webSocketClient == nil) {
        _webSocketClient = [[BJIMSocketBase alloc] initWithIpAddr:@"SOCKET_HOST"];
        _webSocketClient.responseType = YP_WS_ResponseType_Dictionary;
        
        // 心跳
        /*
        WS(weakSelf);
        [[RACObserve(_webSocketClient, state) distinctUntilChanged] subscribeNext:^(id x) {
            [weakSelf.heartBeatDispose dispose];
            
            weakSelf.sendMsgQueue.execEnable = (weakSelf.webSocketClient.state == BJ_WS_STATE_Connected);
            
            if (weakSelf.webSocketClient.state == BJ_WS_STATE_Connected) {
                //TODO send message.
                weakSelf.heartBeatDispose = [[RACSignal interval:120 onScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] subscribeNext:^(id x) {
                    [weakSelf doHeartbeat];
                    NSDictionary *hackMessageNew = @{
                                                     @"message_type":SOCKET_API_RESPONSE_MESSAGE_NEW};
                    [weakSelf didReciveMessage:hackMessageNew];
                }];
            } else {
                // 重连
                if (weakSelf.webSocketClient.state == YP_WS_STATE_Offline) {
         */
         
                    /*
                     //增加逻辑: 重连的时候,循环用8887端口 和 8080端口不断尝试重连
                     BOOL useDefaultPort = [[NSUserDefaults standardUserDefaults] boolForKey:@"useDefaultPort"];
                     if (useDefaultPort) {
                     _webSocketClient.wsServerPort = 8080;
                     [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"useDefaultPort"];
                     [[NSUserDefaults standardUserDefaults] synchronize];
                     }
                     else {
                     _webSocketClient.wsServerPort = 8887;
                     [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"useDefaultPort"];
                     [[NSUserDefaults standardUserDefaults] synchronize];
                     }
                     */
        /*
                    [weakSelf reconnect];
                }
            }
        }];
         */
        //        [[_webSocketClient rac_signalForSelector:@selector(onWillReconnect)] subscribeNext:^(id x) {
        //            [weakSelf reconnect];
        //        }];
        
        /*
        [[[_webSocketClient rac_signalForSelector:@selector(onResponseWithDictionary:)] deliverOnMainThread]
         subscribeNext:^(RACTuple *tuple) {
             [weakSelf didReciveMessage:tuple.first];
         }];
         */
    }
    return _webSocketClient;
}



@end

