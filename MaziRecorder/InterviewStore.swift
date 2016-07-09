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

class InterviewStore: NSObject {
    
    static let sharedInstance = InterviewStore()
    
    let interviews = MutableProperty<[Interview]>([])
    private let archiveFileName = "InterviewStore"
    
    override init() {
        super.init()
        
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
    
    // MARK: Update
    
    func createInterview() -> Interview {
        let interview = Interview()
        var interviewsArray = interviews.value
        interviewsArray.append(interview)
        interviews.value = interviewsArray
        
        print("Created interview \(interview)")
        
        return interview
    }
    
    func fetchLatestIncompleteOrCreateNewInterview() -> Interview {
        let reverseInterviews = interviews.value.reverse() // Latest first.
        if let index = reverseInterviews.indexOf({ $0.uploaded == false }) {
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
            interviews.value = interviewsArray.sort({ $0.creationDate.compare($1.creationDate) == NSComparisonResult.OrderedAscending })
            
            print("Updated interview \(newInterview)")
        }
    }
    
}
