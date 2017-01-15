//
//  SynopsisViewController.swift
//  MaziRecorder
//
//  Created by Lutz on 09/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import SnapKit
import ReactiveSwift
import ReactiveCocoa
import NVActivityIndicatorView

class SynopsisViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NVActivityIndicatorViewable {
    
    let interview : MutableProperty<Interview>
    
    var currentImage: UIImageView!
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    
    init(interview: Interview) {
        self.interview = MutableProperty<Interview>(interview)
        
        super.init(nibName : nil, bundle : nil)
        
        // Sync the view's interview with the model.
        self.interview <~ InterviewStore.sharedInstance.interviewSignal(interview.identifier).skipNil()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Interview Synopsis"
        self.view.backgroundColor = MaziStyle.backgroundColor
        
        // Create views.
        let scrollView = UIScrollView()
        self.view.addSubview(scrollView)
        
        let containerView = UIView()
        scrollView.addSubview(containerView)
        
        let synopsisLabel = MaziUIInputLabel()
        synopsisLabel.text = "Synopsis"
        containerView.addSubview(synopsisLabel)
        
        let synopsisField = MaziUITextView()
        containerView.addSubview(synopsisField)
        
        let pictureButton = MaziUIButton(type: .system)
        pictureButton.setTitle("Take Picture", for: UIControlState())
        containerView.addSubview(pictureButton)
        
        currentImage = UIImageView()
        containerView.addSubview(currentImage)
        
        // Navigation bar Upload button.
        let uploadButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(SynopsisViewController.onUploadButtonClick))
        self.navigationItem.rightBarButtonItem = uploadButton
        
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
        
        synopsisLabel.snp.makeConstraints { (make) in
            make.top.equalTo(containerView.snp.top).offset(MaziStyle.largeSpacing)
            make.left.right.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        synopsisField.snp.makeConstraints { (make) in
            make.top.equalTo(synopsisLabel.snp.bottom).offset(MaziStyle.spacing)
            make.left.right.equalTo(containerView).inset(MaziStyle.outerInset)
            make.height.equalTo(120)
        }
        
        pictureButton.snp.makeConstraints { (make) in
            make.top.equalTo(synopsisField.snp.bottom).offset(MaziStyle.largeSpacing)
            make.width.equalTo(MaziStyle.buttonSize.width)
            make.height.equalTo(MaziStyle.buttonSize.height)
            make.centerX.equalTo(containerView)
        }
        
        currentImage.snp.makeConstraints { (make) in
            make.top.equalTo(pictureButton.snp.bottom).offset(MaziStyle.largeSpacing)
            make.width.equalTo(100)
            make.height.equalTo(100)
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(MaziStyle.outerInset)
        }
        
        // Reactive bindings.
        
        // Update the view whenever the model changes.
        interview.producer
            .observe(on: UIScheduler())
            .startWithValues { (newInterview : Interview) in
                synopsisField.text = newInterview.text
                
                // Disable start button when either name or role is empty.
                uploadButton.isEnabled = newInterview.text.characters.count > 0 && newInterview.imageUrl != nil
        }
        
        interview.producer.observe(on: UIScheduler())
            .map { $0.imageUrl }
            .filter { $0 != nil }
            .skipRepeats { $0 == $1 }
            .startWithValues { [weak self] imageUrl in
                guard let `self` = self else { return }
                
                if let url = imageUrl,
                    let imageData = try? Data(contentsOf: url) {
                    self.currentImage.image = UIImage(data: imageData)
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
        
        let maxLength = 1000
        synopsisField.reactive.continuousTextValues
            .observeValues { [weak self] text in
                guard let `self` = self else { return }

                // Make sure text field doesn't surpass a certain number of characters.
                synopsisField.text = String(text.characters.prefix(maxLength))
                
                // Store the new name in the model.
                let update = InterviewUpdate(text: .changed(synopsisField.text))
                InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
        }
        
        // Take picture.
        pictureButton.reactive.trigger(for: .touchUpInside)
            .observeValues { [weak self] _ in
                guard let `self` = self else { return }
                
                self.takePicture()
        }
        
        // Handle upload.
        self.reactive.trigger(for: #selector(SynopsisViewController.onUploadButtonClick))
            .observe(on: UIScheduler())
            .observeValues { [weak self] _ in
                guard let `self` = self else { return }
                
                let networkManager = NetworkManager()
                networkManager.sendInterviewToServer(self.interview.value)
                    .observe(on: UIScheduler())
                    .on(started: {
                        // Show spinner.
                        self.startAnimating(CGSize(width: 100, height: 100))
                    })
                    .on(failed: { error in
                        // Hide spinner.
                        self.stopAnimating()
                        let alertView = UIAlertView(title: "Error", message: "Could not connect to server.", delegate: nil, cancelButtonTitle: "Ok")
                        alertView.show()
                    })
                    .on(completed: {
                        // Hide spinner.
                        self.stopAnimating()
                        
                        // Show a popup saying the upload was successful.
                        let alertView = UIAlertView(title: "Success", message: "The interview was uploaded to the server.", delegate: nil, cancelButtonTitle: "Ok")
                        alertView.show()
                        
                        // Create a new interview for the starting view, and navigate back to it.
                        if let rootViewController = self.navigationController?.viewControllers.first as? ViewController {
                            rootViewController.setNewInterviewObservation(InterviewStore.sharedInstance.createInterview())
                            _ = self.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                    .startWithResult { result in
                        switch result {
                        case .success(let interviewId):
                            // Store the new interview id in the model.
                            let update = InterviewUpdate(identifierOnServer: .changed(interviewId))
                            InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                        case .failure(let error):
                            print("Upload failed with error \(error.localizedDescription)")
                        }
                    }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func takePicture() {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            if UIImagePickerController.availableCaptureModes(for: .front) != nil {
                imagePicker.delegate = self
                imagePicker.allowsEditing = false
                imagePicker.sourceType = .camera
                imagePicker.cameraCaptureMode = .photo
                present(imagePicker, animated: true, completion: {})
            } else {
                print("Rear camera doesn't exist")
            }
        } else {
            print("Camera inaccessable")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("Got an image")
        imagePicker.dismiss(animated: true, completion: {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.currentImage.image = image;
                
                //get path
                let imagePath = self.directoryURL()
                
                //save image
                let imageData = UIImageJPEGRepresentation(image, 0.6)
                if (try? imageData!.write(to: URL(fileURLWithPath: imagePath), options: [.atomic])) != nil {
                    //add to interview
                    let update = InterviewUpdate(imageUrl: .changed(URL(fileURLWithPath: imagePath)))
                    InterviewStore.sharedInstance.updateInterview(fromInterview: self.interview.value, interviewUpdate: update)
                }
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("User canceled image")
        dismiss(animated: true, completion: {
            // Anything you want to happen when the user selects cancel
        })
    }
    
    fileprivate func directoryURL() -> String {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let dateString = formatter.string(from: Date())
        
        let imageURL = documentDirectory.appendingPathComponent("image-\(dateString).jpg")
        return imageURL.path
    }
    
    func onUploadButtonClick() {}

}
