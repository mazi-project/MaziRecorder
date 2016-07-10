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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
