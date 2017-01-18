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
import enum Result.NoError

private let archiveFileName = "QuestionStore"

class QuestionStore {

    static let sharedInstance = QuestionStore()

    let questions = MutableProperty<[String]>([])

    init() {
        // Load model from storage.
        if let unpackedQuestions: [String] = Pantry.unpack(archiveFileName) {
            print("💾 Loaded questions: ", unpackedQuestions)
            questions.value = unpackedQuestions
        } else {
            print("💾 There was no model to load.")
        }

        // Store model whenever it changes.
        questions.producer
            .debounce(1, on: QueueScheduler.main)
            .startWithValues { (newQuestions : [String]) in
                Pantry.pack(newQuestions, key: archiveFileName)
                print("💾 Stored questions.")
        }
    }

    // A signal of interviews matching a given identifier.
    func questionSignal() -> SignalProducer<[String], NoError> {
        return questions.producer
    }

    func addQuestion(_ question: String) {
        self.questions.value.append(question)
    }

    func removeQuestion(_ question: String) {
        if let i = questions.value.index(of: question) {
            questions.value.remove(at: i);
        }
    }

}
