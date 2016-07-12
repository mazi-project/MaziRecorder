//
//  MaziUIButton.swift
//  MaziRecorder
//
//  Created by Lutz on 10/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit

class MaziUIButton : UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = MaziStyle.buttonBgColor
        self.setTitleColor(MaziStyle.buttonTextColor, forState: .Normal)
        self.layer.cornerRadius = MaziStyle.cornerRadius
        
        //add border
        //self.layer.borderColor = MaziStyle.buttonBorderColor.CGColor
        //self.layer.borderWidth = MaziStyle.borderWidth
        
        //add shadow
        /*self.layer.shadowColor = UIColor.blackColor().CGColor;
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 1
        self.layer.shadowOffset = CGSizeMake(1, 1)
        self.layer.masksToBounds = false*/
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
        
        //self.back
        self.setTitleColor(MaziStyle.buttonTextColor, forState: .Selected)
        
        self.setBackgroundImage(MaziUIRecordingButton.imageWithColor(MaziStyle.buttonBgColor), forState: .Selected)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelectState(selected : Bool) {
        self.selected = selected
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
