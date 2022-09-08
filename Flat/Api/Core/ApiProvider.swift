//
//  ApiProvider.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import RxSwift

let defaultNetworkTimeoutInterval: TimeInterval = 30
let callBackQueue = DispatchQueue.main
let rootQueue = DispatchQueue(label: "agora.io.flat.session.rootQueue")

let flatGenerator =  FlatRequestGenerator(host: Env().baseURL, timeoutInterval: defaultNetworkTimeoutInterval, sessionId: globalSessionId)
let flatResponseHandler = FlatResponseHandler()
let agoraGenerator = AgoraRequestGenerator(agoraAppId: Env().agoraAppId, timeoutInterval: defaultNetworkTimeoutInterval)
let agoraResponseHandler = AgoraResponseHandler()

class ApiProvider: NSObject {
    static let shared = ApiProvider()
    
    private override init() {
        super.init()
        // Disable network log
        URLSession.rx.shouldLogRequest = { _ in false }
    }
    
    func cancelAllTasks() {
        session.getAllTasks(completionHandler: {
            $0.forEach { $0.cancel() }
        })
    }
    
    func startEmptyRequestForWakingUpNetworkAlert() {
        var request = URLRequest(url: URL(string: "https://www.agora.io/")!)
        request.httpMethod = "HEADER"
        session.dataTask(with: request).resume()
    }
    
    @discardableResult
    func request<T: FlatRequest>(fromApi api: T) -> Observable<T.Response> {
        request(fromApi: api, generator: flatGenerator, responseDataHandler: flatResponseHandler)
    }
    
    @discardableResult
    func request<T: AgoraRequest>(fromApi api: T) -> Observable<T.Response> {
        request(fromApi: api, generator: agoraGenerator, responseDataHandler: agoraResponseHandler)
    }
    
    @discardableResult
    func request<T: FlatRequest>(fromApi api: T,
                             completionHandler: @escaping (Result<T.Response, ApiError>) -> Void
    ) -> URLSessionDataTask? {
        let task = request(fromApi: api, generator: flatGenerator, responseDataHandler: flatResponseHandler, completionHandler: completionHandler)
        task?.resume()
        return task
    }
    
    @discardableResult
    func request<T: AgoraRequest>(fromApi api: T,
                             completionHandler: @escaping (Result<T.Response, ApiError>) -> Void
    ) -> URLSessionDataTask? {
        let task = request(fromApi: api, generator: agoraGenerator, responseDataHandler: agoraResponseHandler, completionHandler: completionHandler)
        task?.resume()
        return task
    }
    
    @discardableResult
    func request<T: Request>(fromApi api: T,
                             generator: Generator,
                             responseDataHandler: ResponseDataHandler) -> Observable<T.Response> {
        var reqId: String!
        return generator
            .generateObservableRequest(fromApi: api)
            .do(onNext: {
                reqId = $0.value(forHTTPHeaderField: "x-request-id") ?? UUID().uuidString
                logger.trace("start rx \(String(describing: reqId)) \($0)") }
            )
            .flatMap {
                self.session.rx.data(request: $0)
            }
            .do(onNext: { logger.trace("raw rx \(String(describing: reqId)) \(String(data: $0, encoding: .utf8) ?? "")")})
            .flatMap {
                responseDataHandler.processObservableResponseData($0, decoder: api.decoder, forResponseType: T.Response.self)
            }
            .do(
                onNext: { obj in logger.trace("finish rx \(String(describing: reqId)) \(obj)") },
                onError: { error in logger.error("finish error rx \(String(describing: reqId)) \(error)")}
            )
            .subscribe(on: ConcurrentDispatchQueueScheduler(queue: rootQueue))
            .observe(on: SerialDispatchQueueScheduler(queue: callBackQueue, internalSerialQueueName: "io.agora.flat.session.callback"))
    }
    
    @discardableResult
    func request<T: Request>(fromApi api: T,
                             generator: Generator,
                             responseDataHandler: ResponseDataHandler,
                             completionHandler: @escaping (Result<T.Response, ApiError>) -> Void
    ) -> URLSessionDataTask? {
        do {
            let req = try generator.generateRequest(fromApi: api)
            let reqId = req.value(forHTTPHeaderField: "x-request-id") ?? UUID().uuidString
            logger.trace("start \(reqId) \(req)")
            let task = session.dataTask(with: req) { data, response, error in
                if let data = data {
                    logger.trace("raw data \(reqId) \(String(data: data, encoding: .utf8) ?? "")")
                } else if let error = error {
                    logger.trace("finish error \(reqId) \(error)")
                }
                
                if let error = error {
                    // Request was canceled
                    if (error as NSError).code == -999 {
                        return
                    }
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
                    logger.trace("finish \(result)")
                    callBackQueue.async {
                        completionHandler(.success(result))
                    }
                }
                catch {
                    callBackQueue.async {
                        logger.error("decode error \(error)")
                        completionHandler(.failure(.decode(message: error.localizedDescription)))
                    }
                }
            }
            return task
        }
        catch {
            logger.error("\(error)")
            completionHandler(.failure((error as? ApiError) ?? .unknown))
            return nil
        }
    }
    
    fileprivate lazy var session = URLSession(configuration: .default)
}
