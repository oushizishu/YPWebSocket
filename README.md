# YPWebSocket

[![CI Status](http://img.shields.io/travis/oushizishu/YPWebSocket.svg?style=flat)](https://travis-ci.org/oushizishu/YPWebSocket)
[![Version](https://img.shields.io/cocoapods/v/YPWebSocket.svg?style=flat)](http://cocoapods.org/pods/YPWebSocket)
[![License](https://img.shields.io/cocoapods/l/YPWebSocket.svg?style=flat)](http://cocoapods.org/pods/YPWebSocket)
[![Platform](https://img.shields.io/cocoapods/p/YPWebSocket.svg?style=flat)](http://cocoapods.org/pods/YPWebSocket)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

YPWebSocket is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "YPWebSocket"
```

### 0.3.0

1. 由于原来底层 `WebSocket` 库不稳定，基于 [`PocketSocket`](https://github.com/zwopple/PocketSocket) 重新实现，仍然支持 `permessage-deflate`；

2. 只保留一个类 `BJWebSocketBase`，继承自 `NSObject`，底层实现不再对外暴露；

3. 发送消息支持数据类型 `String`、`Dictionary`、`Data`，BJWebSocketBase 根据 `requestType` 参数或属性转换数据格式 `text`（默认）、`binary`，IM、直播都使用 `text`；

```objc
// 支持数据类型 NSString、NSDictionary、NSData
- (BOOL)sendRequest:(id)request;
- (BOOL)sendRequest:(id)request requestType:(BJ_WS_RequestType)requestType;
```

4. 设置接收消息数据类型 `Auto`（默认）、`String`、`Dictionary`、`Data`，BJWebSocketBase 根据 `responseType` 属性回调对应方法；

```objc
@property (nonatomic) BJ_WS_ResponseType responseType; // 默认 text
// 每个消息只会回调下面方法中的一个
- (void)onResponseWithString:(NSString *)response;
- (void)onResponseWithDictionary:(NSDictionary *)response;
- (void)onResponseWithData:(NSData *)response;
```

5. `onReconnect` 改名为 `onWillReconnect`，表明此方法是在即将 `reconnect` 时调用；

Note: `FaceBook` 出品的更知名的 [`SocketRocket`](https://github.com/facebook/SocketRocket) 目前不支持 `permessage-deflate`，暂时不用；


## Author

oushizishu, xinyapeng@baijiahulian.com

## License

YPWebSocket is available under the MIT license. See the LICENSE file for more info.
