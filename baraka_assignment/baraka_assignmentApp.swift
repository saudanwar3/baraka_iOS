//
//  baraka_assignmentApp.swift
//  baraka_assignment
//
//  Created by Muhammad Saud Anwar on 01/10/2025.
//

import SwiftUI

@main
struct baraka_assignmentApp: App {

    var body: some Scene {
        WindowGroup {
            RootUIKitView()
        }
    }
}
struct RootUIKitView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let rootViewController = PortfolioViewController()
        return UINavigationController(rootViewController: rootViewController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
