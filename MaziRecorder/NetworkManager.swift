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
    private let urlString = "http://192.168.72.2/api"
    private let errorDomain = "MaziNetworkingError"
    private let timeoutInterval : NSTimeInterval = 15
    private let uploadTimeoutInterval : NSTimeInterval = 60
    
    typealias ResponseDict = [String: AnyObject]
    
    // Returns a SignalProducer that emits the interview's id on the backend (or an error).
    func sendInterviewToServer(interview: Interview) -> SignalProducer<String, NSError> {
        // Create producer for sending the interview to the server.
        let interviewDict : ResponseDict = ["name": interview.name, "role": interview.role, "text": interview.text]
        return requestProducer(.POST, URLString: "\(urlString)/interviews", parameters: interviewDict)
            .flatMap(.Concat) { next -> SignalProducer<String, NSError> in
                // Get the id; if that's not possible, send an error.
                guard let interviewId = next["_id"] as? String else {
                    return SignalProducer(error: NSError(domain: self.errorDomain, code: 0, userInfo: nil))
                }
                
                let (producer, observer) = SignalProducer<SignalProducer<ResponseDict, NSError>, NSError>.buffer(1 + interview.attachments.count)
                
                // Create producer for uploading the photo to the server.
                if let imageURL = interview.imageUrl {
                    let uploadImageProducer = self.uploadProducer(.POST, URLString: "\(self.urlString)/upload/image/\(interviewId)", fileURL: imageURL, mimeType: "image/jpeg")
                    observer.sendNext(uploadImageProducer)
                }
                
                // Create producers for sending the attachments (and then the recordings) to the server.
                interview.attachments.forEach { attachment in
                    let attachmentDict : ResponseDict = ["text": attachment.questionText, "tags": attachment.tags, "interview": interviewId]
                    let attachmentProducer = self.requestProducer(.POST, URLString: "\(self.urlString)/attachments", parameters: attachmentDict)
                        .flatMap(.Concat) { next -> SignalProducer<ResponseDict, NSError> in
                            // Get the attachment id; if that's not possible, send an error.
                            guard let attachmentId = next["_id"] as? String else {
                                return SignalProducer(error: NSError(domain: self.errorDomain, code: 1, userInfo: nil))
                            }
                            
                            // Create producer for uploading the attachment's recording to the server.
                            return self.uploadProducer(.POST, URLString: "\(self.urlString)/upload/attachment/\(attachmentId)", fileURL: attachment.recordingUrl, mimeType: "audio/wav")
                    }
                    observer.sendNext(attachmentProducer)
                }
                
                observer.sendCompleted()
                
                return producer.flatten(.Concat).map { _ in return interviewId }
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
                        observer.sendFailed(NSError(domain: self.errorDomain, code: 100, userInfo: nil))
                    }
            }
        })
            .timeoutWithError(NSError(domain: self.errorDomain, code: 200, userInfo: nil), afterInterval: self.timeoutInterval, onScheduler: QueueScheduler())
    }
    
    private func uploadProducer(method: Alamofire.Method, URLString: URLStringConvertible, fileURL: NSURL, mimeType: String) -> SignalProducer<ResponseDict, NSError> {
        let (producer, observer) = SignalProducer<ResponseDict, NSError>.buffer(1)
        
        return producer.on(started: {
            Alamofire.upload(method, URLString, multipartFormData: { multipartFormData in
                if let data = NSData(contentsOfURL: fileURL) {
                    multipartFormData.appendBodyPart(data: data, name: "file", fileName: fileURL.lastPathComponent ?? "", mimeType: mimeType)
                }
                }, encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .Success(let upload, _, _):
                        upload.responseString { response in
                            debugPrint(response)
                            switch response.result {
                            case .Success:
                                observer.sendNext(ResponseDict())
                                observer.sendCompleted()
                            case .Failure(let error):
                                observer.sendFailed(error ?? NSError(domain: self.errorDomain, code: 101, userInfo: nil))
                            }
                        }
                    case .Failure(let encodingError):
                        print(encodingError)
                    }
            })
        })
            .timeoutWithError(NSError(domain: self.errorDomain, code: 201, userInfo: nil), afterInterval: self.uploadTimeoutInterval, onScheduler: QueueScheduler())
    }
}