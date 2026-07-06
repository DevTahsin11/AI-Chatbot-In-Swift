//
//  ContentView.swift
//  Tech.AI
//
//  Created by Tahsin Ahmed on 12/20/25
//

import SwiftUI
import Speech
import AVFoundation

struct ContentView: View {

    // Chat state (messages, input, streaming) lives in the view model.
    @State private var viewModel = ChatViewModel()

    // Voice-To-Text Variables
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesScroll
                inputBar
            }
            .navigationTitle("Tech.AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        withAnimation { viewModel.clearChat() }
                    } label: {
                        Label("Clear Chat", systemImage: "trash")
                            .font(.subheadline)
                            
                    }
                    .glassButtonStyle(tint: .red)
                    .disabled(viewModel.isStreaming || viewModel.messages.isEmpty)
                    .accessibilityIdentifier("clearButton")
                    .accessibilityLabel("Clear chat")
                }
            }
        }
    }

    // Chat messages scroll view — auto-scrolls to the newest content
    // as tokens stream in.
    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.last?.text) { _, _ in
                guard let id = viewModel.messages.last?.id else { return }
                if viewModel.isStreaming {
                    proxy.scrollTo(id, anchor: .bottom)
                } else {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // Bottom control bar: glass capsule input field + voice + send,
    // grouped in a GlassEffectContainer so their shapes blend together.
    private var inputBar: some View {
        inputBarContainer {
            HStack(spacing: 8) {

                // Message box
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.secondary)
                    TextField("Ask Anything About Computer Science...", text: $viewModel.inputText)
                        .textFieldStyle(.plain)
                        .submitLabel(.send)
                        .onSubmit { Task { await viewModel.sendMessage() } }
                        .accessibilityIdentifier("messageField")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .inputSurface()

                // Voice button
                Button {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                } label: {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 18, weight: .semibold))
                        .symbolEffect(.pulse, isActive: isRecording)
                }
                .glassButtonStyle(tint: isRecording ? .red : .blue)
                .accessibilityLabel(isRecording ? "Stop voice input" : "Start voice input")

                // Send button — primary action
                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    if viewModel.isStreaming {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .prominentGlassButtonStyle(tint: .blue)
                .disabled(viewModel.inputText.isEmpty || viewModel.isStreaming)
                .accessibilityIdentifier("sendButton")
                .accessibilityLabel("Send")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // Wraps the bar in a GlassEffectContainer where available so multiple
    // glass shapes render efficiently and blend; passes content through
    // unchanged on older systems.
    @ViewBuilder
    private func inputBarContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 8) { content() }
        } else {
            content()
        }
    }

    // Function To Start Recording (Subject To Change)
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization
        {authStatus in
            if authStatus == .authorized
            {
                DispatchQueue.main.async
                {
                    self.isRecording = true
                }

                self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Audio session error: \(error)")
                }

                let inputNode = audioEngine.inputNode

                guard let recognitionRequest = recognitionRequest
                else
                {
                    fatalError("Unable to create recognition request")
                }
                recognitionRequest.shouldReportPartialResults = false

                self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest)
                {result, error in
                    if let result = result
                    {
                        let spokenText = result.bestTranscription.formattedString
                        print("Recognized: \(spokenText)")
                        DispatchQueue.main.async
                        {
                            self.viewModel.inputText = spokenText
                            Task {
                                await self.viewModel.sendMessage()
                            }
                        }
                    }

                    if error != nil || (result?.isFinal ?? false)
                    {
                        self.audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                        DispatchQueue.main.async
                        {
                            self.isRecording = false
                        }
                    }
                }

                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat)
                {buffer, when in
                    self.recognitionRequest?.append(buffer)
                }

                self.audioEngine.prepare()
                do {
                    try self.audioEngine.start()
                } catch
                {
                    print("Audio Engine start error: \(error)")
                }
            } else{
                print("Speech recognition authorization denied")
            }
        }
    }

    // Function To Stop Recording
    func stopRecording()
    {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
    }
}

// Preview
#Preview {
    ContentView()
}
