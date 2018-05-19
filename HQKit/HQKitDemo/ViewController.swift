//
//  ViewController.swift
//  HQKitDemo
//
//  Created by Magee on 2018/5/19.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit

struct DemoConfig {
    var title: String
    var controller: UIViewController
}

class ViewController: UITableViewController {
    let demos: [DemoConfig] = [
        DemoConfig(title: "TipViewDemo", controller: TipViewDemo(title: "TipViewDemo")),
        DemoConfig(title: "RotaryCircleDemo", controller: RotaryCircleDemo(title: "RotaryCircleDemo")),
        DemoConfig(title: "RefreshDemo", controller: RefreshDemo(title: "RefreshDemo"))
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
        navigationController?.pushViewController(demos[indexPath.row].controller, animated: true)
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
        title = customTitle
    }
    
    func initBtn(title: String) -> UIButton {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.backgroundColor = UIColor.black
        view.addSubview(btn)
        btn.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width / 3).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }
}
