// Thin bridge between the Dart web build and @ffmpeg/ffmpeg (self-hosted
// under ./ffmpeg/, not loaded from a CDN — see README "Web版のffmpeg.wasm").
//
// ffmpeg.wasm already runs ffmpeg-core inside its own dedicated Worker
// (see ffmpeg/worker.js), so this module — and therefore the Dart code
// calling it — never blocks the UI thread during encoding (spec section 33).
import { FFmpeg } from './ffmpeg/ffmpeg/index.js';

let ffmpegPromise = null;
let progressCallback = null;
let logCallback = null;

function createFFmpeg() {
  const ffmpeg = new FFmpeg();
  ffmpeg.on('progress', ({ progress, time }) => {
    if (progressCallback) progressCallback(progress, time);
  });
  ffmpeg.on('log', ({ type, message }) => {
    if (logCallback) logCallback(type, message);
  });
  return ffmpeg.load({
    coreURL: new URL('./ffmpeg/core/ffmpeg-core.js', import.meta.url).toString(),
    wasmURL: new URL('./ffmpeg/core/ffmpeg-core.wasm', import.meta.url).toString(),
  }).then(() => ffmpeg);
}

function getFFmpeg() {
  if (!ffmpegPromise) ffmpegPromise = createFFmpeg();
  return ffmpegPromise;
}

window.shortMixFFmpeg = {
  load: () => getFFmpeg().then(() => true),
  setProgressCallback: (cb) => { progressCallback = cb; },
  setLogCallback: (cb) => { logCallback = cb; },
  writeFile: (name, bytes) => getFFmpeg().then((ff) => ff.writeFile(name, bytes)),
  exec: (args) => getFFmpeg().then((ff) => ff.exec(args)),
  readFile: (name) => getFFmpeg().then((ff) => ff.readFile(name)),
  deleteFile: (name) => getFFmpeg().then((ff) => ff.deleteFile(name)).catch(() => {}),
  // Ends the worker outright (used on cancel) so a stuck exec() cannot keep
  // running after the user backs out; the next call transparently starts a
  // fresh instance via getFFmpeg().
  terminate: () => {
    if (ffmpegPromise) {
      ffmpegPromise.then((ff) => ff.terminate()).catch(() => {});
      ffmpegPromise = null;
    }
  },
};
