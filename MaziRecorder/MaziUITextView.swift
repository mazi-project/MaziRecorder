//
//  MaziUITextInput.swift
//  MaziRecorder
//
//  Created by Lutz on 10/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit

class MaziUITextView : UITextView {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.textContainerInset = UIEdgeInsetsMake(MaziStyle.textPadding, MaziStyle.textPadding, MaziStyle.textPadding, MaziStyle.textPadding);
        
        self.backgroundColor = MaziStyle.inputBgColor
        self.layer.borderColor = MaziStyle.borderColor.CGColor
        self.layer.borderWidth = MaziStyle.borderWidth
        self.layer.cornerRadius = MaziStyle.cornerRadius
        
        self.font = UIFont.systemFontOfSize(CGFloat(MaziStyle.fontSize))
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
}
