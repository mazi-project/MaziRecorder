//
//  MaziUiLabel.swift
//  MaziRecorder
//
//  Created by Lutz on 10/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit

class MaziUILabel : UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MaziUIInputLabel : MaziUILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.font = UIFont.boldSystemFontOfSize(16.0)
        self.textAlignment = NSTextAlignment.Right
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
