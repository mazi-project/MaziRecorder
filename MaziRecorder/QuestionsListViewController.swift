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
    let questions = [
        "What are the topics you are interested in or working with?",
        "What is the strongest tool/method/practice you work with?",
        "What public/shared/open space in your city do you love?",
        "Describe a context/conversation/situation that you have been part of, that you were satisfied with.",
        "What was you biggest insight in the time we have spent together?",
        "What problem would you like to solve next?"
    ]
    
    let cellIdentifier = "cellIdentifier"
    
    let tableView = UITableView()
    
    init(interview: Interview) {
        self.interview = MutableProperty<Interview>(interview)
        
        super.init(nibName : nil, bundle : nil)
        
        // Sync the view's interview with the model.
        self.interview <~ InterviewStore.sharedInstance.interviewSignal(interview.identifier).skipNil()
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(tableView)
        
        // Navigation bar Done button.
        let acceptButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(QuestionsListViewController.onDoneButtonClick))
        self.navigationItem.rightBarButtonItem = acceptButton
        
        // Create view constraints.
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view).inset(MaziStyle.outerInset)
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)! as UITableViewCell
        
        let questionString = questions[indexPath.row]
        cell.textLabel?.text = questionString
        
        // change background if already existent
        if (interview.value.attachments.contains { $0.questionText == questionString }) {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
            cell.textLabel!.textColor = MaziStyle.textColor
        } else {
            cell.textLabel!.textColor = MaziStyle.textColorAlternative
        }
        
        
        return cell
    }

    // Handle table view selections.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the selected cell.
        tableView.deselectRow(at: indexPath, animated: true)

        // Create the new view controller and present it to the user.
        let recorderVC = RecorderViewController(interview: self.interview.value, question : self.questions[indexPath.row])
        self.navigationController?.pushViewController(recorderVC, animated: true)
    }

    func onDoneButtonClick() {}
}
