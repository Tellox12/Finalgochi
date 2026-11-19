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

    /// Limited NES-style palette: one dark outline, two or three tones per material.
    private let colors: [Character: UIColor] = [
        "K": UIColor(red: 0.07, green: 0.08, blue: 0.14, alpha: 1),
        "W": UIColor(red: 0.96, green: 0.95, blue: 1.00, alpha: 1),
        "w": UIColor(red: 0.74, green: 0.77, blue: 0.91, alpha: 1),
        "R": UIColor(red: 0.86, green: 0.19, blue: 0.26, alpha: 1),
        "r": UIColor(red: 0.56, green: 0.10, blue: 0.17, alpha: 1),
        "P": UIColor(red: 0.98, green: 0.47, blue: 0.66, alpha: 1),
        "V": UIColor(red: 0.47, green: 0.38, blue: 0.72, alpha: 1),
        "v": UIColor(red: 0.28, green: 0.22, blue: 0.49, alpha: 1),
        "Y": UIColor(red: 1.00, green: 0.80, blue: 0.28, alpha: 1),
        "y": UIColor(red: 0.90, green: 0.55, blue: 0.15, alpha: 1),
        "O": UIColor(red: 0.96, green: 0.47, blue: 0.17, alpha: 1),
        "G": UIColor(red: 0.33, green: 0.72, blue: 0.38, alpha: 1),
        "g": UIColor(red: 0.14, green: 0.44, blue: 0.26, alpha: 1),
        "S": UIColor(red: 0.94, green: 0.89, blue: 0.62, alpha: 1)
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
            // Round white body, red pom-pom, purple bat wings and tiny feet: NES-era moogle.
            return [
                "..........RRRR..........",
                ".........RRRRRR.........",
                ".........RRRRRR.........",
                "..........rrrr..........",
                "........KKKKKKKK........",
                "......KWWWWWWWWWWK......",
                ".....KWWWWWWWWWWWWK.....",
                "....KWWWWWWWWWWWWWWK....",
                "....KWWWWWWWWWWWWWWK....",
                "...vKWWWWWWWWWWWWWWKv...",
                "..vVKWWWKKWWWWKKWWWKVv..",
                "..vVKWWWKKWWWWKKWWWKVv..",
                ".vVVKWWWWWWPPWWWWWWKVVv.",
                "..vVKWWWWWWWWWWWWWWKVv..",
                "...vKWWWWWWWWWWWWWWKv...",
                "....KwWWWWWWWWWWWWwK....",
                "....KwWWWWWWWWWWWWwK....",
                "....KwwWWWWWWWWWWwwK....",
                ".....KwwWWWWWWWWwwK.....",
                "......KwwwwWWwwwwK......",
                "........KKKKKKKK........",
                "......KWWWK..KWWWK......",
                "......KWWWK..KWWWK......",
                "......KKKKK..KKKKK......"
            ]
        case .chocobo:
            // Crest, long neck, hooked beak, fan tail and big orange feet.
            return [
                "..............Y.Y.......",
                ".............YY.YY......",
                ".............KKKKK......",
                "............KYYYYYK.....",
                "............KYYKYYKOO...",
                "............KYYYYYKOOO..",
                "............KYYYYYKOO...",
                "............KYYYYK......",
                ".............KYYK.......",
                "............KYYK........",
                "...........KYYK.........",
                "...YY.....KYYK..........",
                "..YYY....KYYK...........",
                "..YYYKYYYYYYYYYYYYK.....",
                "...KYYYYYYYYYYYYYYYYK...",
                "..KYYyyyyyYYYYYYYYYYYK..",
                "..KYyyyyyyYYYYYYYYYYYK..",
                "...KYyyyyyYYYYYYYYYYK...",
                "....KYyyyyYYYYYYYYYK....",
                "......KYYYYYYYYYYK......",
                ".......KKKKKKKKKK.......",
                "......KYK...KYK.........",
                "......KYK...KYK.........",
                ".....KOOOOK.KOOOOK......"
            ]
        case .cactilio:
            // Spiked crown, stoic face, needle-tipped arms and stubby legs.
            return [
                ".......S..S..S..........",
                ".......S..S..S..........",
                ".......KKKKKKKKKK.......",
                "......KGGGGGGGGGGK......",
                ".....SKGGGGGGGGGGKS.....",
                "......KGGGGGGGGGGK......",
                "......KGGKKGGKKGGK......",
                "......KGGGGGGGGGgK......",
                "......KGGGKKKKGGGK......",
                "......KGGGGGGGGGgK......",
                "......KGGGGGGGGGgK......",
                ".KGGGGKGGGGGGGGGgKGGGGK.",
                "SGGGGGKGGGGGGGGGgKGGGGGS",
                ".KGGGGKGGGGGGGGGgKGGGGK.",
                "......KGGGGGGGGGgK......",
                "......KGGGGGGGGGgK......",
                "......KGGGGGGGGGgK......",
                "......KGGGGGGGGGgK......",
                "......KGGGGGGGGGgK......",
                ".....SKGGGGGGGGGgKS.....",
                ".......KKKKKKKKKK.......",
                ".......KGGK..KGGK.......",
                ".......KGGK..KGGK.......",
                ".......KKKK..KKKK......."
            ]
        }
    }
}
