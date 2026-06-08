/*
 *  Copyright 2026 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>
#include <stddef.h>
#include <stdint.h>

#import <WebRTC/RTCMacros.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Receives decoded PCM samples from an RTCAudioTrack.
 *
 * The audio_data pointer is only valid for the lifetime of the callback.
 * Callbacks may be delivered on a WebRTC audio thread.
 */
RTC_OBJC_EXPORT
@protocol RTC_OBJC_TYPE(RTCAudioRenderer) <NSObject>

- (void)renderPCMData:(const void *)audio_data
        bitsPerSample:(int)bits_per_sample
           sampleRate:(int)sample_rate
     numberOfChannels:(size_t)number_of_channels
       numberOfFrames:(size_t)number_of_frames
absoluteCaptureTimestampMs:(int64_t)absolute_capture_timestamp_ms
     timestampIsValid:(BOOL)timestamp_is_valid;

@end

NS_ASSUME_NONNULL_END
