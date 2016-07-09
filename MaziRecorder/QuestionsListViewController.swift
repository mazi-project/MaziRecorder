//
//  QuestionsListViewController.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit

class QuestionsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let cellIdentifier = "cellIdentifier"
    let questions = ["First question", "Second question", "Third question"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Questions"
        self.view.backgroundColor = UIColor.whiteColor()
        
        // Create views.
        
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(tableView)
        
        // Nav bar button.
        let acceptButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(QuestionsListViewController.onAcceptButtonClick))
        self.navigationItem.rightBarButtonItem = acceptButton
        
        // Create view constraints.
        
        tableView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)! as UITableViewCell
        
        cell.textLabel?.text = questions[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let recorderVC = RecorderViewController(question : questions[indexPath.row])
        self.navigationController?.pushViewController(recorderVC, animated: true)
        
        print("Selected \(questions[indexPath.row])")
    }
    
    func onAcceptButtonClick() {
        print("Click")
    }
    
}
