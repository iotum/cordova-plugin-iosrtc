/**
 * Expose the RTCRtpReceiver class.
 */
module.exports = RTCRtpReceiver;

var exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({ min: 10000, max: 99999, integer: true });

/**
 * Capabilities cache (populated at initialization time).
 */
var _capabilities = {};

function RTCRtpReceiver(pc, data) {
	data = data || {};
	this._id = data.id || randomNumber();

	this._pc = pc;
	this.track = data.track ? pc.getOrCreateTrack(data.track) : null;
	this.params = data.params || {};
}

RTCRtpReceiver.prototype.getParameters = function () {
	return this.params;
};

RTCRtpReceiver.prototype.getStats = function () {
	return this._pc.getStats();
};

RTCRtpReceiver.prototype.update = function ({ track, params }) {
	if (track) {
		this.track = this._pc.getOrCreateTrack(track);
	} else {
		this.track = null;
	}

	this.params = params;
};

RTCRtpReceiver.getCapabilities = function (kind) {
	return _capabilities[kind] || null;
};

RTCRtpReceiver._initCapabilities = function (kind) {
	exec(
		function (data) {
			_capabilities[kind] = data;
		},
		function (err) {
			console.warn('RTCRtpReceiver._initCapabilities(' + kind + ') failed:', err);
		},
		'iosrtcPlugin',
		'RTCRtpReceiver_getCapabilities',
		[kind]
	);
};
