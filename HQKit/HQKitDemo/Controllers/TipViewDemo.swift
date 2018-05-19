//
//  TipViewDemo.swift
//  HQKitDemo
//
//  Created by Magee on 2018/5/19.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit
import HQFoundation
import HQKit

class TipViewDemo: BaseDemo {
    var infoBtn: UIButton!
    var warningBtn: UIButton!
    var dangerBtn: UIButton!
    var successBtn: UIButton!
    
    var tip: TipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tip = TipView()
        view.backgroundColor = UIColor.white
        
        infoBtn = initBtn(title: "Info")
        infoBtn.hq.addEvent({
            self.tip?.show(tips: "This is info message!!!", level: .info)
        }, .touchUpInside)
        
        warningBtn = initBtn(title: "Warning")
        warningBtn.hq.addEvent({
            self.tip?.show(tips: "This is warning message!!!", level: .warning)
        }, .touchUpInside)
        
        dangerBtn = initBtn(title: "Danger")
        dangerBtn.hq.addEvent({
            self.tip?.show(tips: "This is danger message!!!", level: .danger)
        }, .touchUpInside)
        
        successBtn = initBtn(title: "Success")
        successBtn.hq.addEvent({
            self.tip?.show(tips: "This is success message!!!", level: .success)
        }, .touchUpInside)
        
        infoBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-104-[info]-padding-[warning]-padding-[danger]-padding-[success]", options: .alignAllCenterX, metrics: ["padding": 24], views: ["info": infoBtn, "warning": warningBtn, "danger": dangerBtn, "success": successBtn]))
        
    }
    
}
