//
//  CrossHatchView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI

/// Static diagonal crosshatch background (no parallax)
struct CrossHatchBackground: View {
    var lineColor: Color = .gray.opacity(0.001)
    var lineWidth: CGFloat = 0.8
    var spacing: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            Canvas { context, canvasSize in
                let maxDimension = max(canvasSize.width, canvasSize.height)
                let patternSize = maxDimension * 2

                var path = Path()

                // Diagonals: bottom-left → top-right (/)
                var offset: CGFloat = -patternSize
                while offset < patternSize {
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: offset + patternSize, y: patternSize))
                    offset += spacing
                }

                // Diagonals: top-left → bottom-right (\)
                offset = 0
                while offset < patternSize * 2 {
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: offset - patternSize, y: patternSize))
                    offset += spacing
                }

                context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

#Preview {
    ZStack {
        CrossHatchBackground()
        Text("Crosshatch Background")
            .font(.headline)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
