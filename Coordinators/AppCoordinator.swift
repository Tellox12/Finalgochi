import UIKit

final class AppCoordinator: Coordinator {
    private let uiWindow: UIWindow
    private let navigationController = UINavigationController()
    private let gameManager = GameManager()

    init(uiWindow: UIWindow) { self.uiWindow = uiWindow }

    func start() {
        navigationController.setNavigationBarHidden(true, animated: true)
        uiWindow.rootViewController = navigationController
        uiWindow.makeKeyAndVisible()
        showSplash()
    }

    private func showSplash() {
        let screen = SplashViewController()
        screen.onFinishSplash = { [weak self] in
            guard let self else { return }
            self.gameManager.pet == nil ? self.showCharacterSelect() : self.showHome()
        }
        setRoot(screen)
    }

    private func showCharacterSelect() {
        let screen = CharacterSelectViewController()
        screen.onCharacterSelected = { [weak self] kind in
            self?.gameManager.createPet(kind)
            self?.showHome()
        }
        setRoot(screen)
    }

    private func showHome() {
        guard gameManager.pet != nil else { showCharacterSelect(); return }
        let screen = HomeViewController(gameManager: gameManager)
        screen.onOpenActions = { [weak self] in self?.showActionMenu() }
        screen.onOpenInventory = { [weak self] in self?.showInventory() }
        screen.onOpenCharacterSheet = { [weak self] in self?.showCharacterSheet() }
        screen.onOpenShop = { [weak self] in self?.showShop() }
        screen.onOpenSettings = { [weak self] in self?.showSettings() }
        screen.onGameOver = { [weak self] in self?.showGameOver() }
        setRoot(screen)
    }

    private func showActionMenu() {
        let screen = ActionMenuViewController(gameManager: gameManager)
        screen.onFeed = { [weak self] in self?.showInventory() }
        screen.onPlay = { [weak self] in self?.showMinigame() }
        screen.onSleep = { [weak self] in
            guard let self else { return }
            if self.gameManager.pet?.isSleeping == true {
                self.gameManager.wake()
            } else {
                self.gameManager.sleep()
            }
            self.showHome()
        }
        screen.onShowStatus = { [weak self] in self?.showCharacterSheet() }
        screen.onClose = { [weak self] in self?.showHome() }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showInventory() {
        let screen = InventoryViewController(gameManager: gameManager)
        screen.onClose = { [weak self] in self?.showHome() }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showMinigame() {
        let screen = MinigameViewController()
        screen.onFinish = { [weak self] success in
            guard let self else { return }
            self.gameManager.playMiniGame(success: success)
            self.showHome()
        }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showCharacterSheet() {
        let screen = CharacterSheetViewController(gameManager: gameManager)
        screen.onClose = { [weak self] in self?.showHome() }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showShop() {
        let screen = ShopViewController(gameManager: gameManager)
        screen.onClose = { [weak self] in self?.showHome() }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showSettings() {
        let screen = SettingsViewController()
        screen.onClose = { [weak self] in self?.showHome() }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showGameOver() {
        let screen = GameOverViewController()
        screen.onRestart = { [weak self] in
            guard let self else { return }
            self.gameManager.reset()
            self.showCharacterSelect()
        }
        setRoot(screen)
    }

    private func setRoot(_ screen: UIViewController) {
        navigationController.setViewControllers([screen], animated: false)
    }
}
