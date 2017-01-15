//
//  ViewController.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import SnapKit
import ReactiveSwift
import ReactiveCocoa
import enum Result.NoError

class ViewController: UIViewController {
    
    // Create a new interview
    fileprivate let interview = MutableProperty<Interview>(InterviewStore.sharedInstance.fetchLatestIncompleteOrCreateNewInterview())
    
    // Property of signals of interviews. This property allows us to change which interview to 
    // observe (used when resetting after a successful submission).
    fileprivate let interviewObservations = MutableProperty<SignalProducer<Interview, NoError>>(SignalProducer<Interview, NoError>.empty)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Sync the view's interview with the model.
        interview <~ interviewObservations.producer.flatten(.latest)
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
        introTextLabel.textAlignment = .center
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
        
        let startButton = MaziUIButton(type: .system)
        startButton.setTitle("Start", for: UIControlState())
        containerView.addSubview(startButton)
        
        // Navigation bar Reset button.
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(ViewController.onResetButtonClick))
        self.navigationItem.leftBarButtonItem = resetButton
        
        // Create view constraints.
        let labelWidth = 60
        
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }

        let navigationBarHeight = UIApplication.shared.statusBarFrame.height +
            (navigationController?.navigationBar.bounds.height ?? 0)
        containerView.snp.makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.5)
            make.centerX.equalTo(self.view)
            make.top.greaterThanOrEqualTo(scrollView)
            make.centerY.equalTo(scrollView).offset(-navigationBarHeight).priority(UILayoutPriorityDefaultLow)
            make.bottom.lessThanOrEqualTo(scrollView)
        }
        
        introTextLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(introTextLabel.snp.bottom).offset(MaziStyle.paragraphSpacing)
            make.left.equalTo(containerView).inset(MaziStyle.outerInset)
            make.width.equalTo(labelWidth)
        }
        nameField.snp.makeConstraints { (make) in
            make.centerY.equalTo(nameLabel.snp.centerY)
            make.left.equalTo(nameLabel.snp.right).offset(MaziStyle.spacing)
            make.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        roleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameField.snp.bottom).offset(MaziStyle.largeSpacing)
            make.left.equalTo(containerView).inset(MaziStyle.outerInset)
            make.width.equalTo(labelWidth)
        }
        roleField.snp.makeConstraints { (make) in
            make.centerY.equalTo(roleLabel.snp.centerY)
            make.left.equalTo(roleLabel.snp.right).offset(MaziStyle.spacing)
            make.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        startButton.snp.makeConstraints { (make) in
            make.top.equalTo(roleField.snp.bottom).offset(MaziStyle.largeSpacing)
            make.width.equalTo(MaziStyle.buttonSize.width)
            make.height.equalTo(MaziStyle.buttonSize.height)
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        // Reactive bindings.
        
        // Update the view whenever the model changes.
        interview.producer
            .observe(on: UIScheduler())
            .startWithValues { (newInterview : Interview) in
                nameField.text = newInterview.name
                roleField.text = newInterview.role
                
                // Disable start button when either name or role is empty.
                startButton.isEnabled = newInterview.name.characters.count > 0
                    && newInterview.role.characters.count > 0
        }

        Signal.merge([
            NotificationCenter.default.reactive.notifications(forName: NSNotification.Name.UIKeyboardWillShow),
            NotificationCenter.default.reactive.notifications(forName: NSNotification.Name.UIKeyboardWillHide)
            ])
            .take(until: self.reactive.lifetime.ended)
            .observe(on: UIScheduler())
            .observeValues { [weak self] notification in
                guard let `self` = self else { return }
                
                if let userInfo = notification.userInfo,
                    let keyboardSize = (userInfo["UIKeyboardFrameEndUserInfoKey"] as? NSValue)?.cgRectValue {
                    if notification.name == NSNotification.Name.UIKeyboardWillShow {
                        // Keyboard will show.
                        let height = self.view.convert(keyboardSize, from: nil).size.height 
                        scrollView.snp.updateConstraints { (make) in
                            make.bottom.equalTo(self.view).inset(height)
                        }
                    } else {
                        // Keyboard will hide.
                        scrollView.snp.updateConstraints { (make) in
                            make.bottom.equalTo(self.view).inset(0)
                        }
                    }

                    // Animate the constraint changes.
                    UIView.animate(withDuration: 0.5, animations: {
                        scrollView.layoutIfNeeded()
                    })
                }
        }
        
        // Update the model when the user inputs text.
        let maxLength = 60
        nameField.reactive.continuousTextValues
            .skip(first: 1)
            .observeValues { [weak self] next in
                guard let `self` = self else { return }
                
                if var name = next {
                    // Make sure text field doesn't surpass a certain number of characters.
                    name = String(name.characters.prefix(maxLength))
                    
                    // Store the new name in the model.
                    let update = InterviewUpdate(name: .changed(name))
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
        }
        roleField.reactive.continuousTextValues
            .skip(first: 1)
            .observeValues { [weak self] next in
                guard let `self` = self else { return }
                
                if var role = next {
                    // Make sure text field doesn't surpass a certain number of characters.
                    role = String(role.characters.prefix(maxLength))

                    // Store the new role in the model.
                    let update = InterviewUpdate(role: .changed(role as String))
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
        }
        
        // Manual resetting.
        self.reactive.trigger(for: #selector(ViewController.onResetButtonClick))
            .observeValues { [weak self] _ in
                guard let `self` = self else { return }
                
                // Reset the model's fields.
                let update = InterviewUpdate(name: .changed(""), role: .changed(""), text: .changed(""), attachments: .changed([]), imageUrl: .changed(.none), identifierOnServer: .changed(.none))
                InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
        }
        
        // Navigate to the next screen when the user presses Start.
        startButton.reactive.trigger(for: .touchUpInside)
            .observeValues { [weak self] _ in
                guard let `self` = self else { return }
                
                let questionsListVC = QuestionsListViewController(interview: self.interview.value)
                self.navigationController?.pushViewController(questionsListVC, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setNewInterviewObservation(_ newInterview: Interview) {
        interviewObservations.value = InterviewStore.sharedInstance.interviewSignal(newInterview.identifier).skipNil().skipRepeats()
    }
    
    func onResetButtonClick() {}

}

