//
//  MaziUIButton.swift
//  MaziRecorder
//
//  Created by Lutz on 10/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit
import ReactiveCocoa

class MaziUIButton : UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = MaziStyle.buttonBgColor
        self.setTitleColor(MaziStyle.buttonTextColor, forState: .Normal)
        self.layer.cornerRadius = MaziStyle.cornerRadius
        
        self.rac_valuesForKeyPath("enabled", observer: self)
            .toSignalProducer()
            .observeOn(UIScheduler())
            .startWithNext { [weak self] next in
                guard let `self` = self,
                enabled = next as? Bool else { return }
                self.alpha = enabled ? 1 : 0.2
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setTitle(title: String?, forState state: UIControlState) {
        super.setTitle(title, forState: state)
        
        self.titleLabel!.font = UIFont.systemFontOfSize(16.0, weight: UIFontWeightBold)
    }
}

class MaziUIRecordingButton : MaziUIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setBackgroundImage(MaziUIRecordingButton.imageWithColor(MaziStyle.buttonBgColor), forState: .Selected)
        self.setTitleColor(MaziStyle.buttonTextColor, forState: .Selected)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func imageWithColor(color : UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0);
        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext();
    
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, rect);
    
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    
        return image;
    }
}
