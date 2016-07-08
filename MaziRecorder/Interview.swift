//
//  Interview.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation

struct Interview {
    let identifier = NSUUID().UUIDString
    let name : String
    let role : String
    let text : String
    let attachments : [Attachment]
    let imageUrl : String
    
    init(name: String, role: String, text: String, attachments: [Attachment], imageUrl: String) {
        self.name = name
        self.role = role
        self.text = text
        self.attachments = attachments
        self.imageUrl = imageUrl
    }
}
