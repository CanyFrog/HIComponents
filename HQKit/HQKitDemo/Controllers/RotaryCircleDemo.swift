//
//  RotaryCircleDemo.swift
//  HQKitDemo
//
//  Created by HonQi on 2018/5/19.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import UIKit
import HQKit

class RotaryCircleDemo: BaseDemo {
    var circle = RotaryCircleView()
    lazy var autoShowBtn: UIButton = initBtn(title: "Auto Show")
    lazy var autoHideBtn: UIButton = initBtn(title: "Auto Hide")
    lazy var rotateBtn = initBtn(title: "Rotate")
    var sliderBar = UISlider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        circle.translatesAutoresizingMaskIntoConstraints = false
        sliderBar.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(circle)
        view.addSubview(sliderBar)
        
        sliderBar.hq.addEvent({ [weak self] in
            self?.circle.show(ratio: CGFloat((self?.sliderBar.value)!))
        }, [.touchDragInside, .touchDragOutside])
        
        autoShowBtn.hq.addEvent({ [weak self] in
            self?.circle.show()
        }, .touchUpInside)
        
        autoHideBtn.hq.addEvent({ [weak self] in
            self?.circle.hide()
        }, .touchUpInside)
        
        rotateBtn.hq.addEvent({ [weak self] in
            self?.circle.rotate()
        }, .touchUpInside)
        
        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.bounds.height/4),
            circle.widthAnchor.constraint(equalToConstant: 4),
            circle.heightAnchor.constraint(equalToConstant: 4),
            
            autoShowBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            autoShowBtn.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 24),
            autoHideBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            autoHideBtn.topAnchor.constraint(equalTo: autoShowBtn.topAnchor),
            
            sliderBar.topAnchor.constraint(equalTo: autoShowBtn.bottomAnchor, constant: 24),
            sliderBar.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width-48),
            sliderBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sliderBar.heightAnchor.constraint(equalToConstant: 10),
            
            rotateBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rotateBtn.topAnchor.constraint(equalTo: sliderBar.bottomAnchor, constant: 24)
            ])
    }
}
