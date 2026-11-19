import UIKit

final class PixelPetSpriteView: UIView {
    var kind: PetKind = .moogle {
        didSet {
            accessibilityLabel = "Ilustración de \(kind.displayName)"
            setNeedsDisplay()
        }
    }
    var mood: PetMood = .calm {
        didSet {
            accessibilityValue = mood.title
            setNeedsDisplay()
        }
    }
    var evolutionStage: EvolutionStage = .hatchling {
        didSet {
            updateAccessibilityHint()
            setNeedsDisplay()
        }
    }
    var showsMoodBadge = true { didSet { setNeedsDisplay() } }
    var equippedItems: [StoreItem] = [] {
        didSet {
            updateAccessibilityHint()
            setNeedsDisplay()
        }
    }

    private let colors: [Character: UIColor] = [
        "D": UIColor(red: 0.16, green: 0.17, blue: 0.30, alpha: 1),
        "K": UIColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1),
        "W": UIColor(red: 0.93, green: 0.91, blue: 0.98, alpha: 1),
        "w": UIColor(red: 0.77, green: 0.81, blue: 0.92, alpha: 1),
        "Y": UIColor(red: 1.00, green: 0.78, blue: 0.28, alpha: 1),
        "y": UIColor(red: 0.91, green: 0.55, blue: 0.17, alpha: 1),
        "O": UIColor(red: 0.97, green: 0.49, blue: 0.24, alpha: 1),
        "R": UIColor(red: 0.88, green: 0.20, blue: 0.37, alpha: 1),
        "P": UIColor(red: 0.99, green: 0.46, blue: 0.65, alpha: 1),
        "G": UIColor(red: 0.30, green: 0.72, blue: 0.48, alpha: 1),
        "g": UIColor(red: 0.16, green: 0.48, blue: 0.36, alpha: 1),
        "L": UIColor(red: 0.56, green: 0.88, blue: 0.56, alpha: 1)
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityLabel = "Ilustración de Moogle"
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    private func updateAccessibilityHint() {
        var details = ["Etapa: \(evolutionStage.title)"]
        if !equippedItems.isEmpty {
            details.append("Equipo: " + equippedItems.map(\.name).joined(separator: ", "))
        }
        accessibilityHint = details.joined(separator: ". ")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setShouldAntialias(false)
        let rows = spriteRows
        let widestRow = CGFloat(rows.map { $0.count }.max() ?? 16)
        let pixelSize = min(bounds.width / widestRow, bounds.height / CGFloat(rows.count))
        let spriteHeight = pixelSize * CGFloat(rows.count)
        let originY = (bounds.height - spriteHeight) / 2

        context.setShouldAntialias(true)
        context.setFillColor(UIColor.black.withAlphaComponent(0.22).cgColor)
        context.fillEllipse(in: CGRect(x: bounds.midX - bounds.width * 0.25, y: bounds.height - 13, width: bounds.width * 0.5, height: 9))
        context.setShouldAntialias(false)

        for (rowIndex, row) in rows.enumerated() {
            let pixels = Array(row)
            let originX = (bounds.width - pixelSize * CGFloat(pixels.count)) / 2
            for (columnIndex, pixel) in pixels.enumerated() {
                guard let color = colors[pixel] else { continue }
                context.setFillColor(color.cgColor)
                context.fill(CGRect(
                    x: originX + CGFloat(columnIndex) * pixelSize,
                    y: originY + CGFloat(rowIndex) * pixelSize,
                    width: pixelSize,
                    height: pixelSize
                ))
            }
        }

        drawEquipment(context: context, pixelSize: pixelSize, spriteHeight: spriteHeight, originY: originY)
        drawEvolutionMark(pixelSize: pixelSize, originY: originY)

        context.setShouldAntialias(true)
        if showsMoodBadge {
            let badge = CGRect(x: bounds.width - 38, y: 5, width: 32, height: 28)
            let badgePath = UIBezierPath(roundedRect: badge, cornerRadius: 9)
            ScreenKit.panel.withAlphaComponent(0.92).setFill()
            badgePath.fill()
            if let image = UIImage(systemName: mood.symbolName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))?
                .withTintColor(ScreenKit.gold, renderingMode: .alwaysOriginal) {
                let size = image.size
                image.draw(at: CGPoint(x: badge.midX - size.width / 2, y: badge.midY - size.height / 2))
            }
        }
    }

    private func drawEvolutionMark(pixelSize: CGFloat, originY: CGFloat) {
        guard evolutionStage != .hatchling else { return }
        let count = evolutionStage == .legendary ? 5 : (evolutionStage == .veteran ? 3 : 1)
        let center = bounds.midX
        let baseY = max(2, originY - pixelSize * 2)
        let color = evolutionStage == .legendary ? ScreenKit.gold : ScreenKit.accent
        color.setFill()
        for index in 0..<count {
            let xOffset = CGFloat(index - count / 2) * pixelSize * 2
            UIBezierPath(roundedRect: CGRect(x: center + xOffset - pixelSize / 2, y: baseY, width: pixelSize, height: pixelSize * CGFloat(index.isMultiple(of: 2) ? 2 : 1)), cornerRadius: 1).fill()
        }
    }

    private func drawEquipment(context: CGContext, pixelSize: CGFloat, spriteHeight: CGFloat, originY: CGFloat) {
        let gearColors: [Character: UIColor] = [
            "D": UIColor(red: 0.16, green: 0.17, blue: 0.30, alpha: 1),
            "P": UIColor(red: 0.99, green: 0.46, blue: 0.65, alpha: 1),
            "Y": UIColor(red: 1.00, green: 0.78, blue: 0.28, alpha: 1),
            "y": UIColor(red: 0.91, green: 0.55, blue: 0.17, alpha: 1),
            "B": UIColor(red: 0.40, green: 0.49, blue: 0.87, alpha: 1),
            "V": UIColor(red: 0.48, green: 0.30, blue: 0.68, alpha: 1)
        ]
        let headY = originY + pixelSize * 1.5
        let torsoY = originY + spriteHeight * 0.61
        for item in equippedItems {
            switch item {
            case .feather:
                drawPattern(["...Y.", ".YYY.", "..YY.", "..Y.."], centerX: bounds.midX, topY: headY, pixelSize: pixelSize, colors: gearColors, context: context)
            case .cactusHat:
                drawPattern(["...YYYY...", "..YYYYYY..", "YYYYYYYYYYY", "..YY..YY.."], centerX: bounds.midX, topY: headY, pixelSize: pixelSize, colors: gearColors, context: context)
            case .kupoRobe:
                drawPattern(["..PPPPPP..", ".DPPPPPPD.", "..PPPPPP.."], centerX: bounds.midX, topY: torsoY, pixelSize: pixelSize, colors: gearColors, context: context)
            case .chocoboHarness:
                drawPattern(["D.......", ".D......", "..D.....", "...D....", "....D...", ".....D..", "......D."], centerX: bounds.midX, topY: torsoY - pixelSize * 2, pixelSize: pixelSize, colors: gearColors, context: context)
            case .mageCloak:
                drawPattern(["V........V", "VV......VV", ".VV....VV."], centerX: bounds.midX, topY: torsoY, pixelSize: pixelSize, colors: gearColors, context: context)
            case .ribbon:
                drawPattern([".P.P.", "PPPPP", ".P.P."], centerX: bounds.midX, topY: torsoY - pixelSize * 2, pixelSize: pixelSize, colors: gearColors, context: context)
            }
        }
    }

    private func drawPattern(_ rows: [String], centerX: CGFloat, topY: CGFloat, pixelSize: CGFloat, colors: [Character: UIColor], context: CGContext) {
        for (rowIndex, row) in rows.enumerated() {
            let pixels = Array(row)
            let originX = centerX - CGFloat(pixels.count) * pixelSize / 2
            for (columnIndex, pixel) in pixels.enumerated() {
                guard let color = colors[pixel] else { continue }
                context.setFillColor(color.cgColor)
                context.fill(CGRect(
                    x: originX + CGFloat(columnIndex) * pixelSize,
                    y: topY + CGFloat(rowIndex) * pixelSize,
                    width: pixelSize,
                    height: pixelSize
                ))
            }
        }
    }

    private var spriteRows: [String] {
        switch kind {
        case .moogle:
            return [
                "..........RRRR..........", ".........RRYYRR.........", "..........RRRR..........",
                "...........DD...........", "....DD.....DD.....DD....", "...DWWD....DD....DWWD...",
                "..DWWWD....DD....DWWWD..", "..DWWWDD..DDDD..DDWWWD..",
                "...DDDWWDDDDDDDDWWDDD...", "......DDDDDDDDDD.........",
                "....DDWWWWWWWWWWDD.......", "...DWWWWWWWWWWWWWWD......",
                "..DWWWWWWWWWWWWWWWWD.....", "..DWWKWWWWWWKWWWWWWD.....",
                "..DWWWWWWPPWWWWWWWWD.....", "...DWWWWWWWWWWWWWWD......",
                "....DDWWWWWWWWWWDD.......", "......DDDDDDDDDD..........",
                "......DYYD....DYYD........", ".....DDDD......DDDD.......",
                ".....DWWD......DWWD.......", "......DD........DD........"
            ]
        case .chocobo:
            return [
                "...........OO............", "..........OYYO...........", "...........YY.............",
                ".........DYYYYD...........", "........DYYYYYYD..........",
                ".......DYYYYYYYYD.........", "......DYYYYYYYYYYD........",
                "......DYYKYYYYKYYD........", ".......DYYYYYYYYD..OOO....",
                "........DYYYYYYDDOOO......", ".........DYYYYYYYYD.......",
                "........DYYYYYYYYYYD......", ".......DYYYYYYYYYYYYD.....",
                "......DYYYYYYYYYYYYYYD....", ".....DYYYYYYYYYYYYYYYYD...",
                ".....DYYYYDYYYYYYYYYYD....", "......DDDD..DYYYYYDD.......",
                "...........DYYYYD...........", "..........DYYYYYD...........",
                ".........DD....DD...........", ".........DYY..DYYD...........",
                ".........DD....DD............"
            ]
        case .cactilio:
            return [
                "..........Y..Y............", "...........GG.............", "...........LG.............",
                "......DD...GG...DD.........", ".....DGGD..GG..DGGD........",
                ".....DGGD..GG..DGGD........", "......DD...GG...DD..........",
                "...........GGGG............", "..........DGGGGD...........",
                ".........DGGGGGGD..........", "...Y....DGGGGGGGGD....Y....",
                "...Y...DGGGGGGGGGGD...Y....", "...Y...DGGGGGGGGGGD...Y....",
                "......DGGKGGGGKGGD..........", "......DGGKKKKKKGGD..........",
                ".......DDGGGGGGDD............", "..........GGGG..............",
                ".........DGGGGD.............", "...DD....DGGGGD....DD........",
                "..DGGD....DGGD....DGGD.......", "..DGGD....DGGD....DGGD.......",
                "...DD......DD......DD........"
            ]
        }
    }
}
