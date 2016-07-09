//
//  Interview.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation

struct Interview {
    let identifier : String
    let creationDate : NSDate
    let name : String
    let role : String
    let text : String
    let attachments : [Attachment]
    let imageUrl : String
    let uploaded : Bool
    
    init(identifier: String, creationDate: NSDate, name: String, role: String, text: String, attachments: [Attachment], imageUrl: String, uploaded: Bool) {
        self.identifier = identifier
        self.creationDate = creationDate
        self.name = name
        self.role = role
        self.text = text
        self.attachments = attachments
        self.imageUrl = imageUrl
        self.uploaded = uploaded
    }
    
    init(name: String = "", role: String = "", text: String = "", attachments: [Attachment] = [], imageUrl: String = "") {
        self.init(identifier: NSUUID().UUIDString, creationDate: NSDate.init(), name: name, role: role, text: text, attachments: attachments, imageUrl: imageUrl, uploaded: false)
    }
    
    init(interview: Interview, interviewUpdate: InterviewUpdate) {
        self.init(identifier: interview.identifier,
                  creationDate: interview.creationDate,
                  name: interviewUpdate.name ?? interview.name,
                  role: interviewUpdate.role ?? interview.role,
                  text: interviewUpdate.text ?? interview.text,
                  attachments: interviewUpdate.attachments ?? interview.attachments,
                  imageUrl: interviewUpdate.imageUrl ?? interview.imageUrl,
                  uploaded: interviewUpdate.uploaded ?? interview.uploaded)
    }
}

struct InterviewUpdate {
    var name : String?
    var role : String?
    var text : String?
    var attachments : [Attachment]?
    var imageUrl : String?
    var uploaded : Bool?
    
    init(name: String? = .None, role: String? = .None, text: String? = .None, attachments: [Attachment]? = .None, imageUrl: String? = .None, uploaded: Bool? = .None) {
        self.name = name
        self.role = role
        self.text = text
        self.attachments = attachments
        self.imageUrl = imageUrl
        self.uploaded = uploaded
    }
}
