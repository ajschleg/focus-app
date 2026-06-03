import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var engine: FocusEngine

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Plan a focus block")
                    .font(.largeTitle.bold())
                Text("Pick a length, set the phone down, and work. We'll log when you leave the app or pick the phone up.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                ForEach(BlockTemplate.presets) { template in
                    TemplateRow(template: template, selected: template == engine.template) {
                        engine.select(template)
                    }
                }
            }

            if !engine.motionAvailable {
                Label("Motion sensing is off here (likely the Simulator). Leave-the-app detection still works — run on a real iPhone to test pickups.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.orange)
                    .padding()
                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button {
                engine.startFocus()
            } label: {
                Text("Start focus · \(engine.template.focusMinutes) min")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

private struct TemplateRow: View {
    let template: BlockTemplate
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name).font(.headline)
                    Text("\(template.focusMinutes) min focus · \(template.breakMinutes) min break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            }
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlanView().environmentObject(FocusEngine())
}
