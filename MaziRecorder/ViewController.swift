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
    
    let interview = Interview(name: "", role: "", text: "", attachments: [], imageUrl: "")

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
        
        let startButton = UIButton(type: .Custom)
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
        
        // Make sure text fields don't surpass a certain number of characters.
        let maxLength = 60
        nameField.rac_textSignal()
            .subscribeNext { (next : AnyObject!) in
                if let name = next as? NSString {
                    if name.length > maxLength {
                        nameField.text = name.substringToIndex(maxLength)
                    }
                }
        }
        roleField.rac_textSignal()
            .subscribeNext { (next : AnyObject!) in
                if let role = next as? NSString {
                    if role.length > maxLength {
                        roleField.text = role.substringToIndex(maxLength)
                    }
                }
        }
        
        // Disable start button when either text field is empty.
        RACSignal.combineLatest([nameField.rac_textSignal(), roleField.rac_textSignal()])
            .subscribeNext {
                let name : String = ($0 as! RACTuple).first as! String
                let role : String = ($0 as! RACTuple).second as! String
                print("Hello \(name) with \(role)")
                startButton.enabled = name.characters.count > 0 && role.characters.count > 0
        }
        
        startButton.rac_signalForControlEvents(.TouchUpInside).subscribeNext { _ in
            let questionsListVC = QuestionsListViewController()
            self.navigationController?.pushViewController(questionsListVC, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

