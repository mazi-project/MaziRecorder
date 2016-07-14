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
import enum Result.NoError

class RecorderViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    let recordSettings = [
        AVSampleRateKey : NSNumber(float: Float(44100.0)),
        AVFormatIDKey : NSNumber(int: Int32(kAudioFormatLinearPCM)),
        AVNumberOfChannelsKey : NSNumber(int: 1),
        AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))
    ]
    
    let interview : MutableProperty<Interview>
    let question : String
    
    var attachment : Attachment?
    
    var tags = [String]()
    
    var audioPlayer : AVAudioPlayer?
    var audioRecorder : AVAudioRecorder?
    var hasRecorderd = false
    
    let soundVisualizer = SoundCircle()
    var timerDisposable : Disposable?
    
    init(interview: Interview, question : String) {
        self.interview = MutableProperty<Interview>(interview)
        self.question = question
        
        super.init(nibName : nil, bundle : nil)
        
        // Sync the view's interview with the model.
        self.interview <~ InterviewStore.sharedInstance.interviewSignal(interview.identifier).ignoreNil()
        
        //get attachment if there is already on saved
        if let found = self.interview.value.attachments.indexOf({$0.questionText == self.question}) {
            self.attachment = self.interview.value.attachments[found]
        } else {
            self.attachment = Attachment(questionText: self.question, tags: [], recordingUrl: NSURL(fileURLWithPath: ""))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Audio Recorder"
        self.view.backgroundColor = MaziStyle.backgroundColor
        
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
        let scrollView = UIScrollView()
        self.view.addSubview(scrollView)
        
        let containerView = UIView()
        scrollView.addSubview(containerView)
        
        let introTextLabel = MaziUILabel()
        introTextLabel.text = self.question
        containerView.addSubview(introTextLabel)
        introTextLabel.textAlignment = .Center
        
        let startButton = MaziUIRecordingButton(type: .System)
        startButton.setTitle("Start", forState: .Normal)
        containerView.addSubview(startButton)
        
        let timeTextLabel = MaziUILabel()
        timeTextLabel.numberOfLines = 1
        timeTextLabel.text = self.stringWithTime(attachment?.recordingDuration ?? 0)
        timeTextLabel.textAlignment = .Center
        timeTextLabel.font = UIFont.systemFontOfSize(60)
        containerView.addSubview(timeTextLabel)
        
        containerView.addSubview(soundVisualizer)
        
        let tagsLabel = MaziUIInputLabel()
        tagsLabel.text = "Tags"
        tagsLabel.textAlignment = .Left
        containerView.addSubview(tagsLabel)
        
        let tagsField = MaziUITextField()
        tagsField.text = self.attachment?.tags.joinWithSeparator(" ")
        tagsField.attributedPlaceholder = NSAttributedString(string: "Tag question by space seperated tags")
        tagsField.keyboardType = UIKeyboardType.ASCIICapable
        containerView.addSubview(tagsField)
        
        // Navigation bar Save button.
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(RecorderViewController.onSaveButtonClick))
        self.navigationItem.rightBarButtonItem = saveButton
        
        // Create view constraints.
        
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
        startButton.snp_makeConstraints { (make) in
            make.top.equalTo(introTextLabel.snp_bottom).offset(MaziStyle.paragraphSpacing)
            make.centerX.equalTo(containerView)
            make.width.equalTo(120)
        }
        timeTextLabel.snp_makeConstraints { (make) in
            make.top.equalTo(startButton.snp_bottom).offset(MaziStyle.largeSpacing)
            make.centerX.equalTo(containerView)
        }
        soundVisualizer.snp_makeConstraints { (make) in
            make.top.equalTo(timeTextLabel.snp_bottom).offset(MaziStyle.largeSpacing)
            make.width.equalTo(180)
            make.height.equalTo(180)
            make.centerX.equalTo(containerView)
        }
        tagsLabel.snp_makeConstraints { (make) in
            make.top.equalTo(soundVisualizer.snp_bottom).offset(MaziStyle.paragraphSpacing)
            make.left.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        tagsField.snp_makeConstraints { (make) in
            make.top.equalTo(tagsLabel.snp_bottom).offset(MaziStyle.spacing)
            make.left.right.bottom.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        // Reactive bindings.
        
        // Update the view whenever the model changes.
        interview.producer
            .observeOn(UIScheduler())
            .startWithNext { (newInterview : Interview) in
                
                
        }
        
        tagsField.rac_textSignal()
            .toSignalProducer()
            .startWithNext { [unowned self] next in
                if let tags = next as? NSString {
                    // make sure that there are only asci chars and spaces in the tag string
                    let matches = matchesForRegexInText("[a-zA-Z0-9_ ]", text : String(tags))
                    let tagString = matches.joinWithSeparator("")
                    tagsField.text = tagString
                    
                    self.tags = tagString.characters.split{ $0 == " " }.map(String.init)
                }
        }
        
        RACSignal.merge([
            NSNotificationCenter.defaultCenter().rac_addObserverForName(UIKeyboardWillShowNotification, object: nil),
            NSNotificationCenter.defaultCenter().rac_addObserverForName(UIKeyboardWillHideNotification, object: nil)
            ])
            .takeUntil(self.rac_willDeallocSignal())
            .toSignalProducer()
            .observeOn(UIScheduler())
            .startWithNext { [unowned self] next in
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
        
        startButton.rac_signalForControlEvents(.TouchUpInside)
            .toSignalProducer()
            .startWithNext { [unowned self] _ in
                if let recorder = self.audioRecorder {
                    if (recorder.recording) {
                        self.hasRecorderd = true
                        self.stopRecording()
                        startButton.setTitle("Start", forState: .Normal)
                    } else {
                        self.startRecording()
                        startButton.setTitle("Stop", forState: .Normal)
                    }
                }
        }
        
        // Update the time label and the visualisation.
        timerDisposable = QueueScheduler.mainQueueScheduler.scheduleAfter(NSDate(), repeatingEvery: 0.1) {
            if let recorder = self.audioRecorder where recorder.recording {
                timeTextLabel.text = "\(self.stringWithTime(Int(recorder.currentTime)))"
                
                self.updateMeter()
            }
        }
        
        // Handle Done button presses.
        self.rac_signalForSelector(#selector(RecorderViewController.onSaveButtonClick))
            .toSignalProducer()
            .observeOn(UIScheduler())
            .startWithNext { [unowned self] next in
                if let recorder = self.audioRecorder {
                    // Get the duration of the recording (in seconds).
                    let asset = AVURLAsset(URL: recorder.url)
                    let recordingDuration = Int(CMTimeGetSeconds(asset.duration))
                    
                    // Update the model with the new attachment.
                    let attachment = Attachment(questionText: self.question, tags: self.tags, recordingUrl: recorder.url, recordingDuration: recordingDuration)
                    InterviewStore.sharedInstance.updateAttachment(self.interview.value, attachment: attachment)
                    
                    self.navigationController?.popViewControllerAnimated(true)
                }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
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
            self.soundVisualizer.setValues(0, peak: 0)
            self.soundVisualizer.setNeedsDisplay()
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
            
            let baseLevel = Float(80.0)
            
            let valVol = min( (baseLevel + averageVolume) / baseLevel, Float(1.0))
            let valPeak = min( (baseLevel + peakVolume) / baseLevel, Float(1.0))
            
            //draw circle
            self.soundVisualizer.setValues(valVol, peak: valPeak)
            self.soundVisualizer.setNeedsDisplay()
            
            //print("\(valVol):\(valPeak)")
        }
    }
    
    func getTags() {
        
    }
    
    func stringWithTime(time: Int) -> String {
        let seconds = time % 60
        let minutes = time / 60
        return String(format: "%0.2d:%0.2d", minutes, seconds)
    }

}
