//
//  ApiProvider.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

let defaultNetworkTimeoutInterval: TimeInterval = 30
let callBackQueue = DispatchQueue.main

let flatGenerator =  FlatRequestGenerator(host: Env().baseURL, timeoutInterval: defaultNetworkTimeoutInterval)
let flatResponseHandler = FlatResponseHandler()
let agoraGenerator = AgoraRequestGenerator(agoraAppId: Env().agoraAppId, timeoutInterval: defaultNetworkTimeoutInterval)
let agoraResponseHandler = AgoraResponseHandler()

class ApiProvider: NSObject {
    static let shared = ApiProvider()
    
    @discardableResult
    func request<T: FlatRequest>(fromApi api: T,
                             completionHandler: @escaping (Result<T.Response, ApiError>) -> Void
    ) -> URLSessionDataTask? {
        request(fromApi: api, generator: flatGenerator, responseDataHandler: flatResponseHandler, completionHandler: completionHandler)
    }
    
    @discardableResult
    func request<T: AgoraRequest>(fromApi api: T,
                             completionHandler: @escaping (Result<T.Response, ApiError>) -> Void
    ) -> URLSessionDataTask? {
        request(fromApi: api, generator: agoraGenerator, responseDataHandler: agoraResponseHandler, completionHandler: completionHandler)
    }
    
    @discardableResult
    func request<T: Request>(fromApi api: T,
                             generator: Generator,
                             responseDataHandler: ResponseDataHandler,
                             completionHandler: @escaping (Result<T.Response, ApiError>) -> Void
    ) -> URLSessionDataTask? {
        do {
            let req = try generator.generateRequest(fromApi: api)
            let task = session.dataTask(with: req) { data, response, error in
                if let error = error {
                    callBackQueue.async {
                        completionHandler(.failure(.message(message: error.localizedDescription)))
                    }
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    callBackQueue.async {
                        completionHandler(.failure(.unknown))
                    }
                    return
                }
                guard response.statusCode == 200 else {
                    callBackQueue.async {
                        let msg = String(data: data ?? Data(), encoding: .utf8) ?? ""
                        completionHandler(.failure(.message(message: "error statusCode \(response.statusCode), \(msg)")))
                    }
                    return
                }
                guard let data = data else {
                    callBackQueue.async {
                        completionHandler(.failure(.decode(message: "no data")))
                    }
                    return
                }
                do {
                    let result = try responseDataHandler.processResponseData(data, decoder: api.decoder, forResponseType: T.Response.self)
                    callBackQueue.async {
                        completionHandler(.success(result))
                    }
                }
                catch {
                    callBackQueue.async {
                        print(error)
                        completionHandler(.failure(.decode(message: error.localizedDescription)))
                    }
                }
            }
            task.resume()
            return task
        }
        catch {
            print(error)
            completionHandler(.failure((error as? ApiError) ?? .unknown))
            return nil
        }
    }
    
    fileprivate lazy var session = URLSession(configuration: .default)
}
