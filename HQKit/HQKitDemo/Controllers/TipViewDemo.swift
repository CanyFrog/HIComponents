//
//  TipViewDemo.swift
//  HQKitDemo
//
//  Created by HonQi on 2018/5/19.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
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
        
        infoBtn = initBtn(title: "Info")
        infoBtn.hq.addEvent({
            self.tip?.show(tips: "This is info message!!!", level: .info)
        }, .touchUpInside)
        
        warningBtn = initBtn(title: "Warning")
        warningBtn.hq.addEvent({
            self.tip?.show(tips: "This is warning message!!!", level: .warning, top: 104)
        }, .touchUpInside)
        
        dangerBtn = initBtn(title: "Danger")
        dangerBtn.hq.addEvent({
            self.tip?.show(tips: "This is danger message!!!", level: .danger, top: 144)
        }, .touchUpInside)
        
        successBtn = initBtn(title: "Success")
        successBtn.hq.addEvent({
            self.tip?.show(tips: "This is success message!!!", level: .success, top: 184)
        }, .touchUpInside)
        
        infoBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-104-[info]-padding-[warning]-padding-[danger]-padding-[success]", options: .alignAllCenterX, metrics: ["padding": 24], views: ["info": infoBtn, "warning": warningBtn, "danger": dangerBtn, "success": successBtn]))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tip?.dismiss()
    }
    
}
