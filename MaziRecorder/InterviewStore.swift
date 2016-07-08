//
//  InterviewStore.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation
import ReactiveCocoa

class InterviewStore: NSObject {
    
    static let sharedInstance = InterviewStore()
    
    let interviews = MutableProperty<[Interview]>([])
    
    private let archiveFileName = "InterviewStore"
    
    func updateInterview(interview: Interview) {
        var interviewsArray = interviews.value
        if let index = interviewsArray.indexOf({ $0.identifier == interview.identifier }) {
            interviewsArray.removeAtIndex(index)
            interviewsArray.insert(interview, atIndex: index)
            interviews.value = interviewsArray
        }
    }
    
    // MARK: Persistence
    
    func archiveToDisk() {
//        let interviewsDict = interviews.map { $0.encode() }
//        
//        if let filePath = persistentFilePath() {
//            NSKeyedArchiver.archiveRootObject(interviewsDict, toFile: filePath)
//        }
    }
    
    func unarchiveFromDisk() {
//        if let
//            path = persistentFilePath(),
//            interviewsDict = NSKeyedUnarchiver.unarchiveObjectWithFile(path),
//            interviews: [Interview] = decode(interviewsDict) {
//            self.interviews = interviews
//        }
    }
    
    private func persistentFilePath() -> String? {
        let basePath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first as NSString?
        return basePath?.stringByAppendingPathComponent(archiveFileName)
    }
    
}
