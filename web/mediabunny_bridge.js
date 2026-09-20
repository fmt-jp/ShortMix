// WebCodecs-backed rendering pipeline (spec Phase 3 speed follow-up), using
// mediabunny (self-hosted, see web/mediabunny/ and README) for demuxing,
// decoding, muxing and — critically — hardware-accelerated encode/decode via
// the WebCodecs API. This is what lets export approach native-app speed
// instead of ffmpeg.wasm's software-only encoding.
//
// Falls back to ffmpeg.wasm (ffmpeg_bridge.js) automatically on the Dart
// side whenever isSupported() is false or render() throws, so browsers
// without WebCodecs support (older Safari) are unaffected.
import * as Mediabunny from './mediabunny/mediabunny.min.mjs';

let progressCallback = null;
let cancelled = false;

async function isSupported() {
  if (typeof VideoEncoder === 'undefined' || typeof VideoDecoder === 'undefined') return false;
  // The API existing isn't enough — actual H.264 encode support is
  // licensing-gated per browser build (e.g. stock/open-source Chromium
  // builds lack it entirely), so check the specific codec we ship.
  try {
    return await Mediabunny.canEncodeVideo('avc', { width: 1080, height: 1920 });
  } catch {
    return false;
  }
}

async function fetchBlob(url) {
  const response = await fetch(url);
  return response.blob();
}

/** Re-timestamps an audio sample by copying its raw data into a new one — a
 * plain clone() keeps the original (source-relative) timestamp, but each
 * clip's audio needs to land at its own slot in the OUTPUT timeline. */
function shiftAudioSample(sample, offsetSeconds) {
  // Requesting the interleaved 'f32' layout explicitly (rather than
  // sample.format, which may be planar) keeps the copyTo output and the
  // reconstructed AudioSample's declared format in agreement.
  const format = 'f32';
  const size = sample.allocationSize({ format, planeIndex: 0 });
  const buffer = new ArrayBuffer(size);
  sample.copyTo(buffer, { format, planeIndex: 0 });
  return new Mediabunny.AudioSample({
    data: buffer,
    format,
    numberOfChannels: sample.numberOfChannels,
    sampleRate: sample.sampleRate,
    timestamp: sample.timestamp + offsetSeconds,
  });
}

function drawTransitionFrame(ctx, sample, progress, type, outputWidth, outputHeight) {
  ctx.save();
  switch (type) {
    case 'slide': {
      ctx.globalAlpha = 1;
      ctx.translate(outputWidth * (1 - progress), 0);
      sample.drawWithFit(ctx, { fit: 'cover' });
      break;
    }
    case 'zoom': {
      ctx.globalAlpha = progress;
      const scale = 0.7 + 0.3 * progress;
      ctx.translate(outputWidth / 2, outputHeight / 2);
      ctx.scale(scale, scale);
      ctx.translate(-outputWidth / 2, -outputHeight / 2);
      sample.drawWithFit(ctx, { fit: 'cover' });
      break;
    }
    case 'fade':
    case 'crossfade':
    default: {
      ctx.globalAlpha = progress;
      sample.drawWithFit(ctx, { fit: 'cover' });
      break;
    }
  }
  ctx.restore();
}

/**
 * @param config {{
 *   clips: Array<{url: string, startTime: number, outputDuration: number}>,
 *   transitionType: 'cut'|'fade'|'crossfade'|'slide'|'zoom',
 *   transitionDuration: number,
 *   outputWidth: number, outputHeight: number, fps: number,
 * }}
 * @returns {Promise<Uint8Array>}
 */
