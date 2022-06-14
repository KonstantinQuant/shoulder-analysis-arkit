//
//  HumanJointsView.swift
//  BodyDetection
//
//  Created by Konstantin Kuchenmeister on 1/1/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit


class HumanJointsView: UIView {
    
    var points: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var path = UIBezierPath()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        path.removeAllPoints()
        self.points.forEach { point in
            path = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: CGFloat(3), height: CGFloat(3)))
            UIColor.green.setFill()
            path.fill()
        }
    }
}



