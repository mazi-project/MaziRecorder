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
    let imageUrl : NSURL?
    let identifierOnServer : String?
    
    // MARK: Init
    
    init(identifier: String, creationDate: NSDate, name: String, role: String, text: String, attachments: [Attachment], imageUrl: NSURL?, identifierOnServer: String?) {
        self.identifier = identifier
        self.creationDate = creationDate
        self.name = name
        self.role = role
        self.text = text
        self.attachments = attachments
        self.imageUrl = imageUrl
        self.identifierOnServer = identifierOnServer
    }
    
    init(name: String = "", role: String = "", text: String = "", attachments: [Attachment] = []) {
        self.init(identifier: NSUUID().UUIDString, creationDate: NSDate(), name: name, role: role, text: text, attachments: attachments, imageUrl: .None, identifierOnServer: .None)
    }
    
    init(interview: Interview, interviewUpdate: InterviewUpdate) {
        self.init(identifier: interview.identifier,
                  creationDate: interview.creationDate,
                  name: interviewUpdate.name.newValue(interview.name),
                  role: interviewUpdate.role.newValue(interview.role),
                  text: interviewUpdate.text.newValue(interview.text),
                  attachments: interviewUpdate.attachments.newValue(interview.attachments),
                  imageUrl: interviewUpdate.imageUrl.newValue(interview.imageUrl),
                  identifierOnServer: interviewUpdate.identifierOnServer.newValue(interview.identifierOnServer))
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
        self.imageUrl = NSURL(string: warehouse.get("imageUrl") ?? "") ?? NSURL()
        let identifierOnServer : String = warehouse.get("identifierOnServer") ?? ""
        self.identifierOnServer = identifierOnServer.characters.count > 0 ? identifierOnServer : .None
    }
    
    func toDictionary() -> [String : AnyObject] {
        return [
            "identifier": self.identifier,
            "creationDate": String(self.creationDate.timeIntervalSinceReferenceDate),
            "name": self.name,
            "role": self.role,
            "text": self.text,
            "attachments": self.attachments.map({ $0.toDictionary() as AnyObject }),
            "imageUrl": self.imageUrl?.absoluteString ?? "",
            "identifierOnServer": self.identifierOnServer ?? ""
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
        && lhs.identifierOnServer == rhs.identifierOnServer
}

enum UpdateValue<T> {
    case Unchanged
    case Changed(T)
    
    func newValue(oldValue: T) -> T {
        switch self {
        case .Changed(let x):
            return x
        default:
            return oldValue
        }
    }
}

struct InterviewUpdate {
    var name : UpdateValue<String>
    var role : UpdateValue<String>
    var text : UpdateValue<String>
    var attachments : UpdateValue<[Attachment]>
    var imageUrl : UpdateValue<NSURL?>
    var identifierOnServer : UpdateValue<String?>
    
    init(name: UpdateValue<String> = .Unchanged, role: UpdateValue<String> = .Unchanged, text: UpdateValue<String> = .Unchanged, attachments: UpdateValue<[Attachment]> = .Unchanged, imageUrl: UpdateValue<NSURL?> = .Unchanged, identifierOnServer: UpdateValue<String?> = .Unchanged) {
        self.name = name
        self.role = role
        self.text = text
        self.attachments = attachments
        self.imageUrl = imageUrl
        self.identifierOnServer = identifierOnServer
    }
}
