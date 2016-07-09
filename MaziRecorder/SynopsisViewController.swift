//
//  SynopsisViewController.swift
//  MaziRecorder
//
//  Created by Lutz on 09/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit

class SynopsisViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let interview : Interview
    
    var currentImage: UIImageView!
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    
    init(interview: Interview) {
        self.interview = interview
        super.init(nibName : nil, bundle : nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Interview Synopsis"
        self.view.backgroundColor = UIColor.whiteColor()
        
        // Create views.
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.greenColor()
        self.view.addSubview(containerView)
        
        let synopsisLabel = UILabel()
        synopsisLabel.text = "Synopsis:"
        containerView.addSubview(synopsisLabel)
        
        let synopsisField = UITextView()
        synopsisField.backgroundColor = UIColor.lightGrayColor()
        containerView.addSubview(synopsisField)
        
        let pictureButton = UIButton(type: .System)
        pictureButton.setTitle("Take Picture", forState: .Normal)
        containerView.addSubview(pictureButton)
        
        currentImage = UIImageView()
        containerView.addSubview(currentImage)
        
        // Create Constraints
        
        let outerInset = 20
        let spacing = 10
        let largeSpacing = 20
        
        containerView.snp_makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.5)
            make.centerX.centerY.equalTo(self.view)
        }
        
        synopsisLabel.snp_makeConstraints { (make) in
            make.top.equalTo(containerView.snp_top).offset(largeSpacing)
            make.left.right.equalTo(containerView).inset(outerInset)
        }
        
        synopsisField.snp_makeConstraints { (make) in
            make.top.equalTo(synopsisLabel.snp_bottom).offset(spacing)
            make.left.right.equalTo(containerView).inset(outerInset)
            make.height.equalTo(120)
        }
        
        pictureButton.snp_makeConstraints { (make) in
            make.top.equalTo(synopsisField.snp_bottom).offset(largeSpacing)
            make.width.equalTo(120)
            make.centerX.equalTo(containerView)
        }
        
        currentImage.snp_makeConstraints { (make) in
            make.top.equalTo(pictureButton.snp_bottom).offset(largeSpacing)
            make.width.equalTo(100)
            make.height.equalTo(100)
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(outerInset)
        }
        
        
        // Reactive bindings.
        let maxLength = 1000
        synopsisField.rac_textSignal()
            .subscribeNext { (next : AnyObject!) in
                if let text = next as? NSString {
                    // Make sure text field doesn't surpass a certain number of characters.
                    if text.length > maxLength {
                        synopsisField.text = text.substringToIndex(maxLength)
                    }
                    
                    // Store the new name in the model.
                    let update = InterviewUpdate(text: synopsisField.text)
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview, interviewUpdate: update)
                }
        }
        
        // Take picture
        pictureButton.rac_signalForControlEvents(.TouchUpInside).subscribeNext { _ in
            self.takePicture()
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
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview, interviewUpdate: update)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
