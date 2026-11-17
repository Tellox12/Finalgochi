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

        let orbColor: UIColor = phase == .night ? UIColor(red: 0.88, green: 0.91, blue: 1, alpha: 1) : UIColor(red: 1, green: 0.82, blue: 0.43, alpha: 1)
        context.setFillColor(orbColor.cgColor)
        context.fillEllipse(in: CGRect(x: rect.width * 0.78, y: 24, width: 34, height: 34))

        context.setFillColor(UIColor(red: 0.15, green: 0.29, blue: 0.34, alpha: 1).cgColor)
        let hill = CGMutablePath()
        hill.move(to: CGPoint(x: 0, y: rect.height * 0.78))
        hill.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height * 0.73), control: CGPoint(x: rect.width * 0.48, y: rect.height * 0.47))
        hill.addLine(to: CGPoint(x: rect.width, y: rect.height))
        hill.addLine(to: CGPoint(x: 0, y: rect.height))
        hill.closeSubpath()
        context.addPath(hill)
        context.fillPath()
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
