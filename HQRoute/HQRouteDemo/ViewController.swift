//
//  ViewController.swift
//  HQRouteDemo
//
//  Created by Magee Huang on 8/30/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit
import HQRoute

class ViewController: UIViewController {
    var pushBtn: UIButton!
    var popBtn: UIButton!
    var presentBtn: UIButton!
    var dismissBtn: UIButton!
    var homeBtn: UIButton!
    
    weak var router: Router?
    var bgColor: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.red
        navigationItem.title = title
        
        pushBtn = initBtn(title: "Push")
        pushBtn.addTarget(self, action: #selector(pushEvent), for: .touchUpInside)
        
        popBtn = initBtn(title: "Pop")
        popBtn.addTarget(self, action: #selector(popEvent), for: .touchUpInside)
        
        presentBtn = initBtn(title: "Present")
        presentBtn.addTarget(self, action: #selector(presentEvent), for: .touchUpInside)
        
        dismissBtn = initBtn(title: "Dismiss")
        dismissBtn.addTarget(self, action: #selector(dismissEvent), for: .touchUpInside)
        
        homeBtn = initBtn(title: "Home")
        homeBtn.addTarget(self, action: #selector(homeEvent), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            pushBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            pushBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 104),
            
            popBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            popBtn.topAnchor.constraint(equalTo: pushBtn.topAnchor),
            
            presentBtn.leadingAnchor.constraint(equalTo: pushBtn.leadingAnchor),
            presentBtn.topAnchor.constraint(equalTo: pushBtn.bottomAnchor, constant: 24),
            
            dismissBtn.trailingAnchor.constraint(equalTo: popBtn.trailingAnchor),
            dismissBtn.topAnchor.constraint(equalTo: popBtn.bottomAnchor, constant: 24),
            
            homeBtn.topAnchor.constraint(equalTo: presentBtn.bottomAnchor, constant: 24),
            homeBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
    }
    
    func initBtn(title: String) -> UIButton {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.textAlignment = .center
        btn.backgroundColor = UIColor.darkGray
        view.addSubview(btn)
        btn.widthAnchor.constraint(equalToConstant: (view.bounds.width - 24 * 3) / 2).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }
    
    @objc func pushEvent() {
        router?.forward(component: "demo-component?title=\((navigationController?.viewControllers.count ?? 1)+1)")
    }
    
    @objc func popEvent() {
        router?.back()
    }
    
    @objc func presentEvent() {
        router?.forward(component: "demo-component?title=\((navigationController?.viewControllers.count ?? 1)+1)", mode: .present, animated: true)
    }
    
    @objc func dismissEvent() {
        router?.back()
    }
    
    @objc func homeEvent() {
        router?.home()
    }
}

