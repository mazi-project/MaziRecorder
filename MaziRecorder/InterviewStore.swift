//
//  InterviewStore.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Pantry
import enum Result.NoError

class InterviewStore {
    
    static let sharedInstance = InterviewStore()
    
    let interviews = MutableProperty<[Interview]>([])
    
    private let queue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    private let archiveFileName = "InterviewStore"
    
    init() {
        // Load model from storage.
        if let unpackedInterviews: [Interview] = Pantry.unpack(archiveFileName) {
            print("💾 Loaded model: ", unpackedInterviews)
            interviews.value = unpackedInterviews
        } else {
            print("💾 There was no model to load.")
        }

        // Store model whenever it changes.
        interviews.producer
            .skipRepeats({ $0 == $1 })
            .debounce(1, onScheduler: QueueScheduler.mainQueueScheduler)
            .startWithNext({ (newInterviews : [Interview]) in
                Pantry.pack(newInterviews, key: self.archiveFileName)
                print("💾 Stored model.")
            })
    }
    
    // MARK: Getters
    
    // A signal of interviews matching a given identifier.
    func interviewSignal(identifier: String) -> SignalProducer<Interview?, NoError> {
        return interviews.producer
            .map { next -> Interview? in
                return self.getInterview(identifier, interviews: next)
            }
            .replayLazily(1)
    }
    
    // A signal of attachment matching a given question.
    func attachmentSignal(question: String) -> SignalProducer<Attachment?, NoError> {
        return interviews.producer
            .map { next -> Attachment? in
                let attachments : [Attachment] = next.flatMap { $0.attachments }
                if let index = attachments.indexOf({ $0.questionText == question }) {
                    return attachments[index]
                }
                return .None
            }
            .replayLazily(1)
    }
    
    // Get an interview from an array of interviews that matches a given identifier.
    private func getInterview(identifier: String, interviews: [Interview]) -> Interview? {
        if let index = interviews.indexOf({ $0.identifier == identifier }) {
            let interview = interviews[index]
            return interview
        }
        return .None
    }
    
    // MARK: Update
    
    func createInterview() -> Interview {
        let interview = Interview()
        var interviewsArray = interviews.value
        interviewsArray.append(interview)
        
        dispatch_async(queue) {
            self.interviews.value = interviewsArray
        }
        
        print("Created interview: \(interview)")
        
        return interview
    }
    
    func fetchLatestIncompleteOrCreateNewInterview() -> Interview {
        let reverseInterviews = interviews.value.reverse() // Latest first.
        if let index = reverseInterviews.indexOf({ $0.identifierOnServer == .None }) {
            return reverseInterviews[index]
        }
        
        return createInterview()
    }
    
    func updateInterview(fromInterview interview: Interview, interviewUpdate: InterviewUpdate) {
        self.updateInterview(fromIdentifier: interview.identifier, interviewUpdate: interviewUpdate)
    }
    
    func updateInterview(fromIdentifier identifier: String, interviewUpdate: InterviewUpdate) {
        var interviewsArray = interviews.value
        if let index = interviewsArray.indexOf({ $0.identifier == identifier }) {
            let oldInterview = interviewsArray[index]
            let newInterview = Interview(interview: oldInterview, interviewUpdate: interviewUpdate)
            interviewsArray.removeAtIndex(index)
            interviewsArray.append(newInterview)
            
            dispatch_async(queue) {
                self.interviews.value = interviewsArray.sort({ $0.creationDate.compare($1.creationDate) == NSComparisonResult.OrderedAscending })
            }
            
            print("Updated interview: \(newInterview)")
        }
    }
    
}
