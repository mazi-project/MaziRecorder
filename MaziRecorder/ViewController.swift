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
    var interview = InterviewStore.sharedInstance.fetchLatestIncompleteOrCreateNewInterview()

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
        
        // Update the view whenever the model changes.
        InterviewStore.sharedInstance.interviewSignal(interview.identifier)
            .ignoreNil()
            .startWithNext { (next : Interview) in
                self.interview = next
                nameField.text = self.interview.name
                roleField.text = self.interview.role
        }
        
        let maxLength = 60
        nameField.rac_textSignal()
            .subscribeNext { (next : AnyObject!) in
                if var name = next as? NSString {
                    // Make sure text field doesn't surpass a certain number of characters.
                    if name.length > maxLength {
                        name = name.substringToIndex(maxLength)
                    }
                    
                    // Store the new name in the model.
                    let update = InterviewUpdate(name: name as String)
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview, interviewUpdate: update)
                }
        }
        roleField.rac_textSignal()
            .subscribeNext { (next : AnyObject!) in
                if var role = next as? NSString {
                    // Make sure text field doesn't surpass a certain number of characters.
                    if role.length > maxLength {
                        role = role.substringToIndex(maxLength)
                    }
                    
                    // Store the new role in the model.
                    let update = InterviewUpdate(role: role as String)
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview, interviewUpdate: update)
                }
        }
        
        // Disable start button when either text field is empty.
        RACSignal.combineLatest([nameField.rac_textSignal(), roleField.rac_textSignal()])
            .subscribeNext { (next : AnyObject!) in
                if let tuple = next as? RACTuple,
                    name = tuple.first as? String,
                    role = tuple.second as? String {
                    print("Name: \(name), with role: \(role)")
                    startButton.enabled = name.characters.count > 0 && role.characters.count > 0
                }
        }
        
        // Navigate to the next screen when the user presses Start.
        startButton.rac_signalForControlEvents(.TouchUpInside).subscribeNext { _ in
            let questionsListVC = QuestionsListViewController(interview: self.interview)
            self.navigationController?.pushViewController(questionsListVC, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

