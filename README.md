# QiWebSocket
A websocket demo(Client &amp; Server). The client is written in swift and the server is written in Golang.




>**本篇将介绍以下内容：  
1、什么是`WebSocket`？   
2、`WebSocket`使用场景  
3、`WebSocket`底层原理（协议）  
4、`iOS`中`WebSocket`的相关框架  
5、使用`Starscream`（`Swift`）完成长链需求（ 客户端 ）  
6、使用`Golang`完成长链需求（ 服务端 ）**

---

### 一、什么是 WebSocket ？

**WebSocket = “HTTP第1次握手” + `TCP`的“全双工“通信 的网络协议。**

主要过程：
- 首先，通过`HTTP`第一次握手保证连接成功。
- 其次，再通过`TCP`实现浏览器与服务器全双工(`full-duplex`)通信。（通过不断发`ping`包、`pang`包保持心跳）

最终，使得 **“服务端”** 拥有 **“主动”** 发消息给 **“客户端”** 的能力。

这里有几个重点：

1. `WebSocket`是基于`TCP`的上部应用层网络协议。
2. 它依赖于`HTTP`的第一次握手成功 + 之后的`TCP`双向通信。

---

### 二、WebSocket 应用场景

#### 1. IM（即时通讯）

典型例子：微信、QQ等
当然，用户量如果非常大的话，仅仅依靠`WebSocket`肯定是不够的，各大厂应该也有自己的一些优化的方案与措施。但对于用户量不是很大的即时通讯需求，使用`WebSocket`是一种不错的方案。

#### 2. 游戏（多人对战）

典型例子：王者荣耀等（应该都玩过）

#### 3. 协同编辑（共享文档）

多人同时编辑同一份文档时，可以实时看到对方的操作。
这时，就用上了`WebSocket`。

#### 4. 直播/视频聊天

对音频/视频需要较高的实时性。

#### 5. 股票/基金等金融交易平台

对于股票/基金的交易来说，每一秒的价格可能都会发生变化。

#### 6. IoT（物联网 / 智能家居）

例如，我们的App需要实时的获取智能设备的数据与状态。
这时，就需要用到`WebSocket`。

......
等等等等

只要是一些对 **“实时性”** 要求比较高的需求，可能就会用到`WebSocket`。


---


### 三、WebSocket 底层原理

`WebSocket`是一个网络上的应用层协议，它依赖于`HTTP`协议的第一次握手，握手成功后，数据就通过`TCP/IP`协议传输了。

`WebSocket`分为握手阶段和数据传输阶段，即进行了`HTTP`一次握手 + 双工的`TCP`连接。

#### 1、握手阶段

首先，客户端发送消息：（本例是：用`Golang`编写的本地服务）

```http
GET /chat HTTP/1.1
Host: 127.0.0.1:8000
Origin: ws://127.0.0.1:8000
Qi-WebSocket-Version: 0.0.1
Sec-WebSocket-Version: 13
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: aGFjb2hlYW9rd2JtdmV5eA==
```

然后，服务端返回消息：（本例是：用`swift`编写的客户端接收）

```swift
"Upgrade": "websocket", 
"Connection": "Upgrade", 
"Sec-WebSocket-Accept": "NO+pj7z0cvnNj//mlwRuAnCYqCE="
```

这里值得注意的是`Sec-WebSocket-Accept`的计算方法：
`base64(hsa1(sec-websocket-key + 258EAFA5-E914-47DA-95CA-C5AB0DC85B11))`

- 如果这个`Sec-WebSocket-Accept`计算错误，浏览器会提示：`Sec-WebSocket-Accept dismatch`；
- 如果返回成功，`Websocket`就会回调`onopen`事件


#### 2、传输阶段

`WebSocket`是以 **`frame`** 的形式传输数据的。
比如会将一条消息分为几个`frame`，按照先后顺序传输出去。

这样做会有几个好处：
- 较大的数据可以**分片传输**，不用考虑到数据大小导致的长度标志位不足够的情况。
- 和`HTTP`的`chunk`一样，可以边生成数据边传递消息，即提高传输效率。

`WebSocket`传输过程使用的报文，如下所示：

```html
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 +-+-+-+-+-------+-+-------------+-------------------------------+
 |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
 |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
 |N|V|V|V|       |S|             |   (if payload len==126/127)   |
 | |1|2|3|       |K|             |                               |
 +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
 |     Extended payload length continued, if payload len == 127  |
 + - - - - - - - - - - - - - - - +-------------------------------+
 |                               |Masking-key, if MASK set to 1  |
 +-------------------------------+-------------------------------+
 | Masking-key (continued)       |          Payload Data         |
 +-------------------------------- - - - - - - - - - - - - - - - +
 :                     Payload Data continued ...                :
 + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
 |                     Payload Data continued ...                |
 +---------------------------------------------------------------+
```

