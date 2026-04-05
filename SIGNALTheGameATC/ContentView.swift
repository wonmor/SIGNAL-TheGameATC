import SwiftUI

struct ContentView: View {
    @StateObject private var radio = RadioAudioManager()
    @StateObject private var game: ATCGameViewModel

    @State private var showSettings = false
    @State private var apiKeyDraft = ""
    @State private var modelDraft = ""
    @State private var streamDraft = ""

    init() {
        let r = RadioAudioManager()
        _radio = StateObject(wrappedValue: r)
        _game = StateObject(wrappedValue: ATCGameViewModel(audio: r))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    header
                    TorontoRadarView()
                        .frame(height: 220)
                        .padding(.horizontal)
                    log
                    composer
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SIGNAL")
                        .font(.system(.headline, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(Color.green.opacity(0.9))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.green.opacity(0.85))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await game.newSimulation(apiKey: resolvedKey()) }
                    } label: {
                        Label("New", systemImage: "antenna.radiowaves.left.and.right")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(Color.green.opacity(0.85))
                    }
                    .disabled(game.isBusy)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    apiKeyDraft: $apiKeyDraft,
                    modelDraft: $modelDraft,
                    streamURLDraft: $streamDraft,
                    onSave: {
                        game.modelName = modelDraft
                        game.saveStreamURL(streamDraft)
                        radio.bedVolume = radio.bedVolume
                        radio.applyStreamURLFromStorage(streamDraft)
                        Task { await game.newSimulation(apiKey: resolvedKey()) }
                    }
                )
            }
            .onAppear {
                if !radio.isRunning { radio.start() }
                game.bindAudio(radio)
                apiKeyDraft = KeychainStore.loadAPIKey() ?? ""
                modelDraft = game.modelName
                streamDraft = game.loadStreamURL()
                Task {
                    guard game.messages.isEmpty else { return }
                    let key = (KeychainStore.loadAPIKey() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if key.isEmpty {
                        game.messages.append(GameMessage(
                            speaker: .system,
                            text: "Training-style ATC simulation. Add your OpenAI API key in Settings, then tap New. You work Toronto approach: keep phraseology sharp and vectors sensible."
                        ))
                    } else {
                        await game.newSimulation(apiKey: key)
                    }
                }
            }
            .onChange(of: radio.bedVolume) { _, _ in radio.updateMixLevels() }
            .onChange(of: radio.streamVolume) { _, _ in radio.updateMixLevels() }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("You are Toronto approach. Stable clearances beat rushed chatter.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.green.opacity(0.55))
            HStack {
                Text("STATIC")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.orange.opacity(0.7))
                Slider(value: $radio.bedVolume, in: 0 ... 1)
                Text("STREAM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.cyan.opacity(0.6))
                Slider(value: $radio.streamVolume, in: 0 ... 1)
            }
            if let err = game.errorText {
                Text(err)
                    .font(.footnote.monospaced())
                    .foregroundStyle(Color.red.opacity(0.9))
            }
        }
        .padding(.horizontal)
    }

    private var log: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(game.messages) { m in
                        messageRow(m)
                            .id(m.id)
                    }
                    if game.isBusy {
                        ProgressView()
                            .tint(Color.green.opacity(0.8))
                            .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.green.opacity(0.2))
            )
            .padding(.horizontal)
            .onChange(of: game.messages.count) { _, _ in
                if let last = game.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Say your transmission…", text: $game.composerText, axis: .vertical)
                .lineLimit(1 ... 4)
                .textInputAutocapitalization(.characters)
                .padding(10)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.green.opacity(0.25))
                )
                .foregroundStyle(Color.green.opacity(0.95))
                .font(.system(.body, design: .monospaced))
            Button {
                Task { await game.sendPlayerTransmission(apiKey: resolvedKey()) }
            } label: {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .padding(12)
                    .background(Color.green.opacity(game.isBusy ? 0.15 : 0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(game.isBusy || game.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.black.opacity(0.9))
    }

    private func messageRow(_ m: GameMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tag(for: m.speaker))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color.green.opacity(0.55))
                Spacer()
                Text(m.created.formatted(date: .omitted, time: .shortened))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            Text(m.text)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(color(for: m.speaker))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tag(for s: RadioSpeaker) -> String {
        switch s {
        case .atc: "YOU — TORONTO"
        case .frequency: "121.9 — RADIO"
        case .system: "SYS"
        }
    }

    private func color(for s: RadioSpeaker) -> Color {
        switch s {
        case .atc: Color.cyan.opacity(0.95)
        case .frequency: Color.green.opacity(0.92)
        case .system: Color.orange.opacity(0.85)
        }
    }

    private func resolvedKey() -> String {
        let k = KeychainStore.loadAPIKey() ?? ""
        return k.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? apiKeyDraft : k
    }
}

#Preview {
    ContentView()
}
