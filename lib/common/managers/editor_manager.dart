import 'package:image_picker/image_picker.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:untitled/common/managers/logger.dart';

class EditorManager {
  static var shared = EditorManager();

  /// Apply color filter and optionally add audio using FFmpeg
  Future<XFile?> applyFilterAndAudioToVideo({
    required String inputPath,
    required int duration,
    required String? audioPath,
    required int? audioStartDuration,
    required List<double> colorChannelMixer,
    required String outputPath,
  }) async {
    bool? status = await RetrytechPlugin.shared.applyFilterAndAudioToVideo(
      inputPath: inputPath,
      audioPath: audioPath,
      audioStartTimeInMS: audioStartDuration?.roundToDouble(),
      shouldBothMusics: true,
      outputPath: outputPath,
      filterValues: colorChannelMixer,
    );
    if (status == true) {
      Loggers.success("FFMPEG WORKED: $outputPath");
      return XFile(outputPath);
    } else {
      Loggers.error("FFMPEG ERROR");
      return null;
    }
  }

  Future<void> applyFilterToImage({
    required String inputPath,
    required List<double> colorChannelMixer,
    required String outputPath,
  }) async {
    if (await RetrytechPlugin.shared.applyFilterToImage(
            filterValues: colorChannelMixer,
            inputPath: inputPath,
            outputPath: outputPath) ==
        true) {
      Loggers.success("RetryTech Plugin $outputPath");
    } else {
      Loggers.error("RetryTech Plugin ERROR");
    }
  }
}
