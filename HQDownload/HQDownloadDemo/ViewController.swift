//
//  ViewController.swift
//  HQDownloadDemo
//
//  Created by Qi on 2018/4/20.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit

enum Options: String {
    case single = "单个文件下载"
    case multiple = "多个文件下载"
    case big = "大文件分段下载"
    case `continue` = "断点续传"
    case background = "后台下载"
}

class ViewController: UIViewController {
    var tableView: UITableView!
    
    let options: [Options] = [.single, .multiple, .big, .continue, .background]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OptionCell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        title = "HQDownloadDemo"
    }
}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell")
        if cell == nil { cell = UITableViewCell(style: .default, reuseIdentifier: "OptionCell") }
        cell?.textLabel?.text = options[indexPath.row].rawValue
        cell?.accessoryType = .disclosureIndicator
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            navigationController?.pushViewController(SingleViewController(), animated: true)
//        case 1:
//            navigationController?.pushViewController(MultipleViewController(), animated: true)
//        case 3:
//            navigationController?.pushViewController(ContinueViewController(), animated: true)
//        case 4:
//            navigationController?.pushViewController(BackgroundViewController(), animated: true)
        default:
            break
        }
        
    }
}
