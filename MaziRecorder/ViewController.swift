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
import enum Result.NoError

class ViewController: UIViewController {
    
    // Create a new interview
    private let interview = MutableProperty<Interview>(InterviewStore.sharedInstance.fetchLatestIncompleteOrCreateNewInterview())
    
    // Signal of signals of interviews. This producer allows us to change which
    // interview to observe (used when resetting after a successful submission).
    private let (interviewObservationsProducer, interviewObservationsObserver) = SignalProducer<SignalProducer<Interview, NoError>, NoError>.buffer(1)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Sync the view's interview with the model.
        interview <~ interviewObservationsProducer.flatten(.Latest)
        self.setNewInterviewObservation(interview.value)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Mazi Recorder"
        self.view.backgroundColor = MaziStyle.backgroundColor
        
        // Create views.
        let scrollView = UIScrollView()
        self.view.addSubview(scrollView)
        
        let containerView = UIView()
        scrollView.addSubview(containerView)
        
        let introTextLabel = MaziUILabel()
        introTextLabel.text = "Prepare a new Interview."
        introTextLabel.numberOfLines = 0
        introTextLabel.textAlignment = .Center
        containerView.addSubview(introTextLabel)
        
        let nameLabel = MaziUIInputLabel()
        nameLabel.text = "Name"
        containerView.addSubview(nameLabel)
        
        let nameField = MaziUITextField()
        nameField.attributedPlaceholder = NSAttributedString(string: "Name of the interviewed Person")
        containerView.addSubview(nameField)
        
        let roleLabel = MaziUIInputLabel()
        roleLabel.text = "Role"
        containerView.addSubview(roleLabel)
        
        let roleField = MaziUITextField()
        roleField.attributedPlaceholder = NSAttributedString(string: "Expertise/Role of the person")
        containerView.addSubview(roleField)
        
        let startButton = MaziUIButton(type: .System)
        startButton.setTitle("Start", forState: .Normal)
        containerView.addSubview(startButton)
        
        // Navigation bar Reset button.
        let resetButton = UIBarButtonItem(title: "Reset", style: .Plain, target: self, action: #selector(ViewController.onResetButtonClick))
        self.navigationItem.leftBarButtonItem = resetButton
        
        // Create view constraints.
        let labelWidth = 60
        
        scrollView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }

