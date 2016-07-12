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
        self.layer.borderColor = MaziStyle.buttonBorderColor.CGColor
        self.layer.borderWidth = MaziStyle.borderWidth
        
        //add shadow
        self.layer.shadowColor = UIColor.blackColor().CGColor;
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 1
        self.layer.shadowOffset = CGSizeMake(1, 1)
        self.layer.masksToBounds = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
