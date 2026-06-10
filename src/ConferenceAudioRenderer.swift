import Foundation

protocol ConferenceAudioRendererDelegate: AnyObject {
	func onConferenceAudioFrame(label: String,
		bitsPerSample: Int,
		sampleRate: Int,
		numberOfChannels: Int,
		numberOfFrames: Int,
		timestampMs: Int64,
		timestampIsValid: Bool)
}

class ConferenceAudioRenderer: NSObject, RTCAudioRenderer {
	let label: String
	weak var delegate: ConferenceAudioRendererDelegate?

	private(set) var callbackCount: UInt64 = 0
	private(set) var frameCount: UInt64 = 0
	private(set) var latestSampleRate: Int = 0
	private(set) var latestChannels: Int = 0
	private(set) var latestRmsDbfs: Double = -160.0
	private(set) var latestPeakDbfs: Double = -160.0

	init(label: String, delegate: ConferenceAudioRendererDelegate?) {
		self.label = label
		self.delegate = delegate
	}

	func renderPCMData(_ audio_data: UnsafeRawPointer,
		bitsPerSample bits_per_sample: Int,
		sampleRate sample_rate: Int,
		numberOfChannels number_of_channels: Int,
		numberOfFrames number_of_frames: Int,
		absoluteCaptureTimestampMs absolute_capture_timestamp_ms: Int64,
		timestampIsValid timestamp_is_valid: Bool) {
		// Keep callback work minimal; mixer thread integration is implemented separately.
		callbackCount += 1
		frameCount += UInt64(number_of_frames)
		latestSampleRate = sample_rate
		latestChannels = number_of_channels

		if bits_per_sample == 16, number_of_channels > 0, number_of_frames > 0 {
			let sampleCount = number_of_frames * number_of_channels
			let samples = audio_data.assumingMemoryBound(to: Int16.self)
			var peak: Int16 = 0
			var sumSquares: Double = 0.0

			for i in 0..<sampleCount {
				let sample = samples[i]
				let magnitude = abs(Int(sample))
				if magnitude > Int(peak) {
					peak = Int16(min(magnitude, Int(Int16.max)))
				}

				let normalized = Double(sample) / Double(Int16.max)
				sumSquares += normalized * normalized
			}

			let rms = sqrt(sumSquares / Double(sampleCount))
			let peakNorm = max(Double(peak) / Double(Int16.max), 1.0e-8)
			let rmsNorm = max(rms, 1.0e-8)
			latestPeakDbfs = 20.0 * log10(peakNorm)
			latestRmsDbfs = 20.0 * log10(rmsNorm)
		}

		delegate?.onConferenceAudioFrame(
			label: label,
			bitsPerSample: bits_per_sample,
			sampleRate: sample_rate,
			numberOfChannels: number_of_channels,
			numberOfFrames: number_of_frames,
			timestampMs: absolute_capture_timestamp_ms,
			timestampIsValid: timestamp_is_valid
		)
	}

	func getStats() -> [String: Any] {
		return [
			"label": label,
			"callbackCount": callbackCount,
			"frameCount": frameCount,
			"sampleRate": latestSampleRate,
			"channels": latestChannels,
			"rmsDbfs": latestRmsDbfs,
			"peakDbfs": latestPeakDbfs
		]
	}
}
