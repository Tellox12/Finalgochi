import UIKit
import UniformTypeIdentifiers

final class AppCoordinator: NSObject, Coordinator, UIDocumentPickerDelegate {
    private enum MainTab: Int {
        case habitat
        case actions
        case shop
        case profile
    }

    private let uiWindow: UIWindow
    private let rootNavigationController = RotatingNavigationController()
    private let tabBarController = RotatingTabBarController()
    private let homeNavigationController = RotatingNavigationController()
    private let actionsNavigationController = RotatingNavigationController()
    private let shopNavigationController = RotatingNavigationController()
    private let profileNavigationController = RotatingNavigationController()
    private let gameManager = GameManager()

    private var isShowingGameOver = false

    init(uiWindow: UIWindow) {
        self.uiWindow = uiWindow
        super.init()
        gameManager.onGameOver = { [weak self] in self?.showGameOver() }
    }

    func start() {
        uiWindow.overrideUserInterfaceStyle = .dark
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        uiWindow.rootViewController = rootNavigationController
        uiWindow.makeKeyAndVisible()
        showSplash()
    }

    func sceneDidBecomeActive() {
        FeedbackManager.shared.resume()
        gameManager.updateElapsedTime()
        _ = gameManager.claimDailyLogin()
        LocalNotificationManager.clearCareReminder()
        let hasPendingReturn = gameManager.activeExpedition.map { !$0.isReady() } ?? false
        if !hasPendingReturn {
            LocalNotificationManager.clearExpeditionReturn()
        }
        if gameManager.pet?.isGameOver == true {
            showGameOver()
        }
    }

    func sceneDidEnterBackground() {
        gameManager.updateElapsedTime()
        gameManager.saveNow()
        if let pet = gameManager.pet, !pet.isGameOver {
            LocalNotificationManager.scheduleCareReminder(after: 3 * 60 * 60, petName: pet.name)
        } else {
            LocalNotificationManager.clearCareReminder()
        }
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
        isShowingGameOver = false
        let screen = CharacterSelectViewController()
        screen.onCharacterSelected = { [weak self] kind in
            self?.gameManager.createPet(kind)
            self?.showMainTabs()
        }
        setRoot(screen)
    }

