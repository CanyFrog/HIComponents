//
//  PresentationDemo.swift
//  HQKitDemo
//
//  Created by Magee Huang on 9/14/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit

class PresentationDemo: BaseDemo {
    var isPresented: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = isPresented ? UIColor.cyan : UIColor.white
        
        let BaiduBtn = initBtn(title: isPresented ? "Dismiss" : "Presentation" )
        BaiduBtn.hq.addEvent({ 
            if self.isPresented {
                self.dismiss(animated: true, completion: nil)
            }
            else {
                let vc = PresentationDemo()
                vc.isPresented = true
                self.hq.modal(viewController: vc, preferredHeight: 600, animated: true)
            }
        }, .touchUpInside)
        
        BaiduBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        BaiduBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        if isPresented {
            print("delegate is dealloc? \(transitioningDelegate == nil)")
        }
    }
    
    deinit {
        print("deinit view controller")
    }
}
