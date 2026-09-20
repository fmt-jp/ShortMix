import '../../../models/project.dart';
import '../../../models/transition.dart';

/// Builds the ffmpeg `exec()` argument list for a [ShortMixProject] whose
/// clips already carry the final plan (`startTime`/`endTime`/`outputDuration`
/// from [DurationAdjuster]/[ClipSelector] — spec sections 17–24 in one pass):
/// trim each input to its window, scale+center-crop to the output aspect
/// ratio, then join with the chosen transition.
///
/// The whole project shares a single transition choice (spec section 22:
/// "適用: すべての動画間"), so this only ever needs `project.transitions.first`.
class FfmpegCommandBuilder {
  const FfmpegCommandBuilder();

  List<String> build({
    required ShortMixProject project,
    required List<String> inputFileNames,
    required String outputFileName,
  }) {
    final clips = project.clips;
    final n = clips.length;
    assert(inputFileNames.length == n);
    assert(n > 0);

    final args = <String>[];
    for (var i = 0; i < n; i++) {
      final clip = clips[i];
      args.addAll([
        '-ss', clip.startTime.toStringAsFixed(3),
        '-t', clip.outputDuration.toStringAsFixed(3),
        '-i', inputFileNames[i],
      ]);
    }

    final w = project.outputWidth;
    final h = project.outputHeight;
    final filters = <String>[];
    for (var i = 0; i < n; i++) {
      filters.add(
        '[$i:v]scale=w=$w:h=$h:force_original_aspect_ratio=increase,'
        'crop=$w:$h,setsar=1,fps=30[v$i]',
      );
      filters.add('[$i:a]aresample=48000,asetpts=PTS-STARTPTS[a$i]');
    }

    final transition = project.transitions.isNotEmpty ? project.transitions.first : const Transition();
    final isCut = n == 1 || transition.type == TransitionType.cut;

    if (n == 1) {
      filters.add('[v0]format=yuv420p[vout]');
    } else if (isCut) {
      final videoInputs = List.generate(n, (i) => '[v$i]').join();
      filters.add('${videoInputs}concat=n=$n:v=1:a=0[vconcat]');
      filters.add('[vconcat]format=yuv420p[vout]');
    } else {
      final xfadeName = _xfadeName(transition.type);
      final t = transition.duration;
      var prevLabel = 'v0';
      var cumulative = clips[0].outputDuration;
      for (var i = 1; i < n; i++) {
        final outLabel = i == n - 1 ? 'vout_raw' : 'vx$i';
        final offset = cumulative - t;
        filters.add(
          '[$prevLabel][v$i]xfade=transition=$xfadeName:'
          'duration=${t.toStringAsFixed(3)}:offset=${offset.toStringAsFixed(3)}'
          '[$outLabel]',
        );
        cumulative = cumulative + clips[i].outputDuration - t;
        prevLabel = outLabel;
      }
      filters.add('[vout_raw]format=yuv420p[vout]');
    }

    if (n == 1) {
      filters.add('[a0]anull[aout]');
    } else {
      // Audio is hard-cut at each clip boundary even when the video
      // crossfades/slides/zooms — acceptable for MVP (spec doesn't require
      // an audio crossfade), avoids the extra offset bookkeeping acrossfade
      // would need alongside the video xfade chain above.
      final audioInputs = List.generate(n, (i) => '[a$i]').join();
      filters.add('${audioInputs}concat=n=$n:v=0:a=1[aout]');
    }

    args.addAll([
      '-filter_complex', filters.join(';'),
      '-map', '[vout]',
      '-map', '[aout]',
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-crf', '28',
      '-r', '30',
      '-c:a', 'aac',
      '-ar', '48000',
      '-movflags', '+faststart',
      outputFileName,
    ]);

    return args;
  }

  String _xfadeName(TransitionType type) {
    switch (type) {
      case TransitionType.fade:
      case TransitionType.crossfade:
        return 'fade';
      case TransitionType.slide:
        return 'slideleft';
      case TransitionType.zoom:
        return 'zoomin';
      case TransitionType.cut:
        return 'fade'; // unreachable: cut short-circuits to concat above.
    }
  }
}
