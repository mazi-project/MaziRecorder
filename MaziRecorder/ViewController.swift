//
//  ViewController.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import SnapKit
import ReactiveCocoa

class ViewController: UIViewController {
    
    // Create a new interview
    let interview = MutableProperty<Interview>(InterviewStore.sharedInstance.fetchLatestIncompleteOrCreateNewInterview())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Mazi Recorder"
        
        // Create views.
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.greenColor()
        self.view.addSubview(containerView)
        
        let introTextLabel = UILabel()
        introTextLabel.text = "Intro"
        introTextLabel.numberOfLines = 0
        containerView.addSubview(introTextLabel)
        
        let nameLabel = UILabel()
        nameLabel.text = "Name:"
        containerView.addSubview(nameLabel)
        
        let nameField = UITextField()
        nameField.backgroundColor = UIColor.lightGrayColor()
        containerView.addSubview(nameField)
        
        let roleLabel = UILabel()
        roleLabel.text = "Role:"
        containerView.addSubview(roleLabel)
        
        let roleField = UITextField()
        roleField.backgroundColor = UIColor.lightGrayColor()
        containerView.addSubview(roleField)
        
        let startButton = UIButton(type: .System)
        startButton.setTitle("Start", forState: .Normal)
        containerView.addSubview(startButton)
        
        // Navigation bar Reset button.
        let resetButton = UIBarButtonItem(title: "Reset", style: .Plain, target: self, action: #selector(ViewController.onResetButtonClick))
        self.navigationItem.leftBarButtonItem = resetButton
        
        // Create view constraints.
        
        let outerInset = 20
        let spacing = 10
        let largeSpacing = 20
        
        containerView.snp_makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.5)
            make.centerX.centerY.equalTo(self.view)
        }
        
        introTextLabel.snp_makeConstraints { (make) in
            make.top.left.right.equalTo(containerView).inset(outerInset)
        }
        
        nameLabel.snp_makeConstraints { (make) in
            make.top.equalTo(introTextLabel.snp_bottom).offset(largeSpacing)
            make.left.right.equalTo(containerView).inset(outerInset)
        }
        nameField.snp_makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp_bottom).offset(spacing)
            make.left.right.equalTo(containerView).inset(outerInset)
            make.height.equalTo(60)
        }
        
        roleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(nameField.snp_bottom).offset(largeSpacing)
            make.left.right.equalTo(containerView).inset(outerInset)
        }
        roleField.snp_makeConstraints { (make) in
            make.top.equalTo(roleLabel.snp_bottom).offset(spacing)
            make.left.right.equalTo(containerView).inset(outerInset)
            make.height.equalTo(60)
        }
        
        startButton.snp_makeConstraints { (make) in
            make.top.equalTo(roleField.snp_bottom).offset(largeSpacing)
            make.width.equalTo(120)
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(outerInset)
        }
        
        // Reactive bindings.
        
        // Sync the view's interview with the model.
        interview <~ InterviewStore.sharedInstance.interviewSignal(interview.value.identifier).ignoreNil()
        
        // Update the view whenever the model changes.
        interview.producer
            .observeOn(UIScheduler())
            .startWithNext { (newInterview : Interview) in
                nameField.text = newInterview.name
                roleField.text = newInterview.role
                
                // Disable start button when either name or role is empty.
                startButton.enabled = newInterview.name.characters.count > 0 && newInterview.role.characters.count > 0
        }
        
        // Update the model when the user inputs text.
        let maxLength = 60
        nameField.rac_textSignal()
            .toSignalProducer()
            .skip(1)
            .startWithNext { next in
                if var name = next as? NSString {
                    // Make sure text field doesn't surpass a certain number of characters.
                    if name.length > maxLength {
                        name = name.substringToIndex(maxLength)
                    }
                    
                    // Store the new name in the model.
                    let update = InterviewUpdate(name: name as String)
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
        }
        roleField.rac_textSignal()
            .toSignalProducer()
            .skip(1)
            .startWithNext { next in
                if var role = next as? NSString {
                    // Make sure text field doesn't surpass a certain number of characters.
                    if role.length > maxLength {
                        role = role.substringToIndex(maxLength)
                    }
                    
                    // Store the new role in the model.
                    let update = InterviewUpdate(role: role as String)
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
        }
        
        self.rac_signalForSelector(#selector(ViewController.onResetButtonClick))
            .toSignalProducer()
            .startWithNext { _ in
                // Reset the model's fields.
                let update = InterviewUpdate(name: "", role: "", text: "", attachments: [], imageUrl: "", identifierOnServer: .None)
                InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
        }
        
        // Navigate to the next screen when the user presses Start.
        startButton.rac_signalForControlEvents(.TouchUpInside)
            .toSignalProducer()
            .startWithNext { _ in
                let questionsListVC = QuestionsListViewController(interview: self.interview.value)
                self.navigationController?.pushViewController(questionsListVC, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onResetButtonClick() {}

}

