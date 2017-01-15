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
    let recordingUrl : URL
    let recordingDuration : Int
    
    // MARK: Init
    
    init(questionText: String = "", tags: [String] = [], recordingUrl: URL = URL(fileURLWithPath: ""), recordingDuration: Int = 0) {
        self.questionText = questionText
        self.tags = tags
        self.recordingUrl = recordingUrl
        self.recordingDuration = recordingDuration
    }
}

// MARK: Storable

extension Attachment : Storable {
    init(warehouse: Warehouseable) {
        self.questionText = warehouse.get("questionText") ?? ""
        self.tags = warehouse.get("tags") ?? []
        self.recordingUrl = URL(string: warehouse.get("recordingUrl") ?? "") ?? URL(fileURLWithPath: "")
        self.recordingDuration = warehouse.get("recordingDuration") ?? 0
    }
    
    func toDictionary() -> [String : Any] {
        return [
            "questionText": self.questionText as AnyObject,
            "tags": self.tags as AnyObject,
            "recordingUrl": self.recordingUrl.absoluteString as AnyObject,
            "recordingDuration": self.recordingDuration as AnyObject
        ]
    }
}

// MARK: Equatable

extension Attachment : Equatable {}

func ==(lhs: Attachment, rhs: Attachment) -> Bool {
    return lhs.questionText == rhs.questionText
        && lhs.tags == rhs.tags
        && (lhs.recordingUrl == rhs.recordingUrl)
        && lhs.recordingDuration == rhs.recordingDuration
}