具体的参数说明如下：

- **FIN（1 bit）：**
表示信息的最后一帧，flag，也就是标记符。
PS：当然第一个消息片断也可能是最后的一个消息片断；

- **RSV1、RSV2、RSV3（均为1 bit）：**
默认均为0。如果有约定自定义协议则不为0，一般均为0。（协议扩展用）

- **Opcode（4 bit）：**
定义有效负载数据，如果收到了一个未知的操作码，连接也必须断掉，以下是定义的操作码：

操作码 | 含义
---|---
%x0 | 连续消息片断
%x1 | 文本消息片断
%x2 | 二进制消息片断
%x3-7 | （预留位）为将来的非控制消息片断保留的操作码。
%x8 | 连接关闭
%x9 | 心跳检查ping
%xA | 心跳检查pong
%xB-F | （预留位）为将来的控制消息片断的保留操作码。

- **Mask（1 bit）：**
是否传输数据添加掩码。
若为1，掩码必须放在masking-key区域。（后面会提到..）
注：客户端给服务端发消息`Mask`值均为`1`。

- **Payload length：**
Payload字段用来存储传输数据的长度。

本身Payload报文字段的大小可能有三种情况：`7 bit`、`7+16 bit`、`7+64 bit`。

第一种：`7 bit`，表示从`0000000` ~ `1111101`（即`0`~`125`），表示当前数据的length大小（较小数据，最大长度为125）。

第二种：`(7+16) bit`：前7位为`1111110（即126）`，`126`代表后面会跟着2个字节无符号数，用来存储数据length大小（长度最小126，最大为65 535）。

第三种：`(7+64) bit`：前7位为`1111111（即127）`，`127`代表后面会跟着8个字节无符号数，用来存储数据length大小（长度最小为65536，最大为2^16-1）。

Payload报文长度 | 所传输的数据大小区间
----|----
7 bit | [ 0, 125]
7 +16 bit | [ 126 , 65535]
7 + 64 bit | [ 65536, 2^16 -1]

