//
//  Attachment.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation

struct Attachment {
    let text : String
    let tags : [String]
    let textUrl : String
    
    init(text: String, tags: [String], textUrl: String) {
        self.text = text
        self.tags = tags
        self.textUrl = textUrl
    }
}
