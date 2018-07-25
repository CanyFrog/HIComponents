//
//  ViewController.swift
//  HQKitDemo
//
//  Created by HonQi on 2018/5/19.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import UIKit
import Foundation

struct DemoConfig {
    var title: String
    var controller: BaseDemo.Type
}

class ViewController: UITableViewController {
    let demos: [DemoConfig] = [
        DemoConfig(title: "TipViewDemo", controller: TipViewDemo.self),
        DemoConfig(title: "RotaryCircleDemo", controller: RotaryCircleDemo.self),
        DemoConfig(title: "RefreshDemo", controller: RefreshDemo.self),
        DemoConfig(title: "WebViewDemo", controller: WebViewDemo.self)
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Demo"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
}

extension ViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return demos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil { cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")}
        cell?.accessoryType = .disclosureIndicator
        cell!.textLabel?.text = demos[indexPath.row].title
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = demos[indexPath.row]
        let vc = data.controller.init()
        vc.customTitle = data.title
        navigationController?.pushViewController(vc, animated: true)
    }
}

class BaseDemo: UIViewController {
    var customTitle: String!
    
    convenience init(title: String) {
        self.init(nibName: nil, bundle: nil)
        customTitle = title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = customTitle
    }
    
    func initBtn(title: String, width: CGFloat = UIScreen.main.bounds.width / 3) -> UIButton {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.backgroundColor = UIColor.black
        view.addSubview(btn)
        btn.widthAnchor.constraint(equalToConstant: width).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }
}
