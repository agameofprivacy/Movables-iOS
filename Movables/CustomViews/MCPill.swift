//
//  MCPill.swift
//  Movables
//
//  MIT License
//
//  Copyright (c) 2018 Eddie Chen
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

class MCPill: UIView {

    var baseView: UIView!
    var pillContainerView: UIView!
    var circleMask: UIView!
    var characterLabel: UILabel!
    var imageView: UIImageView!
    var bodyLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(frame: CGRect, character: String?, image: UIImage?, body: String, color: UIColor?) {
        super.init(frame: frame)
        
        clipsToBounds = false
        
        baseView = UIView(frame: .zero)
        baseView.translatesAutoresizingMaskIntoConstraints = false
        baseView.layer.shadowColor = UIColor.black.cgColor
        baseView.layer.shadowOpacity = 0.15
        baseView.layer.shadowRadius = 8
        baseView.layer.shadowOffset = CGSize(width: 0, height: 0)
        addSubview(baseView)
        
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[baseView]|", options: .directionLeadingToTrailing, metrics: nil, views: ["baseView":baseView]))
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[baseView]|", options: .alignAllCenterY, metrics: nil, views: ["baseView":baseView]))

        
        pillContainerView = UIView(frame: .zero)
        pillContainerView.translatesAutoresizingMaskIntoConstraints = false
        pillContainerView.backgroundColor = color ?? .black
        pillContainerView.layer.cornerRadius = 14
        pillContainerView.clipsToBounds = true
        baseView.addSubview(pillContainerView)

    baseView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[pillContainerView]|", options: .alignAllCenterY, metrics: nil, views: ["pillContainerView": pillContainerView]))
    baseView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[pillContainerView]|", options: .alignAllCenterX, metrics: nil, views: ["pillContainerView": pillContainerView]))

        circleMask = UIView(frame: .zero)
        circleMask.translatesAutoresizingMaskIntoConstraints = false
        circleMask.layer.borderWidth = 1
        circleMask.layer.borderColor = UIColor.white.cgColor
        circleMask.layer.cornerRadius = 14
        circleMask.clipsToBounds = true
        circleMask.backgroundColor = .white
        pillContainerView.addSubview(circleMask)
        
        characterLabel = UILabel(frame: .zero)
        characterLabel.translatesAutoresizingMaskIntoConstraints = false
        characterLabel.font = UIFont.systemFont(ofSize: 13).bold
        characterLabel.numberOfLines = 1
        characterLabel.textAlignment = .center
        characterLabel.text = character ?? ""
        characterLabel.textColor = Theme().textColor
        circleMask.addSubview(characterLabel)
        
        pillContainerView.addConstraints([
            NSLayoutConstraint(item: characterLabel, attribute: .centerX, relatedBy: .equal, toItem: circleMask, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: characterLabel, attribute: .centerY, relatedBy: .equal, toItem: circleMask, attribute: .centerY, multiplier: 1, constant: 0)
            ])
        
        imageView = UIImageView(image: image ?? nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        circleMask.addSubview(imageView)
        
        circleMask.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|", options: .alignAllCenterY, metrics: nil, views: ["imageView": imageView]))
        circleMask.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|", options: .alignAllCenterX, metrics: nil, views: ["imageView": imageView]))

        
        bodyLabel = UILabel(frame: .zero)
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.numberOfLines = 1
        bodyLabel.font = UIFont.systemFont(ofSize: 15).bold
        bodyLabel.textColor = .white
        bodyLabel.text = body
        bodyLabel.textAlignment = .natural
        pillContainerView.addSubview(bodyLabel)
        
        pillContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[circleMask(28)]-6-[bodyLabel]-11-|", options: .directionLeadingToTrailing, metrics: nil, views: ["circleMask": circleMask, "bodyLabel": bodyLabel]))
        
            pillContainerView.addConstraint(NSLayoutConstraint(item: bodyLabel, attribute: .firstBaseline, relatedBy: .equal, toItem: characterLabel, attribute: .firstBaseline, multiplier: 1, constant: 1))
        pillContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[circleMask(28)]|", options: .alignAllCenterX, metrics: nil, views: ["circleMask": circleMask]))

        
    }
}
