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
    let creationDate : Date
    let name : String
    let role : String
    let text : String
    let attachments : [Attachment]
    let imageUrl : URL?
    let identifierOnServer : String?
    
    // MARK: Init
    
    init(identifier: String, creationDate: Date, name: String, role: String, text: String, attachments: [Attachment], imageUrl: URL?, identifierOnServer: String?) {
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
        self.init(identifier: UUID().uuidString, creationDate: Date(), name: name, role: role, text: text, attachments: attachments, imageUrl: .none, identifierOnServer: .none)
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
    init(warehouse: Warehouseable) {
        self.identifier = warehouse.get("identifier") ?? NSUUID().uuidString
        let creationTimeString : String = warehouse.get("creationDate") ?? ""
        self.creationDate = Date(timeIntervalSinceReferenceDate: Double(creationTimeString) ?? Date.timeIntervalSinceReferenceDate)
        self.name = warehouse.get("name") ?? ""
        self.role = warehouse.get("role") ?? ""
        self.text = warehouse.get("text") ?? ""
        self.attachments = warehouse.get("attachments") ?? []
        self.imageUrl = URL(string: warehouse.get("imageUrl") ?? "")
        let identifierOnServer : String = warehouse.get("identifierOnServer") ?? ""
        self.identifierOnServer = identifierOnServer.characters.count > 0 ? identifierOnServer : .none
    }

    func toDictionary() -> [String : Any] {
        return [
            "identifier": self.identifier as AnyObject,
            "creationDate": String(self.creationDate.timeIntervalSinceReferenceDate) as AnyObject,
            "name": self.name as AnyObject,
            "role": self.role as AnyObject,
            "text": self.text as AnyObject,
            "attachments": self.attachments.map { $0.toDictionary() } as AnyObject,
            "imageUrl": (self.imageUrl?.absoluteString ?? "") as AnyObject,
            "identifierOnServer": (self.identifierOnServer ?? "") as AnyObject
        ]
    }
}

// MARK: Equatable

extension Interview : Equatable {}

func ==(lhs: Interview, rhs: Interview) -> Bool {
    return lhs.identifier == rhs.identifier
        && (lhs.creationDate == rhs.creationDate)
        && lhs.name == rhs.name
        && lhs.role == rhs.role
        && lhs.text == rhs.text
        && lhs.attachments == rhs.attachments
        && lhs.imageUrl == rhs.imageUrl
        && lhs.identifierOnServer == rhs.identifierOnServer
}

enum UpdateValue<T> {
    case unchanged
    case changed(T)
    
    func newValue(_ oldValue: T) -> T {
        switch self {
        case .changed(let x):
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
    var imageUrl : UpdateValue<URL?>
    var identifierOnServer : UpdateValue<String?>
    
    init(name: UpdateValue<String> = .unchanged, role: UpdateValue<String> = .unchanged, text: UpdateValue<String> = .unchanged, attachments: UpdateValue<[Attachment]> = .unchanged, imageUrl: UpdateValue<URL?> = .unchanged, identifierOnServer: UpdateValue<String?> = .unchanged) {
        self.name = name
        self.role = role
        self.text = text
        self.attachments = attachments
        self.imageUrl = imageUrl
        self.identifierOnServer = identifierOnServer
    }
}
