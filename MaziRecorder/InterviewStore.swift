//
//  InterviewStore.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation
import ReactiveSwift
import ReactiveCocoa
import Pantry
import enum Result.NoError

private let archiveFileName = "InterviewStore"

class InterviewStore {
    
    static let sharedInstance = InterviewStore()
    
    let interviews = MutableProperty<[Interview]>([])
    
    fileprivate let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    
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
            .debounce(1, on: QueueScheduler.main)
            .startWithValues { (newInterviews : [Interview]) in
                Pantry.pack(newInterviews, key: archiveFileName)
                print("💾 Stored model.")
            }
    }
    
    // MARK: Getters
    
    // A signal of interviews matching a given identifier.
    func interviewSignal(_ identifier: String) -> SignalProducer<Interview?, NoError> {
        return interviews.producer
            .map { next -> Interview? in
                return self.getInterview(identifier, interviews: next)
            }
            .replayLazily(upTo: 1)
    }
    
    // A signal of attachment matching a given question.
    func attachmentSignal(_ question: String) -> SignalProducer<Attachment?, NoError> {
        return interviews.producer
            .map { next -> Attachment? in
                let attachments : [Attachment] = next.flatMap { $0.attachments }
                if let index = attachments.index(where: { $0.questionText == question }) {
                    return attachments[index]
                }
                return .none
            }
            .replayLazily(upTo: 1)
    }
    
    // Get an interview from an array of interviews that matches a given identifier.
    fileprivate func getInterview(_ identifier: String, interviews: [Interview]) -> Interview? {
        if let index = interviews.index(where: { $0.identifier == identifier }) {
            let interview = interviews[index]
            return interview
        }
        return .none
    }
    
    // MARK: Update
    
    func createInterview() -> Interview {
        let interview = Interview()
        var interviewsArray = interviews.value
        interviewsArray.append(interview)
        
        (queue).async {
            self.interviews.value = interviewsArray
        }
        
        print("Created interview: \(interview)")
        
        return interview
    }
    
    func fetchLatestIncompleteOrCreateNewInterview() -> Interview {
        let reverseInterviews = interviews.value.reversed() // Latest first.
        if let index = reverseInterviews.index(where: { $0.identifierOnServer == nil }) {
            return reverseInterviews[index]
        }
        
        return createInterview()
    }
    
    func updateAttachment(_ interview: Interview, attachment: Attachment) {
        var newAttachments = interview.attachments
        if let existingIndex = interview.attachments.index(where: { $0.questionText == attachment.questionText }) {
            newAttachments.remove(at: existingIndex)
            newAttachments.insert(attachment, at: existingIndex)
        } else {
            newAttachments = newAttachments + [attachment]
        }
        
        let update = InterviewUpdate(attachments: .changed(newAttachments))
        self.updateInterview(fromInterview: interview, interviewUpdate: update)
    }
    
    func updateInterview(fromInterview interview: Interview, interviewUpdate: InterviewUpdate) {
        self.updateInterview(fromIdentifier: interview.identifier, interviewUpdate: interviewUpdate)
    }
    
    func updateInterview(fromIdentifier identifier: String, interviewUpdate: InterviewUpdate) {
        var interviewsArray = interviews.value
        if let index = interviewsArray.index(where: { $0.identifier == identifier }) {
            let oldInterview = interviewsArray[index]
            let newInterview = Interview(interview: oldInterview, interviewUpdate: interviewUpdate)
            interviewsArray.remove(at: index)
            interviewsArray.append(newInterview)
            
            (queue).async {
                self.interviews.value = interviewsArray.sorted(by: { $0.creationDate.compare($1.creationDate) == ComparisonResult.orderedAscending })
            }
            
            print("Updated interview: \(newInterview)")
        }
    }
    
}
