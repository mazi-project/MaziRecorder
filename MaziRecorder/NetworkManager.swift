//
//  NetworkManager.swift
//  MaziRecorder
//
//  Created by Lutz on 09/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation
import Alamofire
import ReactiveSwift
import ReactiveCocoa
import enum Result.NoError

class NetworkManager {
    fileprivate let urlString = "http://192.168.72.2/api"
    fileprivate let errorDomain = "MaziNetworkingError"
    fileprivate let timeoutInterval : TimeInterval = 15
    fileprivate let uploadTimeoutInterval : TimeInterval = 60
    
    typealias ResponseDict = [String: Any]
    
    // Returns a SignalProducer that emits the interview's id on the backend (or an error).
    func sendInterviewToServer(_ interview: Interview) -> SignalProducer<String, NSError> {
        // Create producer for sending the interview to the server.
        let interviewDict : ResponseDict = ["name": interview.name, "role": interview.role, "text": interview.text]
        return requestProducer("\(urlString)/interviews", parameters: interviewDict)
            .flatMap(.concat) { next -> SignalProducer<String, NSError> in
                // Get the id; if that's not possible, send an error.
                guard let interviewId = next["_id"] as? String else {
                    return SignalProducer(error: NSError(domain: self.errorDomain, code: 0, userInfo: nil))
                }
                
                let producer = SignalProducer<SignalProducer<ResponseDict, NSError>, NSError>.init { (observer, _) in
                    // Create producer for uploading the photo to the server.
                    if let imageURL = interview.imageUrl {
                        let uploadImageProducer = self.uploadProducer("\(self.urlString)/upload/image/\(interviewId)", fileURL: imageURL, mimeType: "image/jpeg")
                        observer.send(value: uploadImageProducer)
                    }

                    // Create producers for sending the attachments (and then the recordings) to the server.
                    interview.attachments.forEach { attachment in
                        let attachmentDict : ResponseDict = ["text": attachment.questionText, "tags": attachment.tags, "interview": interviewId]
                        let attachmentProducer = self.requestProducer("\(self.urlString)/attachments", parameters: attachmentDict)
                            .flatMap(.concat) { next -> SignalProducer<ResponseDict, NSError> in
                                // Get the attachment id; if that's not possible, send an error.
                                guard let attachmentId = next["_id"] as? String else {
                                    return SignalProducer(error: NSError(domain: self.errorDomain, code: 1, userInfo: nil))
                                }

                                // Create producer for uploading the attachment's recording to the server.
                                return self.uploadProducer("\(self.urlString)/upload/attachment/\(attachmentId)", fileURL: attachment.recordingUrl, mimeType: "audio/wav")
                        }
                        observer.send(value: attachmentProducer)
                    }
                    
                    observer.sendCompleted()
                }
                
                return producer
                    .replayLazily(upTo: 1 + interview.attachments.count)
                    .flatten(.concat)
                    .map { _ in return interviewId }
        }
    }
    
    fileprivate func requestProducer(_ URLString: URLConvertible, parameters: ResponseDict) -> SignalProducer<ResponseDict, NSError> {
        return SignalProducer<ResponseDict, NSError>.init { (observer, _) in
            Alamofire.request(URLString, method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .responseJSON { (response : DataResponse<Any>) in
                    debugPrint(response)
                    if let result = response.result.value as? ResponseDict {
                        observer.send(value: result)
                        observer.sendCompleted()
                    } else {
                        observer.send(error: NSError(domain: self.errorDomain, code: 100, userInfo: nil))
                    }
            }
        }
            .timeout(after: self.timeoutInterval, raising: NSError(domain: self.errorDomain, code: 200, userInfo: nil), on: QueueScheduler())
    }
    
    fileprivate func uploadProducer(_ URLString: URLConvertible, fileURL: URL, mimeType: String) -> SignalProducer<ResponseDict, NSError> {
        return SignalProducer<ResponseDict, NSError>.init { (observer, _) in
            Alamofire.upload(multipartFormData: { (multipartFormData) in
                if let data = try? Data(contentsOf: fileURL) {
                    multipartFormData.append(data, withName: "file", fileName: fileURL.lastPathComponent, mimeType: mimeType)
                }
            }, to: URLString, encodingCompletion: { (encodingResult) in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseString { response in
                        debugPrint(response)
                        switch response.result {
                        case .success:
                            observer.send(value: ResponseDict())
                            observer.sendCompleted()
                        case .failure(let error):
                            observer.send(error: (error as NSError?) ?? NSError(domain: self.errorDomain, code: 101, userInfo: nil))
                        }
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            })
        }
            .timeout(after: self.uploadTimeoutInterval, raising: NSError(domain: self.errorDomain, code: 201, userInfo: nil), on: QueueScheduler())
    }
}
