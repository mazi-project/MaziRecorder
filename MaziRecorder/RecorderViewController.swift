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
import ReactiveSwift
import ReactiveCocoa
import enum Result.NoError

class RecorderViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    let recordSettings = [
        AVSampleRateKey : NSNumber(value: Float(44100.0) as Float),
        AVFormatIDKey : NSNumber(value: Int32(kAudioFormatLinearPCM) as Int32),
        AVNumberOfChannelsKey : NSNumber(value: 1 as Int32),
        AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue) as Int32)
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
        self.interview <~ InterviewStore.sharedInstance.interviewSignal(interview.identifier).skipNil()
        
        //get attachment if there is already on saved
        if let found = self.interview.value.attachments.index(where: {$0.questionText == self.question}) {
            self.attachment = self.interview.value.attachments[found]
        } else {
            self.attachment = Attachment(questionText: self.question, tags: [], recordingUrl: URL(fileURLWithPath: ""))
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
            try audioRecorder = AVAudioRecorder(url: self.directoryURL()!, settings: recordSettings)
            if let a = audioRecorder {
                a.prepareToRecord()
                a.delegate = self
                a.isMeteringEnabled = true
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
        introTextLabel.textAlignment = .center
        
        let startButton = MaziUIRecordingButton(type: .system)
        startButton.setTitle("Start", for: UIControlState())
        containerView.addSubview(startButton)
        
        let timeTextLabel = MaziUILabel()
        timeTextLabel.numberOfLines = 1
        timeTextLabel.text = self.stringWithTime(attachment?.recordingDuration ?? 0)
        timeTextLabel.textAlignment = .center
        timeTextLabel.font = UIFont.systemFont(ofSize: 60)
        containerView.addSubview(timeTextLabel)
        
        containerView.addSubview(soundVisualizer)
        
        let tagsLabel = MaziUIInputLabel()
        tagsLabel.text = "Tags"
        tagsLabel.textAlignment = .left
        containerView.addSubview(tagsLabel)
        
        let tagsField = MaziUITextField()
        tagsField.text = self.attachment?.tags.joined(separator: " ")
        tagsField.attributedPlaceholder = NSAttributedString(string: "Tag question by space seperated tags")
        tagsField.keyboardType = UIKeyboardType.asciiCapable
        containerView.addSubview(tagsField)
        
        // Navigation bar Save button.
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(RecorderViewController.onSaveButtonClick))
        self.navigationItem.rightBarButtonItem = saveButton
        
        // Create view constraints.
        
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
        startButton.snp.makeConstraints { (make) in
            make.top.equalTo(introTextLabel.snp.bottom).offset(MaziStyle.paragraphSpacing)
            make.centerX.equalTo(containerView)
            make.width.equalTo(MaziStyle.buttonSize.width)
            make.height.equalTo(MaziStyle.buttonSize.height)
        }
        timeTextLabel.snp.makeConstraints { (make) in
            make.top.equalTo(startButton.snp.bottom).offset(MaziStyle.largeSpacing)
            make.centerX.equalTo(containerView)
        }
        soundVisualizer.snp.makeConstraints { (make) in
            make.top.equalTo(timeTextLabel.snp.bottom).offset(MaziStyle.largeSpacing)
            make.width.equalTo(180)
            make.height.equalTo(180)
            make.centerX.equalTo(containerView)
        }
        tagsLabel.snp.makeConstraints { (make) in
            make.top.equalTo(soundVisualizer.snp.bottom).offset(MaziStyle.paragraphSpacing)
            make.left.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        tagsField.snp.makeConstraints { (make) in
            make.top.equalTo(tagsLabel.snp.bottom).offset(MaziStyle.spacing)
            make.left.right.bottom.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        // Reactive bindings.
        
        // Update the view whenever the model changes.
        interview.producer
            .observe(on: UIScheduler())
            .startWithValues { (newInterview : Interview) in
                
                
        }
        
        tagsField.reactive.continuousTextValues
            .observeValues { [weak self] next in
                guard let `self` = self else { return }
                
                if let tags = next {
                    // make sure that there are only asci chars and spaces in the tag string
                    let matches = matchesForRegexInText("[a-zA-Z0-9_ ]", text : tags)
                    let tagString = matches.joined(separator: "")
                    tagsField.text = tagString
                    
                    self.tags = tagString.characters.split{ $0 == " " }.map(String.init)
                }
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
        
        startButton.reactive.trigger(for: .touchUpInside)
            .observeValues { [weak self] _ in
                guard let `self` = self else { return }
                
                if let recorder = self.audioRecorder {
                    if (recorder.isRecording) {
                        self.hasRecorderd = true
                        self.stopRecording()
                        startButton.setTitle("Start", for: .normal)
                        startButton.isEnabled = false;
                    } else {
                        self.startRecording()
                        startButton.setTitle("Stop", for: .normal)
                    }
                }
        }
        
        // Update the time label and the visualisation.
        timerDisposable = QueueScheduler.main.schedule(after: Date(), interval: 0.1) {
            if let recorder = self.audioRecorder, recorder.isRecording {
                timeTextLabel.text = "\(self.stringWithTime(Int(recorder.currentTime)))"
                
                self.updateMeter()
            }
        }
        
        // Handle Done button presses.
        self.reactive.trigger(for: #selector(RecorderViewController.onSaveButtonClick))
            .observe(on: UIScheduler())
            .observeValues { [weak self] next in
                guard let `self` = self else { return }
                
                if let recorder = self.audioRecorder {
                    // Get the duration of the recording (in seconds).
                    let asset = AVURLAsset(url: recorder.url)
                    let recordingDuration = Int(CMTimeGetSeconds(asset.duration))
                    
                    // Update the model with the new attachment.
                    let attachment = Attachment(questionText: self.question, tags: self.tags, recordingUrl: recorder.url, recordingDuration: recordingDuration)
                    InterviewStore.sharedInstance.updateAttachment(self.interview.value, attachment: attachment)
                    
                    _ = self.navigationController?.popViewController(animated: true)
                }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
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
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("🎶 Recording finished \(recorder.url)")
    }
    
    func directoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let dateString = formatter.string(from: Date())
        
        let soundURL = documentDirectory.appendingPathComponent("sound-\(dateString).wav")
        return soundURL
    }
    
    func onSaveButtonClick() {}
    
    func updateMeter() {
        if let recorder = self.audioRecorder {
            recorder.updateMeters()
            let averageVolume = recorder.averagePower(forChannel: 0)
            let peakVolume = recorder.peakPower(forChannel: 0)
            
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
    
    func stringWithTime(_ time: Int) -> String {
        let seconds = time % 60
        let minutes = time / 60
        return String(format: "%0.2d:%0.2d", minutes, seconds)
    }

}
