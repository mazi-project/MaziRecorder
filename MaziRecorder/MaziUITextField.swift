//
//  MaziUIView.swift
//  MaziRecorder
//
//  Created by Lutz on 10/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit

class MaziUITextField : UITextField {
    
    let padding = UIEdgeInsets(top: MaziStyle.textPadding, left: MaziStyle.textPadding, bottom: MaziStyle.textPadding, right: MaziStyle.textPadding);
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = MaziStyle.inputBgColor
        self.layer.borderColor = MaziStyle.borderColor.CGColor
        self.layer.borderWidth = MaziStyle.borderWidth
        self.layer.cornerRadius = MaziStyle.cornerRadius
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}