    private func showMainTabs() {
        guard gameManager.pet != nil else { showCharacterSelect(); return }
        isShowingGameOver = false
        configureTabBarAppearance()

        let home = HomeViewController(gameManager: gameManager)
        home.onOpenSettings = { [weak self] in self?.showSettings() }
        home.onOpenExpeditions = { [weak self] in self?.showExpeditions() }
        home.onQuickFeed = { [weak self] in
            guard let self else { return }
            if self.gameManager.inventory[.ration, default: 0] > 0 {
                _ = self.gameManager.use(.ration)
            } else {
                self.showInventory()
            }
        }
        home.onQuickPlay = { [weak self] in self?.showMinigame() }
        home.onQuickSleep = { [weak self] in self?.toggleSleep() }

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
        configure(shopNavigationController, root: shop, title: "Bazar", symbol: "bag.fill", tag: MainTab.shop.rawValue)
        configure(profileNavigationController, root: profile, title: "Ficha", symbol: "person.crop.circle.fill", tag: MainTab.profile.rawValue)

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
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ScreenKit.panel
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.06)
        for itemAppearance in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            itemAppearance.normal.iconColor = ScreenKit.faintText
            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: ScreenKit.faintText,
                .font: ScreenKit.roundedFont(size: 10, weight: .medium, textStyle: .caption2)
            ]
            itemAppearance.selected.iconColor = ScreenKit.accent
            itemAppearance.selected.titleTextAttributes = [
                .foregroundColor: ScreenKit.accent,
                .font: ScreenKit.roundedFont(size: 10, weight: .semibold, textStyle: .caption2)
            ]
        }
        tabBarController.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }
        tabBarController.tabBar.tintColor = ScreenKit.accent
        tabBarController.tabBar.unselectedItemTintColor = ScreenKit.faintText
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
        gameManager.updateElapsedTime()
        guard gameManager.canPlayMiniGame else { return }
        let navigationController = selectedMainNavigationController
        let screen = MinigameViewController()
        screen.onResult = { [weak self] success in
            guard let self else { return }
            let didApply = self.gameManager.playMiniGame(success: success)
            if didApply {
                (self.homeNavigationController.viewControllers.first as? HomeViewController)?.showMiniGameResult(success: success)
            }
        }
        screen.onClose = { [weak self, weak navigationController] in
            navigationController?.popToRootViewController(animated: true)
            self?.selectTab(.habitat)
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
        screen.petName = gameManager.pet?.name ?? "Tu compañero"
        screen.onClose = { [weak self] in
            self?.homeNavigationController.popViewController(animated: true)
        }
        screen.onExportSave = { [weak self] in self?.exportSave() }
        screen.onImportSave = { [weak self] in self?.importSave() }
        homeNavigationController.pushViewController(screen, animated: true)
    }

    private func exportSave() {
        guard let data = gameManager.exportSave() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Finalgochi-respaldo.json")
        do {
            try data.write(to: url, options: .atomic)
            let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            share.popoverPresentationController?.sourceView = uiWindow.rootViewController?.view
            share.popoverPresentationController?.sourceRect = CGRect(x: uiWindow.bounds.midX, y: uiWindow.bounds.midY, width: 1, height: 1)
            uiWindow.rootViewController?.present(share, animated: true)
        } catch {
            presentSaveMessage("No se pudo crear el archivo de respaldo.")
        }
    }

    private func importSave() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = self
        uiWindow.rootViewController?.present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = values.fileSize,
              fileSize <= GameManager.maximumSaveFileSize,
              let data = try? Data(contentsOf: url) else {
            controller.dismiss(animated: true) { [weak self] in
                self?.presentSaveMessage("El respaldo no es válido o está dañado.")
            }
            return
        }

        controller.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Restaurar respaldo",
                message: "Se sobrescribirá la partida actual con el contenido del archivo. Esta acción no se puede deshacer.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            alert.addAction(UIAlertAction(title: "Restaurar", style: .destructive) { _ in
                // Wait for the confirmation alert to finish dismissing before the root view changes.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.performImport(data)
                }
            })
            self.uiWindow.rootViewController?.present(alert, animated: true)
        }
    }

    private func performImport(_ data: Data) {
        guard gameManager.importSave(data) else {
            presentSaveMessage("El respaldo no es válido o pertenece a una versión más reciente.")
            return
        }
        LocalNotificationManager.clearExpeditionReturn()
        LocalNotificationManager.clearCareReminder()
        if let expedition = gameManager.activeExpedition,
           let pet = gameManager.pet,
           !expedition.isReady() {
            LocalNotificationManager.scheduleExpeditionReturn(
                after: expedition.remainingTime(),
                petName: pet.name,
                routeName: expedition.route.title
            )
        }
        if gameManager.pet?.isGameOver == true {
            showGameOver()
        } else {
            showMainTabs()
        }
        presentSaveMessage("Partida restaurada correctamente.")
    }

    private func presentSaveMessage(_ message: String, attempt: Int = 0) {
        guard let root = uiWindow.rootViewController else { return }
        // Import failures are reported from inside an alert action; wait until that alert is gone.
        if root.presentedViewController != nil, attempt < 8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.presentSaveMessage(message, attempt: attempt + 1)
            }
            return
        }
        let alert = UIAlertController(title: "Respaldo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
        root.present(alert, animated: true)
    }

    private func showGameOver() {
        guard !isShowingGameOver else { return }
        isShowingGameOver = true
        LocalNotificationManager.clearAll()
        let screen = GameOverViewController()
        screen.petName = gameManager.pet?.name
        screen.onRestart = { [weak self] in
            guard let self else { return }
            LocalNotificationManager.clearAll()
            self.gameManager.reset()
            self.isShowingGameOver = false
            self.showCharacterSelect()
        }
        setRoot(screen)
        uiWindow.rootViewController = rootNavigationController
    }

    private func setRoot(_ screen: UIViewController) {
        rootNavigationController.setViewControllers([screen], animated: false)
    }
}

// MARK: - Rotation

/// Containers normally forward `supportedInterfaceOrientations` to their children, and a plain
/// `UIViewController` excludes portrait upside down on iPhone. These subclasses keep every screen
/// rotatable in all four orientations on both iPhone and iPad.
private final class RotatingNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var shouldAutorotate: Bool { true }
}

private final class RotatingTabBarController: UITabBarController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var shouldAutorotate: Bool { true }
}
