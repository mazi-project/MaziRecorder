//
//  NetworkManager.swift
//  MaziRecorder
//
//  Created by Lutz on 09/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation
import Alamofire
import ReactiveCocoa
import enum Result.NoError

class NetworkManager {
    let url : String
    private let errorDomain = "MaziNetworkingError"
    
    init(url: String = "http://192.168.0.13:8881/api") {
        self.url = url
    }
    
    typealias ResponseDict = [String: AnyObject]
    
    // Returns a SignalProducer that emits the interview's id on the backend (or an error).
    func sendInterviewToServer(interview: Interview) -> SignalProducer<String, NSError> {
        // Create producer for sending the interview to the server.
        let interviewDict = ["name": interview.name, "role": interview.role, "text": interview.text]
        let sendInterviewProducer = requestProducer(.POST, URLString: "\(url)/interviews", parameters: interviewDict)
        
        return sendInterviewProducer.flatMap(.Concat) { next -> SignalProducer<String, NSError> in
            guard let id = next["_id"] as? String else {
                return SignalProducer(error: NSError(domain: self.errorDomain, code: 0, userInfo: nil))
            }
            
            return SignalProducer(value: id)
        }
    }
    
    private func requestProducer(method: Alamofire.Method, URLString: URLStringConvertible, parameters: ResponseDict) -> SignalProducer<ResponseDict, NSError> {
        let (producer, observer) = SignalProducer<ResponseDict, NSError>.buffer(1)
        
        return producer.on(started: {
            Alamofire.request(method, URLString, parameters: parameters, encoding: .JSON)
                .responseJSON { (response : Response<AnyObject, NSError>) in
                    debugPrint(response)
                    if let result = response.result.value as? ResponseDict {
                        observer.sendNext(result)
                        observer.sendCompleted()
                    } else {
                        observer.sendFailed(NSError(domain: self.errorDomain, code: 0, userInfo: nil))
                    }
            }
        })
    }
}