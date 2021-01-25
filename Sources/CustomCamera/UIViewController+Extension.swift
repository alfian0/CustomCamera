//
//  File.swift
//  
//
//  Created by Macintosh on 25/01/21.
//

import UIKit

extension UIViewController {
    public var isModal: Bool {
        let presentingModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabbar = tabBarController?.presentingViewController is UITabBarController
        return presentingModal || presentingIsNavigation || presentingIsTabbar
    }
}
