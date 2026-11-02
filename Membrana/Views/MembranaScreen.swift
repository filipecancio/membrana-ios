import SwiftUI

/// Tela principal do aplicativo Membrana no iOS, combinando o shader Metal SDF 360°
/// com superfícies translúcidas e bordas especulares no padrão Liquid Glass da Apple.
struct MembranaScreen: View {
    @State private var freeTension: Double = 48.0
    @State private var freeBoxWidth: Double = 260.0
    @State private var freeBoxHeight: Double = 70.0
    @State private var freeBallRadius: Double = 34.0
    @State private var glassRefraction: Double = 0.75

    private let accentViolet = Color(red: 0.49, green: 0.30, blue: 1.00)
    private let accentCyan = Color(red: 0.00, green: 0.90, blue: 1.00)

    var body: some View {
        ZStack {
            // Fundo profundo espacial
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.10),
                    Color(red: 0.08, green: 0.09, blue: 0.15),
                    Color(red: 0.04, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // 1. Top Bar em estilo Liquid Glass
                liquidGlassHeader

                // 2. Card Informativo Liquid Glass
                liquidGlassInfoCard

                // 3. Área Interativa Central com o Shader Metal SDF + Liquid Glass
                LiquidMembraneShaderBox(
                    boxWidth: freeBoxWidth,
                    boxHeight: freeBoxHeight,
                    boxCornerRadius: freeBoxHeight / 2.0,
                    ballRadius: freeBallRadius,
                    elasticTension: freeTension,
                    glassRefraction: glassRefraction
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.24),
                                    .white.opacity(0.05),
                                    accentCyan.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

                // 4. Painel de Calibração em Liquid Glass
                liquidGlassControlPanel
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews (Liquid Glass Design System)

    private var liquidGlassHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Membrana")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("360° Liquid Glass Membrane (Metal SDF)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    freeTension = 48.0
                    freeBoxWidth = 260.0
                    freeBoxHeight = 70.0
                    freeBallRadius = 34.0
                    glassRefraction = 0.75
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.45), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
            .accessibilityLabel("Resetar Parâmetros")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var liquidGlassInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.halffull")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentCyan, accentViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("Deformação livre 360° com refração Liquid Glass.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Arraste a esfera vermelha para fora da cápsula e observe a lente líquida refratar o fundo.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.70))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.30), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var liquidGlassControlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PARÂMETROS DA MEMBRANA 360° & LIQUID GLASS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(accentCyan)

            // Slider 1: Tensão da Membrana (uBlendK)
            parameterSlider(
                title: "Tensão da Membrana (Blend K)",
                valueText: "\(Int(freeTension)) pt",
                value: $freeTension,
                range: 8...100
            )

            // Slider 2: Raio da Bola Invasora
            parameterSlider(
                title: "Raio da Bola Invasora",
                valueText: "\(Int(freeBallRadius)) pt",
                value: $freeBallRadius,
                range: 20...55
            )

            // Slider 3: Índice de Refração Liquid Glass
            parameterSlider(
                title: "Refração Óptica (Liquid Glass)",
                valueText: "\(Int(glassRefraction * 100))%",
                value: $glassRefraction,
                range: 0...1
            )
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.38),
                            .white.opacity(0.08),
                            accentViolet.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func parameterSlider(
        title: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text(valueText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(accentCyan)
            }

            Slider(value: value, in: range)
                .tint(accentViolet)
        }
    }
}

#Preview {
    MembranaScreen()
}
