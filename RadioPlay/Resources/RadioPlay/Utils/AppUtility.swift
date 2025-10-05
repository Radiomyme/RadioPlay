//
//  AppUtility.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Utils/AppUtility.swift (renommez le fichier)
import Foundation
import UIKit

struct AppUtility {
    static var window: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return nil
        }
        return window
    }
    
    static var rootViewController: UIViewController? {
        return window?.rootViewController
    }
}