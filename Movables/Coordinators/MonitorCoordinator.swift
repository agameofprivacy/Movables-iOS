//
//  MonitorCoordinator.swift
//  Movables
//
//  MIT License
//
//  Copyright (c) 2018 Eddie Chen
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import UIKit
class MonitorCoordinator: Coordinator {
    
    let rootViewController: UINavigationController
    var monitorVC: MonitorViewController
    var packageDetailVC: PackageDetailViewController?
    
    override init() {
        monitorVC = MonitorViewController()
        self.rootViewController = UINavigationController(rootViewController: monitorVC)
        self.rootViewController.tabBarItem = UITabBarItem(title: String(NSLocalizedString("tabBar.activities", comment: "Activities tab name")), image: UIImage(named: "tab_track"), tag: 2)
    }
    
}

extension MonitorCoordinator: MonitorViewControllerDelegate {
    func showPackageDetail(with packageId: String, and headline: String) {
        packageDetailVC = PackageDetailViewController()
        packageDetailVC?.headline = headline
        packageDetailVC?.tagName = ""
        packageDetailVC?.packageDocumentId = packageId
        packageDetailVC?.delegate = self
        let packageDetailNC = UINavigationController(rootViewController: packageDetailVC!)
        self.rootViewController.present(packageDetailNC, animated: true) {
            print("presented package detail")
        }
    }
}

extension MonitorCoordinator: PackageDetailViewControllerDelegate {
    func dismissPackageDetailVC() {
        packageDetailVC?.view.endEditing(true)
        packageDetailVC?.dismiss(animated: true, completion: {
            print("package detail dismissed")
        })
    }
    
    func showPostsVC() {
        let postsVC = PostsViewController(collectionViewLayout: UICollectionViewFlowLayout())
        postsVC!.reference = packageDetailVC?.package?.reference
        postsVC!.referenceType = .package
        packageDetailVC?.navigationController?.show(postsVC!, sender: packageDetailVC)
    }
    
    func presentDropoffSummary(with package: Package, response: [String : Any]) {
        let dropoffSummaryVC = DropoffSummaryViewController()
        dropoffSummaryVC.package = package
        dropoffSummaryVC.response = response
        
        packageDetailVC?.navigationController?.pushViewController(dropoffSummaryVC, animated: true)
    }
    
    func showMapRouteVC(for package: Package) {
        let mapRouteVC = MapRouteViewController()
        mapRouteVC.package = package
        packageDetailVC?.navigationController?.show(mapRouteVC, sender: packageDetailVC)
    }

}
