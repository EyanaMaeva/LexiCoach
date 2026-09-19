package com.example.lexicoach

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.lexicoach/pcm_player"
    private val executor = Executors.newSingleThreadExecutor()
    private var audioTrack: AudioTrack? = null
    private var methodChannel: MethodChannel? = null
    private var streamEnded = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    val sampleRate = call.argument<Int>("sampleRate") ?: 24000
                    val channels = call.argument<Int>("channels") ?: 1
                    configurePlayer(sampleRate, channels)
                    result.success(null)
                }
                "playChunk" -> {
                    val bytes = call.arguments as? ByteArray
                    if (bytes != null) {
                        playChunk(bytes)
                    }
                    result.success(null)
                }
                "markStreamEnd" -> {
                    markStreamEnd()
                    result.success(null)
                }
                "stop" -> {
                    stopPlayer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun configurePlayer(sampleRate: Int, channels: Int) {
        stopPlayer()

        val channelMask = if (channels == 1) {
            AudioFormat.CHANNEL_OUT_MONO
        } else {
            AudioFormat.CHANNEL_OUT_STEREO
        }
        val minBufferSize = AudioTrack.getMinBufferSize(
            sampleRate,
            channelMask,
            AudioFormat.ENCODING_PCM_16BIT
        )

        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setChannelMask(channelMask)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .build()
            )
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setBufferSizeInBytes(minBufferSize * 4)
            .build()
        audioTrack?.play()
        streamEnded = false
    }

    private fun playChunk(bytes: ByteArray) {
        val track = audioTrack ?: return
        streamEnded = false
        executor.execute {
            track.write(bytes, 0, bytes.size)
        }
    }

    private fun markStreamEnd() {
        streamEnded = true
        executor.execute {
            val track = audioTrack ?: return@execute
            val bufferSize = track.bufferSizeInFrames
            val sampleRate = track.sampleRate.coerceAtLeast(1)
            val delayMs = ((bufferSize.toDouble() / sampleRate.toDouble()) * 1000).toLong() + 250
            Thread.sleep(delayMs)
            if (streamEnded) {
                runOnUiThread {
                    methodChannel?.invokeMethod("playbackIdle", null)
                }
            }
        }
    }

    private fun stopPlayer() {
        streamEnded = false
        audioTrack?.pause()
        audioTrack?.flush()
        audioTrack?.release()
        audioTrack = null
    }
}
