import UIKit

final class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupViewControllers()
    }
    
    private func setupAppearance() {
        tabBar.tintColor = AppColor.primary
    }
    
    private func setupViewControllers() {
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        let searchVC = SearchViewController()
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "sparkle.magnifyingglass")
        )
        
        let statsVC = StatsViewController()
        statsVC.tabBarItem = UITabBarItem(
            title: "Stats",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )
        
        viewControllers = [homeNav, searchNav, statsVC]
    }
}
