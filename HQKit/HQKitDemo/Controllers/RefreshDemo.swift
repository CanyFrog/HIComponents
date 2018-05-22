//
//  RefreshDemo.swift
//  HQKitDemo
//
//  Created by Magee on 2018/5/19.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit
import HQKit

class RefreshDemo: BaseDemo, UITableViewDataSource {
    var tableView: UITableView?
//    var headerRefresh: HeaderRefreshView?
    var footerRefresh: FooterRefreshView?
    
    var dataRows: Int = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView?.dataSource = self
        tableView?.tableFooterView = UIView()
        
//        headerRefresh = HeaderRefreshView(container: tableView!)
        footerRefresh = FooterRefreshView(container: tableView!)
        footerRefresh?.backgroundColor = UIColor.red
        footerRefresh?.beginRefreshClosure = { [weak self] in
            sleep(5)
            self?.dataRows += 5
            self?.tableView?.reloadData()
            self?.footerRefresh?.endRefresh()
        }
        
        view.addSubview(tableView!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        headerRefresh?.beginRefresh()
//        Timer.hq.after(1) {
//            self.headerRefresh?.endRefresh()
//            self.dataRows = 10
//            self.tableView?.reloadData()
//        }
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
