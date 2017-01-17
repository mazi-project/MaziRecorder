//
//  QuestionStore.swift
//  MaziRecorder
//
//  Created by Lutz on 16/01/17.
//  Copyright © 2017 Erich Grunewald. All rights reserved.
//

import Foundation
import ReactiveSwift
import ReactiveCocoa
import Pantry

private let archiveFileName = "QuestionStore"

class QuestionStore {

    static let sharedInstance = QuestionStore()

    let questions = MutableProperty<[String]>([])

    init() {
        // Load model from storage.
        if let unpackedQuestions: [String] = Pantry.unpack(archiveFileName) {
            print("💾 Loaded model: ", unpackedQuestions)
            questions.value = unpackedQuestions
        } else {
            print("💾 There was no model to load.")
        }

        // Store model whenever it changes.
        questions.producer
            .skipRepeats({ $0 == $1 })
            .debounce(1, on: QueueScheduler.main)
            .startWithValues { (newQuestions : [String]) in
                Pantry.pack(newQuestions, key: archiveFileName)
                print("💾 Stored model.")
        }
    }

}
