//
//  QuestionsListViewController.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import SnapKit

class QuestionsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let interview : MutableProperty<Interview>
    let questions = MutableProperty<[String]>([])

    let cellIdentifier = "cellIdentifier"
    let maxQuestionLength = 128
    
    let tableView = UITableView()
    
    init(interview: Interview) {
        self.interview = MutableProperty<Interview>(interview)

        super.init(nibName : nil, bundle : nil)
        
        // Sync the view's interview with the model.
        self.interview <~ InterviewStore.sharedInstance.interviewSignal(interview.identifier).skipNil()

        // Sync the view's question strings.
        self.questions <~ QuestionStore.sharedInstance.questionSignal()

//        self.questions.value = [
//            "What are the topics you are interested in or working with?",
//            "What is the strongest tool/method/practice you work with?",
//            "What public/shared/open space in your city do you love?",
//            "Describe a context/conversation/situation that you have been part of, that you were satisfied with.",
//            "What was you biggest insight in the time we have spent together?",
//            "What problem would you like to solve next?"
//        ]

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Interview Questions"
        self.view.backgroundColor = MaziStyle.backgroundColor
        
        // Create views.
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.register(QuestionTableCell.self, forCellReuseIdentifier: cellIdentifier)
        self.view.addSubview(tableView)
        
        // Navigation bar Done button.
        let acceptButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(QuestionsListViewController.onDoneButtonClick))
        self.navigationItem.rightBarButtonItem = acceptButton

        // Question Add Button
        let addQuestionButton = MaziUIButton();
        addQuestionButton.setTitle("Add Question", for: UIControlState.normal)
        addQuestionButton.addTarget(self, action: #selector(QuestionsListViewController.onAddQuestionButtonClick), for: UIControlEvents.touchUpInside)
        self.view.addSubview(addQuestionButton)
        
        
        // Create view constraints.
        addQuestionButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view).inset(MaziStyle.outerInset)
            make.centerX.equalTo(self.view)
            make.height.equalTo(MaziStyle.buttonSize.height)
            make.width.equalTo(MaziStyle.buttonSize.width)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).inset(MaziStyle.outerInset)
            make.left.equalTo(self.view).inset(MaziStyle.outerInset)
            make.right.equalTo(self.view).inset(MaziStyle.outerInset)
            make.bottom.equalTo(addQuestionButton.snp.top).inset(MaziStyle.outerInset)
        }

        // Reactive bindings.
        
        // Update the view whenever the model changes.
        interview.producer
            .observe(on: UIScheduler())
            .startWithValues { [weak self] (newInterview : Interview) in
                guard let `self` = self else { return }
                
                // Reload table view data.
                self.tableView.reloadData()
                
                // Disable start button when either name or role is empty.
                acceptButton.isEnabled = newInterview.attachments.count > 0
        }
        
        // Handle Done button presses.
        self.reactive.trigger(for: #selector(QuestionsListViewController.onDoneButtonClick))
            .observe(on: UIScheduler())
            .observeValues { [weak self] next in
                guard let `self` = self else { return }
                
                let synospisVC = SynopsisViewController(interview: self.interview.value)
                self.navigationController?.pushViewController(synospisVC, animated: true)
        }

        //Update View whenever questions change
        questions.producer
            .observe(on: UIScheduler())
            .startWithValues { [weak self] (newQuestions : [String]) in
                guard let `self` = self else { return }
                self.tableView.reloadData();
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! QuestionTableCell
        let questionString = questions.value[indexPath.row]
        cell.question = questionString

        //add listener
        cell.deleteButton.reactive.trigger(for: .touchUpInside)
            .observeValues { [weak self] _ in
                guard let `self` = self else { return }
                self.onDeleteButtonClick(question : questionString)
        }

        // change background if already existent
        if (interview.value.attachments.contains { $0.questionText == questionString }) {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
            cell.nameLabel!.textColor = MaziStyle.textColor
        } else {
            cell.nameLabel!.textColor = MaziStyle.textColorAlternative
        }

        
        return cell
    }

    // Handle table view selections.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the selected cell.
        tableView.deselectRow(at: indexPath, animated: true)

        // Create the new view controller and present it to the user.
        let recorderVC = RecorderViewController(interview: self.interview.value, question : self.questions.value[indexPath.row])
        self.navigationController?.pushViewController(recorderVC, animated: true)
    }

    func onDeleteButtonClick(question : String)
    {
        QuestionStore.sharedInstance.removeQuestion(question)
    }

    func onDoneButtonClick() {}

    func onAddQuestionButtonClick() {

        let alert = UIAlertController(title: "Add Question", message: "Enter new question", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""

            //TODO : check min and max length
            textField.reactive.continuousTextValues
                .observeValues { next in
                    if var name = next {
                        // Make sure text field doesn't surpass a certain number of characters.
                        name = String(name.characters.prefix(self.maxQuestionLength))
                        textField.text = name;
                    }
            }

        }

        // Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            guard let textField = alert?.textFields![0] else { return }
            let text : String = textField.text!
            if (text.characters.count > 3) {
                 QuestionStore.sharedInstance.addQuestion(text)
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
}
