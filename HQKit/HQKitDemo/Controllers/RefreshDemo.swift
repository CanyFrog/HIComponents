//
//  RefreshDemo.swift
//  HQKitDemo
//
//  Created by HonQi on 2018/5/19.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import UIKit
import HQKit

class RefreshDemo: BaseDemo, UITableViewDataSource {
    var tableView: UITableView?
    var headerRefresh: HeaderRefreshView?
    var footerRefresh: FooterRefreshView?
    
    var dataRows: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView?.dataSource = self
        tableView?.tableFooterView = UIView()
        
        headerRefresh = HeaderRefreshView(container: tableView!, limit: 80)
        headerRefresh?.beginRefreshClosure = { [weak self] in
            Timer.hq.after(2, {
                self?.dataRows = 5
                self?.tableView?.reloadData()
                self?.headerRefresh?.endRefresh()
            })
        }
        
        footerRefresh = FooterRefreshView(container: tableView!)
        footerRefresh?.beginRefreshClosure = { [weak self] in
            Timer.hq.after(2, {
                self?.dataRows += 5
                self?.tableView?.reloadData()
                self?.footerRefresh?.endRefresh()
            })
        }
        
        view.addSubview(tableView!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        headerRefresh?.beginRefresh()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil { cell = UITableViewCell(style: .default, reuseIdentifier: "Cell") }
        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.text = "This is the \(indexPath.row) row!!!"
        return cell!
    }
}
