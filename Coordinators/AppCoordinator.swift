import UIKit

final class AppCoordinator: Coordinator {
    private enum MainTab: Int {
        case habitat
        case actions
        case shop
        case profile
    }

    private let uiWindow: UIWindow
    private let rootNavigationController = UINavigationController()
    private let tabBarController = UITabBarController()
    private let homeNavigationController = UINavigationController()
    private let actionsNavigationController = UINavigationController()
    private let shopNavigationController = UINavigationController()
    private let profileNavigationController = UINavigationController()
    private let gameManager = GameManager()

    init(uiWindow: UIWindow) { self.uiWindow = uiWindow }

    func start() {
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        uiWindow.rootViewController = rootNavigationController
        uiWindow.makeKeyAndVisible()
        showSplash()
    }

    private func showSplash() {
        let screen = SplashViewController()
        screen.onFinishSplash = { [weak self] in
            guard let self else { return }
            self.gameManager.pet == nil ? self.showCharacterSelect() : self.showMainTabs()
        }
        setRoot(screen)
    }

    private func showCharacterSelect() {
        let screen = CharacterSelectViewController()
        screen.onCharacterSelected = { [weak self] kind in
            self?.gameManager.createPet(kind)
            self?.showMainTabs()
        }
        setRoot(screen)
    }

