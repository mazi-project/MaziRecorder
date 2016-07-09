//
//  Interview.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import Foundation
import Pantry

struct Interview {
    let identifier : String
    let creationDate : NSDate
    let name : String
    let role : String
    let text : String
    let attachments : [Attachment]
    let imageUrl : String
    let uploaded : Bool
    
    // MARK: Init
    
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
        self.init(identifier: NSUUID().UUIDString, creationDate: NSDate(), name: name, role: role, text: text, attachments: attachments, imageUrl: imageUrl, uploaded: false)
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

// MARK: Storable

extension Interview : Storable {
    init(warehouse: JSONWarehouse) {
        self.identifier = warehouse.get("identifier") ?? NSUUID().UUIDString
        let creationTimeString : String = warehouse.get("creationDate") ?? ""
        self.creationDate = NSDate(timeIntervalSinceReferenceDate: Double(creationTimeString) ?? NSDate.timeIntervalSinceReferenceDate())
        self.name = warehouse.get("name") ?? ""
        self.role = warehouse.get("role") ?? ""
        self.text = warehouse.get("text") ?? ""
        self.attachments = warehouse.get("attachments") ?? []
        self.imageUrl = warehouse.get("imageUrl") ?? ""
        self.uploaded = warehouse.get("uploaded") ?? false
    }
    
    func toDictionary() -> [String : AnyObject] {
        return [
            "identifier": self.identifier,
            "creationDate": String(self.creationDate.timeIntervalSinceReferenceDate),
            "name": self.name,
            "role": self.role,
            "text": self.text,
            "attachments": self.attachments.map({ $0.toDictionary() as AnyObject }),
            "imageUrl": self.imageUrl,
            "uploaded": self.uploaded
        ]
    }
}

// MARK: Equatable

extension Interview : Equatable {}

func ==(lhs: Interview, rhs: Interview) -> Bool {
    return lhs.identifier == rhs.identifier
        && lhs.creationDate.isEqual(rhs.creationDate)
        && lhs.name == rhs.name
        && lhs.role == rhs.role
        && lhs.text == rhs.text
        && lhs.attachments == rhs.attachments
        && lhs.imageUrl == rhs.imageUrl
        && lhs.uploaded == rhs.uploaded
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
