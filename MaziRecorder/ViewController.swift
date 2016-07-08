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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Mazi Recorder"
        
        let outerInset = 20
        let spacing = 10
        let largeSpacing = 20
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.greenColor()
        self.view.addSubview(containerView)
        containerView.snp_makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.5)
            make.centerX.centerY.equalTo(self.view)
        }
        
        let introTextLabel = UILabel()
        introTextLabel.text = "Intro"
        introTextLabel.numberOfLines = 0
        containerView.addSubview(introTextLabel)
        introTextLabel.snp_makeConstraints { (make) in
            make.top.left.right.equalTo(containerView).inset(outerInset)
        }
        
        let nameLabel = UILabel()
        nameLabel.text = "Name:"
        containerView.addSubview(nameLabel)
        nameLabel.snp_makeConstraints { (make) in
            make.top.equalTo(introTextLabel.snp_bottom).offset(largeSpacing)
            make.left.right.equalTo(containerView).inset(outerInset)
        }
        
        let nameField = UITextField()
        nameField.backgroundColor = UIColor.lightGrayColor()
        containerView.addSubview(nameField)
        nameField.snp_makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp_bottom).offset(spacing)
            make.left.right.equalTo(containerView).inset(outerInset)
            make.height.equalTo(60)
        }
        
        let roleLabel = UILabel()
        roleLabel.text = "Role:"
        containerView.addSubview(roleLabel)
        roleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(nameField.snp_bottom).offset(largeSpacing)
            make.left.right.equalTo(containerView).inset(outerInset)
        }
        
        let roleField = UITextField()
        roleField.backgroundColor = UIColor.lightGrayColor()
        containerView.addSubview(roleField)
        roleField.snp_makeConstraints { (make) in
            make.top.equalTo(roleLabel.snp_bottom).offset(spacing)
            make.left.right.equalTo(containerView).inset(outerInset)
            make.height.equalTo(60)
        }
        
        let startButton = UIButton(type: .Custom)
        startButton.setTitle("Start", forState: .Normal)
        containerView.addSubview(startButton)
        startButton.snp_makeConstraints { (make) in
            make.top.equalTo(roleField.snp_bottom).offset(largeSpacing)
            make.width.equalTo(120)
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(outerInset)
        }
        
        nameField.rac_textSignal()
            .combineLatestWith(roleField.rac_textSignal())
            .subscribeNext {
                let name : String = ($0 as! RACTuple).first as! String
                let role : String = ($0 as! RACTuple).second as! String
                print("Hello \(name) with \(role)")
                startButton.enabled = name.characters.count > 0 && role.characters.count > 0
        }
        
        startButton.rac_signalForControlEvents(.TouchUpInside).subscribeNext { _ in
            print("Hello")
            
            let questionsListVC = QuestionsListViewController()
            self.navigationController?.pushViewController(questionsListVC, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

