//
//  RecorderViewController.swift
//  MaziRecorder
//
//  Created by Lutz on 08/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import ReactiveCocoa

class RecorderViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    let recordSettings = [
        AVSampleRateKey : NSNumber(float: Float(44100.0)),
        AVFormatIDKey : NSNumber(int: Int32(kAudioFormatLinearPCM)),
        AVNumberOfChannelsKey : NSNumber(int: 1),
        AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))
    ]
    
    let interview : Interview
    let question : String
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
    init(interview: Interview, question : String) {
        self.interview = interview
        self.question = question
        super.init(nibName : nil, bundle : nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Audio Recorder"
        self.view.backgroundColor = UIColor.whiteColor()
        
        // Audio recorder.
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(URL: self.directoryURL()!, settings: recordSettings)
            if let a = audioRecorder {
                a.prepareToRecord()
                a.delegate = self
                a.meteringEnabled = true
            }
        } catch let error {
            print(error)
        }
        
        // Create views.
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.greenColor()
        self.view.addSubview(containerView)
        
        let introTextLabel = UILabel()
        introTextLabel.text = self.question
        introTextLabel.numberOfLines = 0
        containerView.addSubview(introTextLabel)
        introTextLabel.textAlignment = .Center
        
        let startButton = UIButton(type: .System)
        startButton.setTitle("Start Recording", forState: .Normal)
        containerView.addSubview(startButton)
        
        let timeTextLabel = UILabel()
        timeTextLabel.numberOfLines = 0
        containerView.addSubview(timeTextLabel)
        timeTextLabel.textAlignment = .Center
        
        // Navigation bar Save button.
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(RecorderViewController.onSaveButtonClick))
        self.navigationItem.rightBarButtonItem = saveButton
        
        // Create view constraints.
        
        let outerInset = 20
        let largeSpacing = 20
        
        containerView.snp_makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.5)
            make.centerX.centerY.equalTo(self.view)
        }
        introTextLabel.snp_makeConstraints { (make) in
            make.top.left.right.equalTo(containerView).inset(outerInset)
        }
        startButton.snp_makeConstraints { (make) in
            make.top.equalTo(introTextLabel.snp_bottom).offset(largeSpacing)
            make.centerX.equalTo(containerView)
        }
        timeTextLabel.snp_makeConstraints { (make) in
            make.top.equalTo(startButton.snp_bottom).offset(largeSpacing)
            make.centerX.bottom.equalTo(containerView).inset(outerInset)
        }
        
        // Reactive bindings.
        
        startButton.rac_signalForControlEvents(.TouchUpInside).subscribeNext { _ in
            if let recorder = self.audioRecorder {
                if (recorder.recording) {
                    // Stop recording.
                    recorder.stop()
                    do {
                        try AVAudioSession.sharedInstance().setActive(false)
                    } catch {
                    }
                } else {
                    // Start recording.
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch {
                    }
                    recorder.record()
                }
            }
        }
        
        // Update the timer button.
        RACSignal.interval(0.05, onScheduler:RACScheduler.mainThreadScheduler())
            .subscribeNext { _ in
                if let recorder = self.audioRecorder where recorder.recording {
                    let seconds = Int(recorder.currentTime) % 60
                    let minutes = Int(recorder.currentTime) / 60
                    let timeString =  String(format: "%0.2d:%0.2d", minutes, seconds)
                    timeTextLabel.text = "\(timeString)"
                }
        }
        
        // Handle Done button presses.
        self.rac_signalForSelector(#selector(RecorderViewController.onSaveButtonClick))
            .subscribeNext { (next : AnyObject!) in
                if let recorder = self.audioRecorder {
                    // Update the model with the new attachment.
                    let attachment = Attachment(questionText: self.question, tags: [], recordingUrl: recorder.url)
                    let update = InterviewUpdate(attachments: self.interview.attachments + [attachment])
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview, interviewUpdate: update)
                    
                    self.navigationController?.popViewControllerAnimated(true)
                }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        print("🎶 Recording finished \(recorder.url)")
    }
    
    func directoryURL() -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory = urls[0] as NSURL
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let dateString = formatter.stringFromDate(NSDate())
        
        let soundURL = documentDirectory.URLByAppendingPathComponent("sound-\(dateString).wav")
        return soundURL
    }
    
    func onSaveButtonClick() {}

}