    private func showMainTabs() {
        guard gameManager.pet != nil else { showCharacterSelect(); return }

        configureTabBarAppearance()

        let home = HomeViewController(gameManager: gameManager)
        home.onOpenSettings = { [weak self] in self?.showSettings() }
        home.onOpenExpeditions = { [weak self] in self?.showExpeditions() }
        home.onQuickFeed = { [weak self] in
            guard let self else { return }
            if self.gameManager.inventory[.ration, default: 0] > 0 {
                self.gameManager.feed()
            } else {
                self.showInventory()
            }
        }
        home.onQuickPlay = { [weak self] in self?.showMinigame() }
        home.onQuickSleep = { [weak self] in self?.toggleSleep() }
        home.onGameOver = { [weak self] in self?.showGameOver() }

        let actions = ActionMenuViewController(gameManager: gameManager)
        actions.onFeed = { [weak self] in self?.showInventory() }
        actions.onPlay = { [weak self] in self?.showMinigame() }
        actions.onOpenMateria = { [weak self] in self?.showMateria() }
        actions.onOpenExpeditions = { [weak self] in self?.showExpeditions() }
        actions.onSleep = { [weak self] in
            self?.toggleSleep()
            self?.selectTab(.habitat)
        }
        actions.onShowStatus = { [weak self] in self?.selectTab(.profile) }
        actions.onClose = { [weak self] in self?.selectTab(.habitat) }

        let shop = ShopViewController(gameManager: gameManager)
        shop.onClose = { [weak self] in self?.selectTab(.habitat) }
        shop.onOpenMateria = { [weak self] in
            guard let self else { return }
            self.showMateria(returnToShop: true, in: self.shopNavigationController)
        }

        let profile = CharacterSheetViewController(gameManager: gameManager)
        profile.onClose = { [weak self] in self?.selectTab(.habitat) }

        configure(homeNavigationController, root: home, title: "Hábitat", symbol: "house.fill", tag: MainTab.habitat.rawValue)
        configure(actionsNavigationController, root: actions, title: "Acciones", symbol: "sparkles", tag: MainTab.actions.rawValue)
        configure(shopNavigationController, root: shop, title: "Tienda", symbol: "bag.fill", tag: MainTab.shop.rawValue)
        configure(profileNavigationController, root: profile, title: "Ficha", symbol: "person.fill", tag: MainTab.profile.rawValue)

        tabBarController.setViewControllers([
            homeNavigationController,
            actionsNavigationController,
            shopNavigationController,
            profileNavigationController
        ], animated: false)
        tabBarController.selectedIndex = MainTab.habitat.rawValue
        uiWindow.rootViewController = tabBarController
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = ScreenKit.panel
        for itemAppearance in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            itemAppearance.normal.iconColor = ScreenKit.mutedText
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: ScreenKit.mutedText]
            itemAppearance.selected.iconColor = ScreenKit.accent
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: ScreenKit.accent]
        }
        tabBarController.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }
        tabBarController.tabBar.tintColor = ScreenKit.accent
        tabBarController.tabBar.unselectedItemTintColor = ScreenKit.mutedText
    }

    private func configure(_ navigationController: UINavigationController, root: UIViewController, title: String, symbol: String, tag: Int) {
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.setViewControllers([root], animated: false)
        navigationController.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), tag: tag)
    }

    private func selectTab(_ tab: MainTab) {
        tabBarController.selectedIndex = tab.rawValue
    }

    private var selectedMainNavigationController: UINavigationController {
        switch tabBarController.selectedIndex {
        case MainTab.actions.rawValue: return actionsNavigationController
        case MainTab.shop.rawValue: return shopNavigationController
        case MainTab.profile.rawValue: return profileNavigationController
        default: return homeNavigationController
        }
    }

    private func toggleSleep() {
        if gameManager.pet?.isSleeping == true {
            gameManager.wake()
        } else {
            gameManager.sleep()
        }
    }

    private func showHome() {
        homeNavigationController.popToRootViewController(animated: false)
        actionsNavigationController.popToRootViewController(animated: false)
        shopNavigationController.popToRootViewController(animated: false)
        profileNavigationController.popToRootViewController(animated: false)
        selectTab(.habitat)
    }

    private func showInventory() {
        selectTab(.actions)
        let screen = InventoryViewController(gameManager: gameManager)
        screen.onClose = { [weak self] in
            guard let self else { return }
            self.actionsNavigationController.popViewController(animated: true)
            self.selectTab(.habitat)
        }
        actionsNavigationController.pushViewController(screen, animated: true)
    }

    private func showMinigame() {
        let navigationController = selectedMainNavigationController
        let screen = MinigameViewController()
        screen.onFinish = { [weak self, weak navigationController] success in
            guard let self else { return }
            self.gameManager.playMiniGame(success: success)
            navigationController?.popToRootViewController(animated: true)
            self.selectTab(.habitat)
        }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showExpeditions() {
        let navigationController = selectedMainNavigationController
        let screen = ExpeditionsViewController(gameManager: gameManager)
        screen.onClose = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showMateria(returnToShop: Bool = false) {
        showMateria(returnToShop: returnToShop, in: actionsNavigationController)
    }

    private func showMateria(returnToShop: Bool, in navigationController: UINavigationController) {
        let screen = MateriaViewController(gameManager: gameManager)
        screen.onClose = { [weak self, weak navigationController] in
            if returnToShop {
                navigationController?.popViewController(animated: true)
            } else {
                self?.showHome()
            }
        }
        screen.onOpenShop = { [weak self, weak navigationController] in
            guard let self, let navigationController else { return }
            if returnToShop {
                navigationController.popViewController(animated: true)
            } else {
                self.showShop(returnToMateria: true, in: navigationController)
            }
        }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showShop(returnToMateria: Bool, in navigationController: UINavigationController) {
        let screen = ShopViewController(gameManager: gameManager)
        screen.onClose = { [weak self, weak navigationController] in
            if returnToMateria {
                navigationController?.popViewController(animated: true)
            } else {
                self?.showHome()
            }
        }
        screen.onOpenMateria = { [weak self, weak navigationController] in
            guard let self, let navigationController else { return }
            self.showMateria(returnToShop: true, in: navigationController)
        }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showSettings() {
        let screen = SettingsViewController()
        screen.onClose = { [weak self] in
            self?.homeNavigationController.popViewController(animated: true)
        }
        homeNavigationController.pushViewController(screen, animated: true)
    }

    private func showGameOver() {
        let screen = GameOverViewController()
        screen.onRestart = { [weak self] in
            guard let self else { return }
            LocalNotificationManager.clearExpeditionReturn()
            self.gameManager.reset()
            self.showCharacterSelect()
        }
        rootNavigationController.setViewControllers([screen], animated: false)
        uiWindow.rootViewController = rootNavigationController
    }

    private func setRoot(_ screen: UIViewController) {
        rootNavigationController.setViewControllers([screen], animated: false)
    }
}
