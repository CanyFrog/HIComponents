//
//  ActionViewController.swift
//  DemoApp
//
//  Created by HonQi on 9/12/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit

public class ActionSheetController: UIViewController {
    public var preferredHeight: CGFloat = 0.0
    
    public static func present(height: CGFloat, by presenting: UIViewController, completion: (()->Void)? = nil) {
        let actionVC = ActionSheetController()
        actionVC.preferredHeight = height
        actionVC.modalPresentationStyle = .custom

        let presentation = ActionSheetPresentation(presentedViewController: actionVC, presenting: presenting)
        actionVC.transitioningDelegate = presentation
        presenting.present(actionVC, animated: true, completion: completion)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: view.bounds.width, height: preferredHeight)
        view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
    }
    
    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        preferredContentSize = CGSize(width: view.bounds.width, height: preferredHeight)
    }
}
