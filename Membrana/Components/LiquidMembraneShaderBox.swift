import SwiftUI

/// Componente interativo que renderiza a camada de fundo refratada pelo shader Metal `liquidGlassMembrane`.
/// Suporta arraste livre em 360° e retorno elástico governado por um oscilador harmônico subamortecido (`spring`).
struct LiquidMembraneShaderBox: View {
    var boxWidth: CGFloat = 260
    var boxHeight: CGFloat = 70
    var boxCornerRadius: CGFloat = 35
    var ballRadius: CGFloat = 34
    var elasticTension: CGFloat = 48
    var glassRefraction: CGFloat = 0.75

    /// Deslocamento 2D instantâneo da esfera invasora em relação ao centro
    @State private var ballOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            let ballCenter = CGPoint(
                x: center.x + ballOffset.width,
                y: center.y + ballOffset.height
            )

            // Camada de fundo rica em gradientes luminosos e grade óptica para evidenciar
            // a refração real (lensing) do Liquid Glass quando a membrana se deforma.
            ZStack {
                LiquidGlassBackdropCanvas()

                // Superfície transparente que preenche o container para que o layerEffect processe toda a área
                Color.white.opacity(0.001)
            }
            .compositingGroup()
            .layerEffect(
                ShaderLibrary.liquidGlassMembrane(
                    .float2(center.x, center.y),
                    .float2(boxWidth / 2.0, boxHeight / 2.0),
                    .float(boxCornerRadius),
                    .float2(ballCenter.x, ballCenter.y),
                    .float(ballRadius),
                    .float(elasticTension),
                    .float(glassRefraction),
                    .color(Color.white),
                    .color(Color(red: 0.90, green: 0.22, blue: 0.21))
                ),
                maxSampleOffset: CGSize(width: 48, height: 48)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        ballOffset = value.translation
                    }
                    .onEnded { _ in
                        isDragging = false
                        // Retorno elástico 360° com mola subamortecida (equivalente ao Spring.DampingRatioMediumBouncy)
                        withAnimation(
                            .spring(
                                response: 0.55,
                                dampingFraction: 0.50,
                                blendDuration: 0
                            )
                        ) {
                            ballOffset = .zero
                        }
                    }
            )
        }
    }
}

/// Fundo atmosférico com orbes luminosos e malha sutil que permite visualizar o desvio óptico
/// dos raios de luz através da lente Liquid Glass da membrana.
private struct LiquidGlassBackdropCanvas: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // Orbes de luz ambiente no fundo escuro
            let violetOrb = CGRect(x: center.x - 150, y: center.y - 130, width: 220, height: 220)
            context.fill(
                Path(ellipseIn: violetOrb),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.49, green: 0.30, blue: 1.00).opacity(0.42),
                        Color.clear
                    ]),
                    center: CGPoint(x: violetOrb.midX, y: violetOrb.midY),
                    startRadius: 5,
                    endRadius: 120
                )
            )

            let cyanOrb = CGRect(x: center.x - 40, y: center.y - 60, width: 230, height: 230)
            context.fill(
                Path(ellipseIn: cyanOrb),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.00, green: 0.90, blue: 1.00).opacity(0.30),
                        Color.clear
                    ]),
                    center: CGPoint(x: cyanOrb.midX, y: cyanOrb.midY),
                    startRadius: 5,
                    endRadius: 125
                )
            )

            // Malha de precisão sutil (permite enxergar claramente a refração de lente nas bordas do SDF)
            let step: CGFloat = 28
            var gridPath = Path()
            stride(from: 0, through: size.width, by: step).forEach { x in
                gridPath.move(to: CGPoint(x: x, y: 0))
                gridPath.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: 0, through: size.height, by: step).forEach { y in
                gridPath.move(to: CGPoint(x: 0, y: y))
                gridPath.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(gridPath, with: .color(.white.opacity(0.055)), lineWidth: 0.75)
        }
    }
}
