//
//  SoundCircle.swift
//  MaziRecorder
//
//  Created by Lutz on 09/07/16.
//  Copyright © 2016 Erich Grunewald. All rights reserved.
//

import UIKit

class SoundCircle: UIView {
    
    var volume : Float = 0
    var peak : Float = 0
    
    override init(frame : CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setValues(volume : Float, peak : Float) {
        self.volume = volume
        self.peak = peak
    }
    
    override func drawRect(rect: CGRect) {
        
        let offset = CGFloat(2);
        
        let widthVol = self.bounds.width * CGFloat(volume) - offset*2
        let heightVol = self.bounds.height * CGFloat(volume) - offset*2
        
        let xVol = self.bounds.width/2 - widthVol/2 + offset/2.0
        let yVol = self.bounds.height/2 - heightVol/2 + offset/2.0
        
        let widthPeak = self.bounds.width * CGFloat(peak) - offset*2
        let heightPeak = self.bounds.height * CGFloat(peak) - offset*2
        
        let xPeak = self.bounds.width/2 - widthPeak/2 + offset/2.0
        let yPeak = self.bounds.height/2 - heightPeak/2 + offset/2.0
        
        
        let context = UIGraphicsGetCurrentContext()
        
        // draw peak volume
        let rectangle = CGRect(x: xPeak, y: yPeak, width: widthPeak, height: heightPeak)
        
        //CGContextSetFillColorWithColor(context, UIColor.redColor().CGColor)
        CGContextSetStrokeColorWithColor(context, UIColor.darkGrayColor().CGColor)
        CGContextSetLineWidth(context, 1)
        CGContextStrokeEllipseInRect(context, rectangle)
        //CGContextDrawPath(context, .FillStroke)
        
        // draw volume
        let rectangle2 = CGRect(x: xVol, y: yVol, width: widthVol, height: heightVol)
        let fillcolor = UIColor.redColor().colorWithAlphaComponent(CGFloat(self.volume))
        
        CGContextSetFillColorWithColor(context, fillcolor.CGColor)
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextSetLineWidth(context, 2)
        CGContextAddEllipseInRect(context, rectangle2)
        //CGContextStrokeEllipseInRect(context, rectangle2)
        CGContextDrawPath(context, .FillStroke)
        
    }
}
