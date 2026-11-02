# Membrana (iOS — SwiftUI + Metal Liquid Glass) 🫧🍎

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20Liquid%20Glass-007AFF?logo=apple)](https://developer.apple.com/xcode/swiftui/)
[![Metal](https://img.shields.io/badge/Shader-Metal%20SDF-8E8E93?logo=apple)](https://developer.apple.com/metal/)
[![Android Version](https://img.shields.io/badge/Android-Membrana%20(AGSL)-3DDC84?logo=android)](https://github.com/filipecancio/membrana)

Versão iOS nativa do **Membrana**, construída com **SwiftUI** e **Metal Shading Language (`.metal`)**, unindo a física matemática de **Signed Distance Fields (SDF) + Smooth Minimum (`smin`)** ao padrão visual **Liquid Glass** para iPhone.

> 📦 **Nome do Projeto Xcode / App**: `Membrana` (`Membrana.xcodeproj` / `com.cancio.membrana`)  
> 🌐 **Repositório Android Equivalente**: [filipecancio/membrana](https://github.com/filipecancio/membrana)

---

## ✨ Destaques Tecnológicos (SwiftUI + Metal + Liquid Glass)

* **📐 Signed Distance Fields em Metal (`ElasticWaves.metal`)**:
  * Implementação 1:1 das primitivas `sdRoundBox` (pílula central) e `sdCircle` (esfera invasora) combinadas via *Polynomial Smooth Minimum* quadrático (`smin`).
* **💧 Óptica Liquid Glass em Tempo Real (`[[ stitchable ]] liquidGlassMembrane`)**:
  * **Normal Map Analítico ($\nabla d$)**: Calcula o gradiente bidimensional do campo de distância por diferenças finitas para reconstruir a curvatura 3D da gota líquida próxima às bordas.
  * **Refração Real de Camada (`SwiftUI::Layer`)**: Desvia os raios da camada de fundo (`layer.sample`) proporcionalmente à normal da superfície com dispersão cromática sutil (R/G/B) nas zonas de alta tensão.
  * **Iluminação Especular & Borda Fresnel**: Reflexos especulares *Blinn-Phong* combinados com *rim light* translúcido e materiais `.ultraThinMaterial` nos controles da interface.
* **🎢 Física de Mola 360° a 120 Hz (ProMotion)**:
  * Arraste multiaxial livre via `DragGesture` e retorno ao centro com oscilador harmônico subamortecido (`.spring(response: 0.55, dampingFraction: 0.50)`).

---

## 🗂️ Estrutura do Projeto Xcode (`Membrana.xcodeproj`)

```text
membrana-ios/
├── Membrana.xcodeproj/              # Projeto Xcode (Target: Membrana)
└── Membrana/
    ├── MembranaApp.swift            # Entry point (@main)
    ├── Views/
    │   └── MembranaScreen.swift     # Tela principal e controles em estilo Liquid Glass
    ├── Components/
    │   └── LiquidMembraneShaderBox.swift # Host do .layerEffect Metal + DragGesture 360°
    ├── Shaders/
    │   └── ElasticWaves.metal       # Shader [[ stitchable ]] SDF + smin + Refração Liquid Glass
    └── Assets.xcassets/             # Ícone e AccentColor do app
```

---

## 🎛️ Controles na Tela

1. **Tensão da Membrana (`Blend K`)**: Controla o alcance da ponte elástica entre a cápsula e a esfera (`8 pt` a `100 pt`).
2. **Raio da Bola Invasora**: Ajusta o raio da esfera arrastável (`20 pt` a `55 pt`).
3. **Refração Óptica (Liquid Glass)**: Controla o índice de refração da lente líquida sobre o fundo (`0%` a `100%`).

---

## 🚀 Como Executar no Xcode

1. Clone o repositório:
   ```bash
   git clone https://github.com/filipecancio/membrana-ios.git
   cd membrana-ios
   ```
2. Abra o projeto **`Membrana.xcodeproj`** no **Xcode 15+ / Xcode 16+**:
   ```bash
   open Membrana.xcodeproj
   ```
3. Selecione um simulador de **iPhone (iOS 17.0+)** ou seu iPhone físico e pressione **Run (`⌘R`)**.
