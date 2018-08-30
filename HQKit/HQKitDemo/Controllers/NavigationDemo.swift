//
//  NavigationDemo.swift
//  HQKitDemo
//
//  Created by Magee Huang on 8/29/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQKit

class NavigationDemo: BaseDemo {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let infoBtn = initBtn(title: "Navigation")
        infoBtn.hq.addEvent({
            self.navigationController?.pushViewController(NavigationVC(), animated: true)
        }, .touchUpInside)
        
        infoBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        infoBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


class NavigationVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.cyan
        navigationController?.navigationBar.hq.set(backAlpha: 0.4)
        navigationController?.navigationBar.hq.hiddenLine()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Aack", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Forword", style: .plain, target: nil, action: nil)
    }
}
