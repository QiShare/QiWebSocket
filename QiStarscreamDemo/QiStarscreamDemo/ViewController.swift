//
//  ViewController.swift
//  QiStarscreamDemo
//
//  Created by 刘思齐 on 2020/2/10.
//  Copyright © 2020 刘思齐. All rights reserved.
//

import UIKit
import Starscream

class ViewController: UIViewController {
    
    var socketManager: WebSocket?
    var isConnected: Bool = false
    
    var connectButton: UIButton?
    var sendButton: UIButton?
    var closeButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initViews()
        initWebSocket()
    }
    
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
    
    private func initViews() {
        connectButton = UIButton(type: .system)
        connectButton?.setTitle("connect", for: .normal)
        connectButton?.frame = CGRect(x: 150, y: 200, width: 100, height: 36)
        self.view.addSubview(connectButton!)
        
        sendButton = UIButton(type: .system)
        sendButton?.setTitle("sendMessage", for: .normal)
        sendButton?.frame = CGRect(x: 150, y: 300, width: 100, height: 36)
        self.view.addSubview(sendButton!)
        
        closeButton = UIButton(type: .system)
        closeButton?.setTitle("close", for: .normal)
        closeButton?.frame = CGRect(x: 150, y: 400, width: 100, height: 36)
        self.view.addSubview(closeButton!)
        
        connectButton?.addTarget(self, action: #selector(connetButtonClicked), for: .touchUpInside)
        sendButton?.addTarget(self, action: #selector(sendButtonClicked), for: .touchUpInside)
        closeButton?.addTarget(self, action: #selector(closeButtonCliked), for: .touchUpInside)
    }
    
    
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
}

extension ViewController: WebSocketDelegate {
    // 处理服务端回调
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
