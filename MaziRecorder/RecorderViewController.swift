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
    
    let interview : MutableProperty<Interview>
    let question : String
    
    var tags = [String]()
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
    let soundVisualizer = SoundCircle()
    
    init(interview: Interview, question : String) {
        self.interview = MutableProperty<Interview>(interview)
        self.question = question
        
        super.init(nibName : nil, bundle : nil)
        
        // Sync the view's interview with the model.
        self.interview <~ InterviewStore.sharedInstance.interviewSignal(interview.identifier).ignoreNil()
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
        timeTextLabel.numberOfLines = 1
        timeTextLabel.text="00:00"
        containerView.addSubview(timeTextLabel)
        timeTextLabel.textAlignment = .Center
        
        containerView.addSubview(soundVisualizer)
        
        let tagsLabel = UILabel()
        tagsLabel.text = "Tags:"
        containerView.addSubview(tagsLabel)
        
        let tagsField = UITextField()
        tagsField.backgroundColor = UIColor.lightGrayColor()
        containerView.addSubview(tagsField)
        
        // Navigation bar Save button.
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(RecorderViewController.onSaveButtonClick))
        self.navigationItem.rightBarButtonItem = saveButton
        
        // Create view constraints.
        
        let outerInset = 20
        let largeSpacing = 20
        let spacing = 10
        
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
            make.centerX.equalTo(containerView)
        }
        soundVisualizer.snp_makeConstraints { (make) in
            make.top.equalTo(timeTextLabel.snp_bottom).offset(largeSpacing)
            make.width.equalTo(120)
            make.height.equalTo(120)
            make.centerX.equalTo(containerView)
        }
        tagsLabel.snp_makeConstraints { (make) in
            make.top.equalTo(soundVisualizer.snp_bottom).offset(spacing)
            make.left.right.equalTo(containerView).inset(outerInset)
        }
        tagsField.snp_makeConstraints { (make) in
            make.top.equalTo(tagsLabel.snp_bottom).offset(spacing)
            make.left.right.bottom.equalTo(containerView).inset(outerInset)
            make.height.equalTo(60)
        }
        
        // Reactive bindings.
        
        // Update the view whenever the model changes.
        interview.producer
            .observeOn(UIScheduler())
            .startWithNext { (newInterview : Interview) in
                
                /*if let found = self.interview.value.attachments.indexOf({$0.questionText == self.question}) {
                    let attachment = self.interview.value.attachments[found]
                }

                
                
                // Disable start button when either name or role is empty.
                saveButton.enabled = newInterview.name.characters.count > 0 && newInterview.role.characters.count > 0*/
        }
        
        tagsField.rac_textSignal()
            .toSignalProducer()
            .combinePrevious("")
            .startWithNext { (prev, new) in
                if  let newTags = new as? NSString {
                    // make sure that there are only asci chars and spaces in the tag string
                    let matches = matchesForRegexInText("[a-zA-Z0-9_ ]", text : String(newTags))
                    let tagString = matches.joinWithSeparator("")
                    tagsField.text = tagString
                    
                    self.tags = tagString.characters.split{$0 == " "}.map(String.init)
                }
            }
        
        
        startButton.rac_signalForControlEvents(.TouchUpInside).subscribeNext { _ in
            if let recorder = self.audioRecorder {
                if (recorder.recording) {
                    self.stopRecording()
                } else {
                    self.startRecording()
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
                    
                    self.updateMeter()
                }
        }
        
        // Handle Done button presses.
        self.rac_signalForSelector(#selector(RecorderViewController.onSaveButtonClick))
            .toSignalProducer()
            .observeOn(UIScheduler())
            .startWithNext { (next : AnyObject?) in
                if let recorder = self.audioRecorder {
                    // Update the model with the new attachment.
                    let attachment = Attachment(questionText: self.question, tags: self.tags, recordingUrl: recorder.url)
                    let update = InterviewUpdate(attachments: self.interview.value.attachments + [attachment])
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                    
                    self.navigationController?.popViewControllerAnimated(true)
                }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        stopRecording()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stopRecording() {
        if let recorder = self.audioRecorder {
            // Stop recording.
            recorder.stop()
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
            }
        }
    }
    
    func startRecording() {
        if let recorder = self.audioRecorder {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
            }
            recorder.record()
        }
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
    
    func updateMeter() {
        if let recorder = self.audioRecorder {
            recorder.updateMeters()
            let averageVolume = recorder.averagePowerForChannel(0)
            let peakVolume = recorder.peakPowerForChannel(0)
            
            let baseLevel : Float = 50.0
            
            let valVol = (baseLevel + averageVolume) / baseLevel
            let valPeak = (baseLevel + peakVolume) / baseLevel
            
            //draw circle
            self.soundVisualizer.setValues(valVol, peak: valPeak)
            self.soundVisualizer.setNeedsDisplay()
            
            //print("\(valVol):\(valPeak)")
        }
    }
    
    func getTags() {
        
    }

}
