import Foundation

class ConferenceMixSession: NSObject, ConferenceAudioRendererDelegate {
	static let engineMode = "renderer_tap_only"

	let conferenceId: String
	let remoteTrackIdA: String
	let remoteTrackIdB: String
	let micTrackId: String

	let pcIdA: Int
	let pcIdB: Int
	let senderIdA: Int
	let senderIdB: Int

	let originalTrackIdForA: String
	let originalTrackIdForB: String

	let mixedTrackIdForA: String
	let mixedTrackIdForB: String

	private let remoteAudioTrackA: RTCAudioTrack
	private let remoteAudioTrackB: RTCAudioTrack
	private let rendererA: ConferenceAudioRenderer
	private let rendererB: ConferenceAudioRenderer

	private(set) var active: Bool = false
	private var gains: [String: Double]
	private var mute: [String: Bool]
	private var limiterEnabled: Bool
	private var limiterThresholdDb: Double
	private var lastInputFrameInfo: [String: [String: Any]] = [:]

	init(conferenceId: String,
		remoteTrackIdA: String,
		remoteTrackIdB: String,
		micTrackId: String,
		pcIdA: Int,
		pcIdB: Int,
		senderIdA: Int,
		senderIdB: Int,
		originalTrackIdForA: String,
		originalTrackIdForB: String,
		remoteAudioTrackA: RTCAudioTrack,
		remoteAudioTrackB: RTCAudioTrack,
		gains: [String: Double],
		limiterEnabled: Bool,
		limiterThresholdDb: Double) {
		self.conferenceId = conferenceId
		self.remoteTrackIdA = remoteTrackIdA
		self.remoteTrackIdB = remoteTrackIdB
		self.micTrackId = micTrackId
		self.pcIdA = pcIdA
		self.pcIdB = pcIdB
		self.senderIdA = senderIdA
		self.senderIdB = senderIdB
		self.originalTrackIdForA = originalTrackIdForA
		self.originalTrackIdForB = originalTrackIdForB
		self.remoteAudioTrackA = remoteAudioTrackA
		self.remoteAudioTrackB = remoteAudioTrackB
		self.gains = gains
		self.mute = [
			"mic": false,
			"remoteA": false,
			"remoteB": false
		]
		self.limiterEnabled = limiterEnabled
		self.limiterThresholdDb = limiterThresholdDb

		// Track ids for mixed tracks are generated now. Actual mixer-backed tracks are wired in the next phase.
		self.mixedTrackIdForA = "mix-A-\(UUID().uuidString)"
		self.mixedTrackIdForB = "mix-B-\(UUID().uuidString)"

		self.rendererA = ConferenceAudioRenderer(label: "remoteA", delegate: nil)
		self.rendererB = ConferenceAudioRenderer(label: "remoteB", delegate: nil)

		super.init()

		self.rendererA.delegate = self
		self.rendererB.delegate = self
	}

	func start() {
		if active {
			return
		}

		remoteAudioTrackA.add(rendererA)
		remoteAudioTrackB.add(rendererB)
		active = true
	}

	func update(gainsPatch: [String: Double]?, mutePatch: [String: Bool]?, limiterPatch: [String: Any]?) {
		if let gainsPatch = gainsPatch {
			for (k, v) in gainsPatch {
				gains[k] = v
			}
		}

		if let mutePatch = mutePatch {
			for (k, v) in mutePatch {
				mute[k] = v
			}
		}

		if let limiterPatch = limiterPatch {
			if let enabled = limiterPatch["enabled"] as? Bool {
				limiterEnabled = enabled
			}
			if let thresholdDb = limiterPatch["thresholdDb"] as? Double {
				limiterThresholdDb = thresholdDb
			}
		}
	}

	func stop() {
		if !active {
			return
		}

		remoteAudioTrackA.remove(rendererA)
		remoteAudioTrackB.remove(rendererB)
		active = false
	}

	func getStartPayload() -> [String: Any] {
		return [
			"conferenceId": conferenceId,
			"engineMode": ConferenceMixSession.engineMode,
			"mixedTrackIdForA": mixedTrackIdForA,
			"mixedTrackIdForB": mixedTrackIdForB,
			"originalTrackIdForA": originalTrackIdForA,
			"originalTrackIdForB": originalTrackIdForB,
			"sampleRate": 48000,
			"frameSize": 480
		]
	}

	func getStatePayload() -> [String: Any] {
		return [
			"conferenceId": conferenceId,
			"engineMode": ConferenceMixSession.engineMode,
			"active": active,
			"remoteTrackIdA": remoteTrackIdA,
			"remoteTrackIdB": remoteTrackIdB,
			"senderIdA": senderIdA,
			"senderIdB": senderIdB,
			"mixedTrackIdForA": mixedTrackIdForA,
			"mixedTrackIdForB": mixedTrackIdForB
		]
	}

	func getStatsPayload() -> [String: Any] {
		return [
			"conferenceId": conferenceId,
			"engineMode": ConferenceMixSession.engineMode,
			"active": active,
			"gains": gains,
			"mute": mute,
			"limiter": [
				"enabled": limiterEnabled,
				"thresholdDb": limiterThresholdDb
			],
			"inputs": [
				rendererA.getStats(),
				rendererB.getStats()
			],
			"lastInputFrameInfo": lastInputFrameInfo
		]
	}

	func onConferenceAudioFrame(label: String,
		bitsPerSample: Int,
		sampleRate: Int,
		numberOfChannels: Int,
		numberOfFrames: Int,
		timestampMs: Int64,
		timestampIsValid: Bool) {
		lastInputFrameInfo[label] = [
			"bitsPerSample": bitsPerSample,
			"sampleRate": sampleRate,
			"numberOfChannels": numberOfChannels,
			"numberOfFrames": numberOfFrames,
			"timestampMs": timestampMs,
			"timestampIsValid": timestampIsValid,
			"monotonicTimeMs": Int64(Date().timeIntervalSince1970 * 1000.0)
		]

		// Mixer DSP and output-track injection are introduced in the next phase.
	}
}