![](https://user-gold-cdn.xitu.io/2020/2/10/1702f12dacfa5f35?w=992&h=738&f=jpeg&s=68548)


>说明：  
传输数据的长度，以字节的形式表示：7位、7+16位、或者7+64位。  
1）如果这个值以字节表示是0-125这个范围，那这个值就表示传输数据的长度；  
2）如果这个值是126，则随后的2个字节表示的是一个16进制无符号数，用来表示传输数据的长度；  
3）如果这个值是127，则随后的是8个字节表示的一个64位无符号数，这个数用来表示传输数据的长度。


- **Masking-key（0 bit / 4 bit）：**
`0 bit`：说明mask值不为`1`，无掩码。
`4 bit`：说明mask值为`1`，添加掩码。
>PS：客户端发送给服务端数据时，`mask`均为1。
同时，`Masking-key`会存储一个32位的掩码。

- **Payload data（x+y byte）：**
负载数据为扩展数据及应用数据长度之和。

- **Extension data（x byte）：**
如果客户端与服务端之间没有特殊约定，那么扩展数据的长度始终为0，任何的扩展都必须指定扩展数据的长度，或者长度的计算方式，以及在握手时如何确定正确的握手方式。如果存在扩展数据，则扩展数据就会包括在负载数据的长度之内。

- **Application data（y byte）：**
任意的应用数据，放在扩展数据之后。
`应用数据的长度 = 负载数据的长度 - 扩展数据的长度`
即：`Application data = Payload data - Extension data`

---

### 四、iOS 中 WebSocket 相关框架

##### WebSocket（iOS客户端）：

- [Starscream（swift）](https://github.com/daltoniam/Starscream)：
Websockets in swift for iOS and OSX.（`star 5k+`）

- [SocketRocket（objective-c）](https://github.com/facebook/SocketRocket)：
A conforming Objective-C WebSocket client library.（`star：8k+`）

- [SwiftWebSocket（swift）](https://github.com/tidwall/SwiftWebSocket)：
Fast Websockets in Swift for iOS and OSX.（`star：1k+`）

##### Socket（iOS客户端）：

- [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)：
Asynchronous socket networking library for Mac and iOS.（`star：11k+`）

- [socket.io-client-swift](https://github.com/socketio/socket.io-client-swift)：
Socket.IO-client for iOS/OS X.（`star：4k+`）

---

### 五、使用Starscream（swift）完成客户端长链需求

首先附上Starscream：[GitHub地址](https://github.com/daltoniam/Starscream)

#### 第一步：将`Starsream`导入到项目。

打开`Podfile`，加上：
```ruby
pod 'Starscream', '~> 4.0.0'
```

接着`pod install`。

#### 第二步：实现WebSocket能力。

- 导入头文件，`import Starscream`

- 初始化`WebSocket`，把一些请求头包装一下（与服务端对好）

```swift
private func initWebSocket() {
    // 包装请求头
    var request = URLRequest(url: URL(string: "ws://127.0.0.1:8000/chat")!)
    request.timeoutInterval = 5 // Sets the timeout for the connection
    request.setValue("some message", forHTTPHeaderField: "Qi-WebSocket-Header")
    request.setValue("some message", forHTTPHeaderField: "Qi-WebSocket-Protocol")
    request.setValue("0.0.1", forHTTPHeaderField: "Qi-WebSocket-Version")
    request.setValue("some message", forHTTPHeaderField: "Qi-WebSocket-Protocol-2")
    socketManager = WebSocket(request: request)
    socketManager?.delegate = self
}
```

同时，我用三个Button的点击事件，分别模拟了connect（连接）、write（通信）、disconnect（断开）。

```swift
    // Mark - Actions
    // 连接
    @objc func connetButtonClicked() {
        socketManager?.connect()
    }
    // 通信
    @objc func sendButtonClicked() {
        socketManager?.write(string: "some message.")
    }
    // 断开
    @objc func closeButtonCliked() {
        socketManager?.disconnect()
    }
```

#### 第三步：实现WebSocket回调方法（接收服务端消息）

遵守并实现`WebSocketDelegate`。

```swift
extension ViewController: WebSocketDelegate {
    // 通信（与服务端协商好）
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viablityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
            // ...处理异常错误
            print("Received data: \(String(describing: error))")
        }
    }
}
```

分别对应的是：

```swift
public enum WebSocketEvent {
    case connected([String: String])  //!< 连接成功
    case disconnected(String, UInt16) //!< 连接断开
    case text(String)                 //!< string通信
    case binary(Data)                 //!< data通信
    case pong(Data?)                  //!< 处理pong包（保活）
    case ping(Data?)                  //!< 处理ping包（保活）
    case error(Error?)                //!< 错误
    case viablityChanged(Bool)        //!< 可行性改变
    case reconnectSuggested(Bool)     //!< 重新连接
    case cancelled                    //!< 已取消
}
```

这样一个简单的客户端`WebSocket demo`就算完成了。

- 客户端成功，日志截图：

![](https://user-gold-cdn.xitu.io/2020/2/13/1703d8bda4ec3284?w=1162&h=362&f=jpeg&s=59651)

---

### 六、使用Golang完成简单服务端长链需求

仅仅有客户端也无法验证`WebSocket`的能力。  
因此，接下来我们用`Golang`简单做一个本地的服务端`WebSocket`服务。

>PS：最近，正好在学习`Golang`，参考了一些大神的作品。

直接上代码了：

```go
package main

import (
	"crypto/sha1"
	"encoding/base64"
	"errors"
	"io"
	"log"
	"net"
	"strings"
)

func main() {
	ln, err := net.Listen("tcp", ":8000")
	if err != nil {
		log.Panic(err)
	}
	for {
		log.Println("wss")
		conn, err := ln.Accept()
		if err != nil {
			log.Println("Accept err:", err)
		}
		for {
			handleConnection(conn)
		}
	}
}

func handleConnection(conn net.Conn) {
	content := make([]byte, 1024)
	_, err := conn.Read(content)
	log.Println(string(content))
	if err != nil {
		log.Println(err)
	}
	isHttp := false
	// 先暂时这么判断
	if string(content[0:3]) == "GET" {
		isHttp = true
	}
	log.Println("isHttp:", isHttp)
	if isHttp {
		headers := parseHandshake(string(content))
		log.Println("headers", headers)
		secWebsocketKey := headers["Sec-WebSocket-Key"]
		// NOTE：这里省略其他的验证
		guid := "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
		// 计算Sec-WebSocket-Accept
		h := sha1.New()
		log.Println("accept raw:", secWebsocketKey+guid)
		io.WriteString(h, secWebsocketKey+guid)
		accept := make([]byte, 28)
		base64.StdEncoding.Encode(accept, h.Sum(nil))
		log.Println(string(accept))
		response := "HTTP/1.1 101 Switching Protocols\r\n"
		response = response + "Sec-WebSocket-Accept: " + string(accept) + "\r\n"
		response = response + "Connection: Upgrade\r\n"
		response = response + "Upgrade: websocket\r\n\r\n"
		log.Println("response:", response)
		if lenth, err := conn.Write([]byte(response)); err != nil {
			log.Println(err)
		} else {
			log.Println("send len:", lenth)
		}
		wssocket := NewWsSocket(conn)
		for {
			data, err := wssocket.ReadIframe()
			if err != nil {
				log.Println("readIframe err:", err)
			}
			log.Println("read data:", string(data))
			err = wssocket.SendIframe([]byte("good"))
			if err != nil {
				log.Println("sendIframe err:", err)
			}
			log.Println("send data")
		}
	} else {
		log.Println(string(content))
		// 直接读取
	}
}

type WsSocket struct {
	MaskingKey []byte
	Conn       net.Conn
}

func NewWsSocket(conn net.Conn) *WsSocket {
	return &WsSocket{Conn: conn}
}

func (this *WsSocket) SendIframe(data []byte) error {
	// 这里只处理data长度<125的
	if len(data) >= 125 {
		return errors.New("send iframe data error")
	}
	lenth := len(data)
	maskedData := make([]byte, lenth)
	for i := 0; i < lenth; i++ {
		if this.MaskingKey != nil {
			maskedData[i] = data[i] ^ this.MaskingKey[i%4]
		} else {
			maskedData[i] = data[i]
		}
	}
	this.Conn.Write([]byte{0x81})
	var payLenByte byte
	if this.MaskingKey != nil && len(this.MaskingKey) != 4 {
		payLenByte = byte(0x80) | byte(lenth)
		this.Conn.Write([]byte{payLenByte})
		this.Conn.Write(this.MaskingKey)
	} else {
		payLenByte = byte(0x00) | byte(lenth)
		this.Conn.Write([]byte{payLenByte})
	}
	this.Conn.Write(data)
	return nil
}

func (this *WsSocket) ReadIframe() (data []byte, err error) {
	err = nil
	//第一个字节：FIN + RSV1-3 + OPCODE
	opcodeByte := make([]byte, 1)
	this.Conn.Read(opcodeByte)
	FIN := opcodeByte[0] >> 7
	RSV1 := opcodeByte[0] >> 6 & 1
	RSV2 := opcodeByte[0] >> 5 & 1
	RSV3 := opcodeByte[0] >> 4 & 1
	OPCODE := opcodeByte[0] & 15
	log.Println(RSV1, RSV2, RSV3, OPCODE)

	payloadLenByte := make([]byte, 1)
	this.Conn.Read(payloadLenByte)
	payloadLen := int(payloadLenByte[0] & 0x7F)
	mask := payloadLenByte[0] >> 7
	if payloadLen == 127 {
		extendedByte := make([]byte, 8)
		this.Conn.Read(extendedByte)
	}
	maskingByte := make([]byte, 4)
	if mask == 1 {
		this.Conn.Read(maskingByte)
		this.MaskingKey = maskingByte
	}

	payloadDataByte := make([]byte, payloadLen)
	this.Conn.Read(payloadDataByte)
	log.Println("data:", payloadDataByte)
	dataByte := make([]byte, payloadLen)
	for i := 0; i < payloadLen; i++ {
		if mask == 1 {
			dataByte[i] = payloadDataByte[i] ^ maskingByte[i%4]
		} else {
			dataByte[i] = payloadDataByte[i]
		}
	}
	if FIN == 1 {
		data = dataByte
		return
	}
	nextData, err := this.ReadIframe()
	if err != nil {
		return
	}
	data = append(data, nextData...)
	return
}

func parseHandshake(content string) map[string]string {
	headers := make(map[string]string, 10)
	lines := strings.Split(content, "\r\n")
	for _, line := range lines {
		if len(line) >= 0 {
			words := strings.Split(line, ":")
			if len(words) == 2 {
				headers[strings.Trim(words[0], " ")] = strings.Trim(words[1], " ")
			}
		}
	}
	return headers
}
```

完成后，在本地执行：
```vim
go run WebSocket_demo.go
```
即可开启本地服务。

这时候访问`ws://127.0.0.1:8000/chat`接口，即可调用长链服务。

- 服务端，成功日志截图：

![](https://user-gold-cdn.xitu.io/2020/2/13/1703d8bddf8728ad?w=1240&h=346&f=jpeg&s=73997)
