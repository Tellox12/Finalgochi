import UIKit

final class PixelPetSpriteView: UIView {
    var kind: PetKind = .moogle {
        didSet {
            accessibilityLabel = "Ilustración de \(kind.displayName)"
            setNeedsDisplay()
        }
    }

    private let colors: [Character: UIColor] = [
        "D": UIColor(red: 0.16, green: 0.17, blue: 0.30, alpha: 1),
        "K": UIColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1),
        "W": UIColor(red: 0.93, green: 0.91, blue: 0.98, alpha: 1),
        "Y": UIColor(red: 1.00, green: 0.78, blue: 0.28, alpha: 1),
        "O": UIColor(red: 0.97, green: 0.49, blue: 0.24, alpha: 1),
        "P": UIColor(red: 0.99, green: 0.46, blue: 0.65, alpha: 1),
        "G": UIColor(red: 0.30, green: 0.72, blue: 0.48, alpha: 1),
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

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let rows = spriteRows
        let widestRow = CGFloat(rows.map { $0.count }.max() ?? 16)
        let pixelSize = min(bounds.width / widestRow, bounds.height / CGFloat(rows.count))
        let spriteHeight = pixelSize * CGFloat(rows.count)
        let originY = (bounds.height - spriteHeight) / 2

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
    }

    private var spriteRows: [String] {
        switch kind {
        case .moogle:
            return [
                ".......YY.......", "......DYYD......", "...DDD....DDD...", "..DWWD....DWWD..",
                "..DWWD....DWWD..", "...DDD....DDD...", "......DDDD......", "....DDWWWWDD....",
                "...DWWWWWWWWD...", "..DWWWWWWWWWWD..", "..DWWKWWKWWWD..", "...DWWWWWWWWD...",
                "....DDWWWWDD....", ".....DDDDDD.....", "......DPPD......", ".....DD..DD....."
            ]
        case .chocobo:
            return [
                "......DDDD......", ".....DYYYYD.....", "....DYYYYYYD....", "...DYYYYYYYYD...",
                "...DYYDDYYDD....", "...DYYKYYKYYD...", "....DYYYYYYD....", ".....DDYYDD.....",
                "....DYYYYD......", "...DYYYYYYD.....", "..DYYYYYYYYD....", ".DYYYYYYYYYYD...",
                ".DYYYYYYYYYYDD..", "..DDYYYYYYYYYYD.", "....DDDD..DDDD..", "...DD........DD."
            ]
        case .cactilio:
            return [
                ".......DD.......", "......DGGD......", "......DGGD......", "......DGGD......",
                "......DGGD......", "..DD..DGGDD.....", ".DGGD.DGGGD.....", ".DGGD.DGGGD.....",
                ".DGGDDGGGGDD....", "..DGGGGGGGGGDD..", "...DDGGGGGGGGGD.", "....DGGGGGGGGGD.",
                "...DGGGDGGGGGD..", "...DGGKDGKGGD...", "....DDDDDDDDD...", "......D...D......"
            ]
        }
    }
}