        let navigationBarHeight = UIApplication.sharedApplication().statusBarFrame.height +
            (navigationController?.navigationBar.bounds.height ?? 0)
        containerView.snp_makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.5)
            make.centerX.equalTo(self.view)
            make.top.greaterThanOrEqualTo(scrollView)
            make.centerY.equalTo(scrollView).offset(-navigationBarHeight).priorityLow()
            make.bottom.lessThanOrEqualTo(scrollView)
        }
        
        introTextLabel.snp_makeConstraints { (make) in
            make.top.left.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        nameLabel.snp_makeConstraints { (make) in
            make.top.equalTo(introTextLabel.snp_bottom).offset(MaziStyle.paragraphSpacing)
            make.left.equalTo(containerView).inset(MaziStyle.outerInset)
            make.width.equalTo(labelWidth)
        }
        nameField.snp_makeConstraints { (make) in
            make.centerY.equalTo(nameLabel.snp_centerY)
            make.left.equalTo(nameLabel.snp_right).offset(MaziStyle.spacing)
            make.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        roleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(nameField.snp_bottom).offset(MaziStyle.largeSpacing)
            make.left.equalTo(containerView).inset(MaziStyle.outerInset)
            make.width.equalTo(labelWidth)
        }
        roleField.snp_makeConstraints { (make) in
            make.centerY.equalTo(roleLabel.snp_centerY)
            make.left.equalTo(roleLabel.snp_right).offset(MaziStyle.spacing)
            make.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        startButton.snp_makeConstraints { (make) in
            make.top.equalTo(roleField.snp_bottom).offset(MaziStyle.largeSpacing)
            make.width.equalTo(MaziStyle.buttonSize.width)
            make.height.equalTo(MaziStyle.buttonSize.height)
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        // Reactive bindings.
        
        // Update the view whenever the model changes.
        interview.producer
            .observeOn(UIScheduler())
            .startWithNext { (newInterview : Interview) in
                nameField.text = newInterview.name
                roleField.text = newInterview.role
                
                // Disable start button when either name or role is empty.
                startButton.enabled = newInterview.name.characters.count > 0
                    && newInterview.role.characters.count > 0
        }
        
        RACSignal.merge([
            NSNotificationCenter.defaultCenter().rac_addObserverForName(UIKeyboardWillShowNotification, object: nil),
            NSNotificationCenter.defaultCenter().rac_addObserverForName(UIKeyboardWillHideNotification, object: nil)
            ])
            .takeUntil(self.rac_willDeallocSignal())
            .toSignalProducer()
            .observeOn(UIScheduler())
            .startWithNext { [weak self] next in
                guard let `self` = self else { return }
                
                if let notification = next as? NSNotification,
                    userInfo = notification.userInfo,
                    keyboardSize = (userInfo["UIKeyboardFrameEndUserInfoKey"] as? NSValue)?.CGRectValue() {
                    if notification.name == UIKeyboardWillShowNotification {
                        // Keyboard will show.
                        let height = self.view.convertRect(keyboardSize, fromView: nil).size.height ?? 0
                        scrollView.snp_updateConstraints { (make) in
                            make.bottom.equalTo(self.view).inset(height)
                        }
                    } else {
                        // Keyboard will hide.
                        scrollView.snp_updateConstraints { (make) in
                            make.bottom.equalTo(self.view).inset(0)
                        }
                    }

                    // Animate the constraint changes.
                    UIView.animateWithDuration(0.5, animations: {
                        scrollView.layoutIfNeeded()
                    })
                }
        }
        
        // Update the model when the user inputs text.
        let maxLength = 60
        nameField.rac_textSignal()
            .toSignalProducer()
            .skip(1)
            .startWithNext { [weak self] next in
                guard let `self` = self else { return }
                
                if var name = next as? NSString {
                    // Make sure text field doesn't surpass a certain number of characters.
                    if name.length > maxLength {
                        name = name.substringToIndex(maxLength)
                    }
                    
                    // Store the new name in the model.
                    let update = InterviewUpdate(name: .Changed(name as String))
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
        }
        roleField.rac_textSignal()
            .toSignalProducer()
            .skip(1)
            .startWithNext { [weak self] next in
                guard let `self` = self else { return }
                
                if var role = next as? NSString {
                    // Make sure text field doesn't surpass a certain number of characters.
                    if role.length > maxLength {
                        role = role.substringToIndex(maxLength)
                    }
                    
                    // Store the new role in the model.
                    let update = InterviewUpdate(role: .Changed(role as String))
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
        }
        
        // Manual resetting.
        self.rac_signalForSelector(#selector(ViewController.onResetButtonClick))
            .toSignalProducer()
            .startWithNext { [weak self] _ in
                guard let `self` = self else { return }
                
                // Reset the model's fields.
                let update = InterviewUpdate(name: .Changed(""), role: .Changed(""), text: .Changed(""), attachments: .Changed([]), imageUrl: .Changed(.None), identifierOnServer: .Changed(.None))
                InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
        }
        
        // Navigate to the next screen when the user presses Start.
        startButton.rac_signalForControlEvents(.TouchUpInside)
            .toSignalProducer()
            .startWithNext { [weak self] _ in
                guard let `self` = self else { return }
                
                let questionsListVC = QuestionsListViewController(interview: self.interview.value)
                self.navigationController?.pushViewController(questionsListVC, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setNewInterviewObservation(newInterview: Interview) {
        let newInterviewProducer = InterviewStore.sharedInstance.interviewSignal(newInterview.identifier).ignoreNil().skipRepeats()
        interviewObservationsObserver.sendNext(newInterviewProducer)
    }
    
    func onResetButtonClick() {}

}

