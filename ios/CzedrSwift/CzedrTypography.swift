//
//  CzedrTypography.swift
//  Three in-app text sizes (Standard / Large / Extra large).
//

import SwiftUI

enum CzedrTextSize: String, CaseIterable, Identifiable {
    case standard
    case large
    case extraLarge

    static let storageKey = "czedr_text_size"
    static let defaultChoice: CzedrTextSize = .large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Standard"
        case .large: return "Large"
        case .extraLarge: return "Extra large"
        }
    }

    /// Drives Dynamic Type for semantic fonts (.headline, .caption, etc.).
    var contentSizeCategory: ContentSizeCategory {
        switch self {
        case .standard: return .large
        case .large: return .extraLarge
        case .extraLarge: return .accessibilityLarge
        }
    }

    /// Scales fixed point sizes (balance, PIN slots, icons).
    var scale: CGFloat {
        switch self {
        case .standard: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.22
        }
    }

    static func fromStored(_ raw: String) -> CzedrTextSize {
        CzedrTextSize(rawValue: raw) ?? .defaultChoice
    }

    static func scaled(_ points: CGFloat, size: CzedrTextSize) -> CGFloat {
        round(points * size.scale)
    }
}

enum CzedrTypography {
    static func contentSizeCategory(for size: CzedrTextSize) -> ContentSizeCategory {
        size.contentSizeCategory
    }

    static func scaled(_ points: CGFloat, size: CzedrTextSize) -> CGFloat {
        CzedrTextSize.scaled(points, size: size)
    }
}

private struct CzedrTextSizeKey: EnvironmentKey {
    static let defaultValue = CzedrTextSize.defaultChoice
}

extension EnvironmentValues {
    var czedrTextSize: CzedrTextSize {
        get { self[CzedrTextSizeKey.self] }
        set { self[CzedrTextSizeKey.self] = newValue }
    }
}

struct CzedrTextSizePicker: View {
    @AppStorage(CzedrTextSize.storageKey) private var storedRaw = CzedrTextSize.defaultChoice.rawValue

    private var selection: CzedrTextSize {
        CzedrTextSize.fromStored(storedRaw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Text size")
                .font(.caption)
                .foregroundColor(CzedrPalette.caption)
            Text("Applies across the app. Standard is closest to normal phone text.")
                .font(.caption2)
                .foregroundColor(CzedrPalette.caption)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(CzedrTextSize.allCases) { size in
                    Button(action: { storedRaw = size.rawValue }) {
                        Text(size.label)
                            .font(.subheadline.weight(selection == size ? .bold : .regular))
                            .foregroundColor(selection == size ? CzedrPalette.fieldText : CzedrPalette.lightText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selection == size ? CzedrPalette.cheddarGold : CzedrPalette.charcoalButton)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityAddTraits(selection == size ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 8)
    }
}