async function render(config) {
  cancelled = false;
  const { clips, transitionType, outputWidth, outputHeight, fps } = config;
  const t = transitionType === 'cut' ? 0 : config.transitionDuration;

  const openClips = [];
  try {
    for (const clip of clips) {
      const blob = await fetchBlob(clip.url);
      const input = new Mediabunny.Input({ source: new Mediabunny.BlobSource(blob), formats: Mediabunny.ALL_FORMATS });
      const videoTrack = await input.getPrimaryVideoTrack();
      const audioTrack = await input.getPrimaryAudioTrack();
      openClips.push({
        ...clip,
        videoSink: videoTrack ? new Mediabunny.VideoSampleSink(videoTrack) : null,
        audioSink: audioTrack ? new Mediabunny.AudioSampleSink(audioTrack) : null,
        audioTrack,
      });
    }

    // Lay clips out on the output timeline. Consecutive clips overlap by `t`
    // seconds — that overlap window is where the transition is drawn.
    let cursor = 0;
    const timeline = openClips.map((clip, i) => {
      const outStart = cursor;
      const outEnd = outStart + clip.outputDuration;
      cursor = outEnd - (i < openClips.length - 1 ? t : 0);
      return { ...clip, outStart, outEnd };
    });
    const totalDuration = timeline.length ? Math.max(...timeline.map((c) => c.outEnd)) : 0;

    const canvas = new OffscreenCanvas(outputWidth, outputHeight);
    const ctx = canvas.getContext('2d');

    const output = new Mediabunny.Output({
      format: new Mediabunny.Mp4OutputFormat({ fastStart: 'in-memory' }),
      target: new Mediabunny.BufferTarget(),
    });

    const videoSource = new Mediabunny.CanvasSource(canvas, {
      codec: 'avc',
      quality: new Mediabunny.Quality('high'),
    });
    output.addVideoTrack(videoSource);

    const hasAudio = timeline.some((c) => c.audioSink);
    const audioSource = hasAudio
      ? new Mediabunny.AudioSampleSource({ codec: 'aac', quality: new Mediabunny.Quality('high') })
      : null;
    if (audioSource) output.addAudioTrack(audioSource);

    await output.start();

    const frameDuration = 1 / fps;
    for (let time = 0; time < totalDuration; time += frameDuration) {
      if (cancelled) throw new Error('cancelled');
      ctx.clearRect(0, 0, outputWidth, outputHeight);

      const activeIdx = timeline.findIndex((c) => time >= c.outStart && time < c.outEnd);
      if (activeIdx >= 0) {
        const clip = timeline[activeIdx];
        if (clip.videoSink) {
          const srcTime = clip.startTime + (time - clip.outStart);
          const sample = await clip.videoSink.getSample(srcTime);
          if (sample) {
            ctx.save();
            ctx.globalAlpha = 1;
            sample.drawWithFit(ctx, { fit: 'cover' });
            ctx.restore();
            sample.close();
          }
        }

        if (t > 0 && activeIdx < timeline.length - 1) {
          const transitionStart = clip.outEnd - t;
          if (time >= transitionStart) {
            const progress = Math.min(1, Math.max(0, (time - transitionStart) / t));
            const nextClip = timeline[activeIdx + 1];
            if (nextClip.videoSink) {
              const nextSrcTime = nextClip.startTime + (time - nextClip.outStart);
              const nextSample = await nextClip.videoSink.getSample(nextSrcTime);
              if (nextSample) {
                drawTransitionFrame(ctx, nextSample, progress, transitionType, outputWidth, outputHeight);
                nextSample.close();
              }
            }
          }
        }
      }

      await videoSource.add(time, frameDuration);
      if (progressCallback) progressCallback(Math.min(1, time / totalDuration));
    }

    // Audio is hard-cut at clip boundaries (matches the ffmpeg.wasm path;
    // no crossfade), which keeps this independent of the video transition
    // logic above.
    if (audioSource) {
      for (const clip of timeline) {
        if (cancelled) throw new Error('cancelled');
        if (!clip.audioSink) continue;
        const rangeEnd = clip.startTime + clip.outputDuration;
        for await (const sample of clip.audioSink.samples(clip.startTime, rangeEnd)) {
          const shifted = shiftAudioSample(sample, clip.outStart - clip.startTime);
          sample.close();
          await audioSource.add(shifted);
          shifted.close();
        }
      }
    }

    await output.finalize();
    return new Uint8Array(output.target.buffer);
  } finally {
    for (const clip of openClips) {
      clip.videoSink = null;
      clip.audioSink = null;
    }
  }
}

window.shortMixMediabunny = {
  isSupported,
  setProgressCallback: (cb) => { progressCallback = cb; },
  render,
  cancel: () => { cancelled = true; },
};
