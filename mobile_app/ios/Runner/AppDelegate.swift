import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pcmPlayer: PcmAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PcmAudioPlayer") else {
      return
    }
    pcmPlayer = PcmAudioPlayer(messenger: registrar.messenger())
  }
}

final class PcmAudioPlayer {
  private let channel: FlutterMethodChannel
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var format: AVAudioFormat?
  private var pendingBuffers = 0
  private var streamEnded = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "com.example.lexicoach/pcm_player",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "configure":
        let args = call.arguments as? [String: Any]
        let sampleRate = args?["sampleRate"] as? Int ?? 24000
        let channels = args?["channels"] as? Int ?? 1
        self.configure(sampleRate: sampleRate, channels: channels)
        result(nil)
      case "playChunk":
        if let data = call.arguments as? FlutterStandardTypedData {
          self.playChunk(data.data)
        }
        result(nil)
      case "markStreamEnd":
        self.markStreamEnd()
        result(nil)
      case "stop":
        self.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func configure(sampleRate: Int, channels: Int) {
    stop()

    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
    try? audioSession.setActive(true)

    let channelCount = AVAudioChannelCount(channels)
    guard let newFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16,
      sampleRate: Double(sampleRate),
      channels: channelCount,
      interleaved: true
    ) else {
      return
    }

    format = newFormat
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: newFormat)
    try? engine.start()
    player.play()
    pendingBuffers = 0
    streamEnded = false
  }

  private func playChunk(_ data: Data) {
    guard let format, data.count > 0 else { return }
    let frameCount = AVAudioFrameCount(data.count / MemoryLayout<Int16>.size / Int(format.channelCount))
    guard frameCount > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
      return
    }

    buffer.frameLength = frameCount
    data.withUnsafeBytes { rawBuffer in
      guard let source = rawBuffer.baseAddress,
            let destination = buffer.int16ChannelData?[0] else {
        return
      }
      memcpy(destination, source, data.count)
    }

    pendingBuffers += 1
    streamEnded = false
    player.scheduleBuffer(buffer) { [weak self] in
      DispatchQueue.main.async {
        guard let self else { return }
        self.pendingBuffers = max(0, self.pendingBuffers - 1)
        self.notifyIdleIfNeeded()
      }
    }

    if !player.isPlaying {
      player.play()
    }
  }

  private func markStreamEnd() {
    streamEnded = true
    notifyIdleIfNeeded()
  }

  private func notifyIdleIfNeeded() {
    guard streamEnded, pendingBuffers == 0 else { return }
    streamEnded = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
      self?.channel.invokeMethod("playbackIdle", arguments: nil)
    }
  }

  private func stop() {
    streamEnded = false
    pendingBuffers = 0
    player.stop()
    if engine.isRunning {
      engine.stop()
    }
    engine.reset()
  }
}
