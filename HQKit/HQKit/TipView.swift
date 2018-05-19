//
//  TipView.swift
//  HQKit
//
//  Created by Magee on 2018/5/19.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit
import HQFoundation

public class TipView: UIView {
    /// Tip level
    public enum Level { case info, warning, danger, success }
    
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.clear
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.clear
        layer.cornerRadius = 5
        clipsToBounds = true
        
        UIApplication.shared.keyWindow?.addSubview(self)
        addSubview(label)
        initConstrant()
    }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initConstrant() {
        let padding: CGFloat = 10
        guard let window = UIApplication.shared.keyWindow else { return }
        var safeBottom: CGFloat = -50
        if #available(iOS 11.0, *) { safeBottom -= window.safeAreaInsets.bottom }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 12),
            trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -12),
            bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: safeBottom),
            
            label.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding)
            ])
    }
    
    private func match(level: Level) {
        switch level {
        case .info:
            backgroundColor = UIColor.hq.info
        case .warning:
            backgroundColor = UIColor.hq.warning
        case .danger:
            backgroundColor = UIColor.hq.danger
        case .success:
            backgroundColor = UIColor.hq.success
        }
        label.textColor = UIColor.white
    }
}

extension TipView {
    public func show(tips: String, level: Level = .info) {
        label.text = tips
        UIView.animate(withDuration: 0.5) {
            self.match(level: level)
            self.layoutIfNeeded()
        }
    }
    
    public func dismiss() {
        UIView.animate(withDuration: 0.5, animations: {
            self.backgroundColor = UIColor.clear
            self.label.textColor = UIColor.clear
        }) { (_) in
            self.removeFromSuperview()
        }
    }
}
