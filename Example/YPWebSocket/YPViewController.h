//
//  YPViewController.h
//  YPWebSocket
//
//  Created by oushizishu on 06/17/2017.
//  Copyright (c) 2017 oushizishu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YPViewController : UIViewController

- (void)syncConfig;

- (void)start;

- (void)stop;

//- (void)postMessage:(IMMessage *)message;

- (void)postPullRequest:(int64_t)max_user_msg_id
        excludeUserMsgs:(NSString *)excludeUserMsgs
       groupsLastMsgIds:(NSString *)group_last_msg_ids
           currentGroup:(int64_t)groupId;

@end
