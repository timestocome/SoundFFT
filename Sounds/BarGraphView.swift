//
//  BarGraphView.swift
//  Sounds
//
//  Created by Linda Cobb on 10/10/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import UIKit



class BarGraphView : UIView
{
    
    // graph dimensions
    var area: CGRect!
    let maxPoints = 128
    var height: CGFloat!
    var bar:CGRect!

    
    // incoming data to graph
    var dataArrayX:[Float]!
    
    // graph data points
    var x: CGFloat = 0.0
    var previousX:CGFloat = 0.0
    var mark:CGFloat = 0.0
    
    
    
    
    required init( coder aDecoder: NSCoder ){ super.init(coder: aDecoder) }

    override init(frame:CGRect){ super.init(frame:frame) }
    
    
    // get graph size and set up data array
    func setupGraphView() {
        
        area = frame
        height = CGFloat(area.size.height)
        
        dataArrayX = [Float](count:maxPoints, repeatedValue: 0.0)
    }
    
    
    
    
    
    
    
    func addX(x: Float){
        
        dataArrayX.insert(x, atIndex: 0)
        dataArrayX.removeLast()
        
        // update graph
        setNeedsDisplay()
    }
    
    
    
    override func drawRect(rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColor(context, [1.0, 0.0, 0.0, 1.0])
        
        // plot frequency
        
        
        for i in 1..<maxPoints {
            
            mark = CGFloat(i) * 3.0
            
            // plot x
            bar = CGRectMake(mark, height, 2.0, CGFloat(-dataArrayX[i]))
            UIRectFill(bar)
            
        }

        
    }
    
    
}










