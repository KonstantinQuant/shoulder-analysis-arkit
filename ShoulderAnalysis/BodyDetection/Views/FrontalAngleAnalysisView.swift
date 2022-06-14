//
//  FrontalAngleAnalysisView.swift
//  BodyDetection
//
//  Created by Konstantin Kuchenmeister on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit


class FrontalAngleAnalysisView: UIView {
    
    var points: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var path = UIBezierPath()
    
    var plane = UIBezierPath()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        path.removeAllPoints()
        plane.removeAllPoints()
        
        
        path = UIBezierPath(ovalIn: CGRect(x: points[0].x, y: points[0].y, width: CGFloat(10), height: CGFloat(10)))
        UIColor.red.setFill()
        path.fill()
        
        path = UIBezierPath(ovalIn: CGRect(x: points[1].x, y: points[1].y, width: CGFloat(10), height: CGFloat(10)))
        UIColor.red.setFill()
        path.fill()
        
        plane.move(to: CGPoint(x: points[0].x, y: points[0].y))
        plane.addLine(to: CGPoint(x: points[1].x, y: points[1].y))
        
        plane.move(to: CGPoint(x: points[1].x, y: points[1].y))
        plane.addLine(to: CGPoint(x: points[1].x, y: points[2].y))
       
        
        UIColor.green.set()
        plane.lineWidth = 3
        plane.stroke()
        
        
        path.close()
        plane.close()
    }
}



