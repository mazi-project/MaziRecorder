//
//  Attachment.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation

struct Attachment {
    let questionText : String
    let tags : [String]
    let recordingUrl : String
    
    init(questionText: String = "", tags: [String] = [], recordingUrl: String = "") {
        self.questionText = questionText
        self.tags = tags
        self.recordingUrl = recordingUrl
    }
}
