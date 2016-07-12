//
//  SynopsisViewController.swift
//  MaziRecorder
//
//  Created by Lutz on 09/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import SnapKit
import ReactiveCocoa

class SynopsisViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let interview : MutableProperty<Interview>
    
    var currentImage: UIImageView!
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    
    init(interview: Interview) {
        self.interview = MutableProperty<Interview>(interview)
        
        super.init(nibName : nil, bundle : nil)
        
        // Sync the view's interview with the model.
        self.interview <~ InterviewStore.sharedInstance.interviewSignal(interview.identifier).ignoreNil()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Interview Synopsis"
        self.view.backgroundColor = MaziStyle.backgroundColor
        
        // Create views.
        let containerView = UIView()
        self.view.addSubview(containerView)
        
        let synopsisLabel = MaziUILabel()
        synopsisLabel.text = "Synopsis"
        containerView.addSubview(synopsisLabel)
        
        let synopsisField = MaziUITextView()
        containerView.addSubview(synopsisField)
        
        let pictureButton = MaziUIButton(type: .System)
        pictureButton.setTitle("Take Picture", forState: .Normal)
        containerView.addSubview(pictureButton)
        
        currentImage = UIImageView()
        containerView.addSubview(currentImage)
        
        // Navigation bar Upload button.
        let uploadButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(SynopsisViewController.onUploadButtonClick))
        self.navigationItem.rightBarButtonItem = uploadButton
        
        // Create view constraints.
        
        containerView.snp_makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.5)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view.snp_top).offset(MaziStyle.containerOfssetY)
        }
        
        synopsisLabel.snp_makeConstraints { (make) in
            make.top.equalTo(containerView.snp_top).offset(MaziStyle.largeSpacing)
            make.left.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        synopsisField.snp_makeConstraints { (make) in
            make.top.equalTo(synopsisLabel.snp_bottom).offset(MaziStyle.spacing)
            make.left.right.equalTo(containerView).inset(MaziStyle.outerInset)
            make.height.equalTo(120)
        }
        
        pictureButton.snp_makeConstraints { (make) in
            make.top.equalTo(synopsisField.snp_bottom).offset(MaziStyle.largeSpacing)
            make.width.equalTo(120)
            make.centerX.equalTo(containerView)
        }
        
        currentImage.snp_makeConstraints { (make) in
            make.top.equalTo(pictureButton.snp_bottom).offset(MaziStyle.largeSpacing)
            make.width.equalTo(100)
            make.height.equalTo(100)
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        // Reactive bindings.
        
        // Update the view whenever the model changes.
        interview.producer
            .observeOn(UIScheduler())
            .startWithNext { (newInterview : Interview) in
                synopsisField.text = newInterview.text
                
                // Disable start button when either name or role is empty.
                uploadButton.enabled = newInterview.text.characters.count > 0 && newInterview.imageUrl.characters.count > 0
        }
        
        interview.producer.observeOn(UIScheduler())
            .map{ $0.imageUrl }
            .filter{ $0.characters.count > 0}
            .skipRepeats()
            .startWithNext{ (imageUrl : String) in
                if let url = NSURL(string: imageUrl) {
                    self.currentImage.image = UIImage(contentsOfFile: url.absoluteString)
                }
        }
        
        let maxLength = 1000
        synopsisField.rac_textSignal()
            .toSignalProducer()
            .startWithNext { next in
                if let text = next as? NSString {
                    // Make sure text field doesn't surpass a certain number of characters.
                    if text.length > maxLength {
                        synopsisField.text = text.substringToIndex(maxLength)
                    }
                    
                    // Store the new name in the model.
                    let update = InterviewUpdate(text: synopsisField.text)
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
        }
        
        // Take picture.
        pictureButton.rac_signalForControlEvents(.TouchUpInside)
            .toSignalProducer()
            .startWithNext { _ in
                self.takePicture()
        }
        
        // Handle upload.
        self.rac_signalForSelector(#selector(SynopsisViewController.onUploadButtonClick))
            .toSignalProducer()
            .observeOn(UIScheduler())
            .startWithNext { _ in
                let networkManager = NetworkManager()
                networkManager.sendInterviewToServer(self.interview.value)
                    .on(started: {
                        // Show spinner.
                    })
                    .on(failed: { error in
                        // Hide spinner.
                    })
                    .on(completed: {
                        // Hide spinner.
                        
                        // Show a popup saying the upload was successful.
                        let alertView = UIAlertView(title: "Success", message: "The interview was uploaded to the server.", delegate: nil, cancelButtonTitle: "Ok")
                        alertView.show()
                        
                        // Create a new interview for the starting view, and navigate back to it.
                        if let rootViewController = self.navigationController?.viewControllers.first as? ViewController {
                            rootViewController.interview.value = InterviewStore.sharedInstance.createInterview()
                            self.navigationController?.popToRootViewControllerAnimated(true)
                        }
                    })
                    .startWithNext({ interviewId in
                        // Store the new interview id in the model.
                        let update = InterviewUpdate(identifierOnServer: interviewId)
                        InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                    })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func takePicture() {
        if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
            if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
                imagePicker.delegate = self
                imagePicker.allowsEditing = false
                imagePicker.sourceType = .Camera
                imagePicker.cameraCaptureMode = .Photo
                presentViewController(imagePicker, animated: true, completion: {})
            } else {
                print("Rear camera doesn't exist")
            }
        } else {
            print("Camera inaccessable")
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("Got an image")
        imagePicker.dismissViewControllerAnimated(true, completion: {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.currentImage.image = image;
                
                //get path
                let imagePath = self.directoryURL()
                
                //save image
                let imageData = UIImageJPEGRepresentation(image, 0.6)
                if imageData!.writeToFile(imagePath, atomically: true) {
                    //add to interview
                    let update = InterviewUpdate(imageUrl: imagePath)
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
            }
        })
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        print("User canceled image")
        dismissViewControllerAnimated(true, completion: {
            // Anything you want to happen when the user selects cancel
        })
    }
    
    private func directoryURL() -> String {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory = urls[0] as NSURL
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let dateString = formatter.stringFromDate(NSDate())
        
        let imageURL = documentDirectory.URLByAppendingPathComponent("image-\(dateString).jpg")
        return imageURL.path ?? ""
    }
    
    func onUploadButtonClick() {}

}
