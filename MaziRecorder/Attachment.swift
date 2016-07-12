//
//  Attachment.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation
import Pantry

struct Attachment {
    let questionText : String
    let tags : [String]
    let recordingUrl : NSURL
    let recordingDuration : Int
    
    // MARK: Init
    
    init(questionText: String = "", tags: [String] = [], recordingUrl: NSURL = NSURL(), recordingDuration: Int = 0) {
        self.questionText = questionText
        self.tags = tags
        self.recordingUrl = recordingUrl
        self.recordingDuration = recordingDuration
    }
}

// MARK: Storable

extension Attachment : Storable {
    init(warehouse: JSONWarehouse) {
        self.questionText = warehouse.get("questionText") ?? ""
        self.tags = warehouse.get("tags") ?? []
        self.recordingUrl = NSURL(string: warehouse.get("recordingUrl") ?? "") ?? NSURL()
        self.recordingDuration = warehouse.get("recordingDuration") ?? 0
    }
    
    func toDictionary() -> [String : AnyObject] {
        return [
            "questionText": self.questionText,
            "tags": self.tags,
            "recordingUrl": self.recordingUrl.absoluteString,
            "recordingDuration": self.recordingDuration
        ]
    }
}

// MARK: Equatable

extension Attachment : Equatable {}

func ==(lhs: Attachment, rhs: Attachment) -> Bool {
    return lhs.questionText == rhs.questionText
        && lhs.tags == rhs.tags
        && lhs.recordingUrl.isEqual(rhs.recordingUrl)
        && lhs.recordingDuration == rhs.recordingDuration
}
