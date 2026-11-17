import UIKit

final class HabitatSceneView: UIView {
    var phase: WorldPhase = .night { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), rect.width > 0, rect.height > 0 else { return }
        let colors = palette.map(\.cgColor) as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: rect.height), options: [])

        if phase == .night || phase == .dusk {
            for index in 0..<22 {
                let x = CGFloat((index * 47 + 17) % 300) / 300 * rect.width
                let y = CGFloat((index * 29 + 11) % 105) / 105 * rect.height * 0.55
                context.setFillColor(UIColor.white.withAlphaComponent(index.isMultiple(of: 3) ? 0.8 : 0.4).cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: 2.5, height: 2.5))
            }
        }

        if phase == .day || phase == .dawn {
            context.setFillColor(UIColor.white.withAlphaComponent(0.12).cgColor)
            let cloudX = rect.width * 0.20
            let cloudY = rect.height * 0.29
            context.fillEllipse(in: CGRect(x: cloudX, y: cloudY, width: 32, height: 12))
            context.fillEllipse(in: CGRect(x: cloudX + 9, y: cloudY - 7, width: 20, height: 18))
        }

        let orbColor: UIColor = phase == .night ? UIColor(red: 0.88, green: 0.91, blue: 1, alpha: 1) : UIColor(red: 1, green: 0.82, blue: 0.43, alpha: 1)
        context.setFillColor(orbColor.withAlphaComponent(0.12).cgColor)
        context.fillEllipse(in: CGRect(x: rect.width * 0.78 - 9, y: 15, width: 52, height: 52))
        context.setFillColor(orbColor.cgColor)
        context.fillEllipse(in: CGRect(x: rect.width * 0.78, y: 24, width: 34, height: 34))

        context.setFillColor(UIColor(red: 0.12, green: 0.23, blue: 0.34, alpha: 0.64).cgColor)
        let farHill = CGMutablePath()
        farHill.move(to: CGPoint(x: 0, y: rect.height * 0.82))
        farHill.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height * 0.80), control: CGPoint(x: rect.width * 0.48, y: rect.height * 0.55))
        farHill.addLine(to: CGPoint(x: rect.width, y: rect.height))
        farHill.addLine(to: CGPoint(x: 0, y: rect.height))
        farHill.closeSubpath()
        context.addPath(farHill)
        context.fillPath()

        context.setFillColor(UIColor(red: 0.15, green: 0.29, blue: 0.34, alpha: 1).cgColor)
        let hill = CGMutablePath()
        hill.move(to: CGPoint(x: 0, y: rect.height * 0.78))
        hill.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height * 0.73), control: CGPoint(x: rect.width * 0.48, y: rect.height * 0.47))
        hill.addLine(to: CGPoint(x: rect.width, y: rect.height))
        hill.addLine(to: CGPoint(x: 0, y: rect.height))
        hill.closeSubpath()
        context.addPath(hill)
        context.fillPath()

        context.setStrokeColor(UIColor(red: 0.48, green: 0.75, blue: 0.54, alpha: 0.48).cgColor)
        context.setLineWidth(2)
        for index in 0..<9 {
            let x = CGFloat(index) * rect.width / 8
            let baseY = rect.height * (0.90 + CGFloat(index % 3) * 0.025)
            context.move(to: CGPoint(x: x, y: baseY))
            context.addLine(to: CGPoint(x: x - 3, y: baseY - 8))
            context.move(to: CGPoint(x: x, y: baseY))
            context.addLine(to: CGPoint(x: x + 4, y: baseY - 6))
        }
        context.strokePath()
    }

    private var palette: [UIColor] {
        switch phase {
        case .dawn: return [UIColor(red: 0.35, green: 0.31, blue: 0.53, alpha: 1), UIColor(red: 0.91, green: 0.56, blue: 0.48, alpha: 1)]
        case .day: return [UIColor(red: 0.18, green: 0.43, blue: 0.60, alpha: 1), UIColor(red: 0.48, green: 0.69, blue: 0.63, alpha: 1)]
        case .dusk: return [UIColor(red: 0.30, green: 0.24, blue: 0.49, alpha: 1), UIColor(red: 0.78, green: 0.38, blue: 0.38, alpha: 1)]
        case .night: return [UIColor(red: 0.09, green: 0.13, blue: 0.30, alpha: 1), UIColor(red: 0.21, green: 0.27, blue: 0.42, alpha: 1)]
        }
    }
}
