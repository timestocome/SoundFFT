//
//  GraphView.swift
//  Sensors
//
//  Created by Linda Cobb on 9/22/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import UIKit


class GraphView: UIView
{
 
    // graph dimensions
    var area: CGRect!
    var maxPoints: Int!
    var height: CGFloat!
    
    // incoming data to graph
    var dataArrayX:[CGFloat]!
    
    
    // graph data points
    var x: CGFloat = 0.0
    var previousX:CGFloat = 0.0
    var mark:CGFloat = 0.0
    

    
    
    required init( coder aDecoder: NSCoder ){ super.init(coder: aDecoder) }

    override init(frame:CGRect){ super.init(frame:frame) }
    
    

    func setupGraphView() {
    
        area = frame
        maxPoints = Int(area.size.width)
        height = CGFloat(area.size.height)
       
        dataArrayX = [CGFloat](count:maxPoints, repeatedValue: 0.0)
    }
    
    
    
    
    
    
    
    func addX(x: UInt8){

        // scale incoming data and insert it into data array
        let xScaled = height - CGFloat(x) * 0.4
        
        dataArrayX.insert(xScaled, atIndex: 0)
        dataArrayX.removeLast()
        
        setNeedsDisplay()
    }
    
    
    
    override func drawRect(rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColor(context, [1.0, 0.0, 0.0, 1.0])

        for i in 1..<maxPoints {
            
            mark = CGFloat(i)
            
            // plot x
            CGContextMoveToPoint(context, mark-1, self.dataArrayX[i-1])
            CGContextAddLineToPoint(context, mark, self.dataArrayX[i])
            CGContextStrokePath(context)

        }
    }
    
}









