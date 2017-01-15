//
//  MaziUIButton.swift
//  MaziRecorder
//
//  Created by Lutz on 10/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

class MaziUIButton : UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = MaziStyle.buttonBgColor
        self.setTitleColor(MaziStyle.buttonTextColor, for: UIControlState())
        self.layer.cornerRadius = MaziStyle.cornerRadius
        
        self.reactive.values(forKeyPath: "enabled")
            .observe(on: UIScheduler())
            .startWithValues { [weak self] next in
                guard let `self` = self,
                let enabled = next as? Bool else { return }
                self.alpha = enabled ? 1 : 0.2
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setTitle(_ title: String?, for state: UIControlState) {
        super.setTitle(title, for: state)
        
        self.titleLabel!.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightBold)
    }
}

class MaziUIRecordingButton : MaziUIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setBackgroundImage(MaziUIRecordingButton.imageWithColor(MaziStyle.buttonBgColor), for: .selected)
        self.setTitleColor(MaziStyle.buttonTextColor, for: .selected)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func imageWithColor(_ color : UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0);
        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext();
    
        context?.setFillColor(color.cgColor);
        context?.fill(rect);
    
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    
        return image!;
    }
}
