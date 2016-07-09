//
//  QuestionsListViewController.swift
//  MaziRecorder
//
//  Created by Erich Grunewald on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SnapKit

class QuestionsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let interview : Interview
    let questions = ["First question", "Second question", "Third question"]
    
    let cellIdentifier = "cellIdentifier"
    
    init(interview: Interview) {
        self.interview = interview
        super.init(nibName : nil, bundle : nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        
        // Navigation bar Done button.
        let acceptButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(QuestionsListViewController.onDoneButtonClick))
        self.navigationItem.rightBarButtonItem = acceptButton
        
        // Create view constraints.
        
        tableView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        // Reactive bindings.
        
        // Handle Done button presses.
        self.rac_signalForSelector(#selector(QuestionsListViewController.onDoneButtonClick))
            .subscribeNext { (next : AnyObject!) in
                print("Click")
        }
        
        // Handle table view selections.
        self.rac_signalForSelector(#selector(QuestionsListViewController.tableView(_:didSelectRowAtIndexPath:)))
            .subscribeNext { (next : AnyObject!) in
            if let tuple = next as? RACTuple,
                tableView = tuple.first as? UITableView,
                indexPath = tuple.second as? NSIndexPath {
                // Deselect the selected cell.
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                
                // Create the new view controller and present it to the user.
                let recorderVC = RecorderViewController(interview: self.interview, question : self.questions[indexPath.row])
                self.navigationController?.pushViewController(recorderVC, animated: true)
            }
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {}
    
    func onDoneButtonClick() {}
    
}
