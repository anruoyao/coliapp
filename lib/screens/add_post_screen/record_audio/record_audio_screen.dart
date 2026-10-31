import 'dart:async';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'dart:math';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';

var audioSize = Size(Get.width - 86, 50);

class RecordAudioScreen extends StatefulWidget {
  final Function(
          String path, PlayerController playerController, List<double> waves)
      onRecordDone;

  const RecordAudioScreen({super.key, required this.onRecordDone});

  @override
  State<RecordAudioScreen> createState() => _RecordAudioScreenState();
}

class _RecordAudioScreenState extends State<RecordAudioScreen> {
  final num audioLimitSec =
      ((SessionManager.shared.getSettings()?.minuteLimitInAudioPost ?? 0) * 60);
  bool isRecording = false;
  RecorderController recorderController = RecorderController();
  Duration duration = Duration();
  var progress = 0.0.obs;
  String? audioPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cWhite,
      child: SafeArea(
        child: Column(
          children: [
            Container(height: AppBar().preferredSize.height),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Spacer(),
                  Opacity(
                      opacity: audioPath == null ? 1 : 0,
                      child: XMarkButton(color: cBlack)),
                ],
              ),
            ),
            Expanded(
              child: audioPath == null ? recordingView() : recordedView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget recordingView() {
    return Column(
      children: [
        Spacer(),
        Container(
          width: Get.width,
          margin: EdgeInsets.symmetric(horizontal: 15),
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                  cornerRadius: 12, cornerSmoothing: cornerSmoothing),
              side:
                  BorderSide(color: cBlack.withValues(alpha: 0.2), width: 0.5),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: AudioWaveforms(
            size: audioSize,
            recorderController: recorderController,
            enableGesture: false,
            decoration: BoxDecoration(
              borderRadius: SmoothBorderRadius(cornerRadius: 12),
              color: cPrimary.withValues(alpha: 0),
            ),
            shouldCalculateScrolledPosition: false,
            waveStyle: WaveStyle(
              spacing: 3,
              waveThickness: 1.5,
              scaleFactor: 30,
              showDurationLabel: false,
              showBottom: true,
              showMiddleLine: true,
              middleLineThickness: 0.5,
              waveCap: StrokeCap.round,
              middleLineColor: cBlack,
              waveColor: cBlack,
              showHourInDuration: true,
              backgroundColor: cWhite,
            ),
          ),
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Obx(
            () => CustomPaint(
              foregroundPainter: MyPainter(
                lineColor: cPrimary.withValues(alpha: 0.3),
                completeColor: cPrimary,
                completePercent: progress * 100,
                width: 3.0,
              ),
              child: new Padding(
                padding: const EdgeInsets.all(5.0),
                child: GestureDetector(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: ShapeDecoration(
                            color: isRecording ? cWhite : cPrimary,
                            shape: CircleBorder()),
                      ),
                      AnimatedContainer(
                        duration: Duration(seconds: 1),
                        width: 40,
                        height: 40,
                        decoration: ShapeDecoration(
                          color: cPrimary,
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius.all(
                              SmoothRadius(
                                cornerRadius: 5,
                                cornerSmoothing: cornerSmoothing,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onLongPressStart: (details) {
                    startRecording();
                  },
                  onLongPressEnd: (details) {
                    stopRecording();
                  },
                  onLongPressCancel: () {
                    if (recorderController.isRecording) {
                      stopRecording();
                    } else {
                      startRecording();
                    }
                    // startRecording();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    _listenCurrentDuration();
    super.initState();
  }

  void _listenCurrentDuration() {
    recorderController.onCurrentDuration.listen((event) {
      duration = event;
      progress.value = duration.inMicroseconds / (audioLimitSec * 1000000);
      if (duration.inSeconds == audioLimitSec) {
        stopRecording();
      }
    });
  }

  void startRecording() async {
    recorderController.onRecorderStateChanged.listen((event) {
      if (mounted) {
        setState(() {
          isRecording = event.isRecording;
          progress.value = 0;
        });
      }
    });
    HapticManager.shared.medium();
    final hasPermission = await recorderController.checkPermission();
    if (hasPermission) {
      await recorderController.record();
    } else {
      print('RECORD PERMISSION NOT GRANTED');
    }
  }

  Future<void> pauseRecording() async {
    await recorderController.pause();
    HapticManager.shared.medium();
  }

  Future<void> stopRecording() async {
    final path = await recorderController.stop();
    audioPath = path;
    HapticManager.shared.medium();
    preparePlayer();
    print(path);
    return;
  }

  void refresh() {
    recorderController.refresh();
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  /// =================================================================
  /// =================================================================
  /// Player...
  PlayerController playerController = PlayerController();
  List<double> waves = [];
  bool isPlaying = false;

  Widget recordedView() {
    return Column(
      children: [
        Spacer(),
        AudioWavePlayerCard(playerController: playerController),
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            children: [
              Expanded(
                child: CommonSheetButton(
                  title: LKeys.retake,
                  color: cBlack.withValues(alpha: 0.2),
                  textColor: cBlack,
                  onTap: () {
                    showColibriBottomSheet(ConfirmationSheet(
                        desc: LKeys.doYouWantToRemoveThisRecording,
                        buttonTitle: LKeys.yes,
                        onTap: () {
                          playerController.release();
                          playerController.stopPlayer();
                          audioPath = null;
                          setState(() {});
                        }));
                  },
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: CommonSheetButton(
                  title: LKeys.done,
                  color: cPrimary,
                  textColor: cBlack,
                  onTap: () {
                    widget.onRecordDone(audioPath!, playerController, waves);
                    pause();
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void preparePlayer() async {
    if (!playerController.playerState.isInitialised) {
      playerController.onCurrentExtractedWaveformData.listen((event) {
        waves = event;
        if (mounted) {
          setState(() {});
        }
      });
      playerController.onPlayerStateChanged.listen((event) async {
        isPlaying = event.isPlaying;
        if (mounted) {
          setState(() {});
        }
      });
    }

    await playerController.preparePlayer(
      path: audioPath!,
      // shouldExtractWaveform: false,
      // noOfSamples: 100,
      // volume: 1.0,
    );
    await playerController.extractWaveformData(
      path: audioPath!,
      noOfSamples: playerWaveStyle.getSamplesForWidth(audioSize.width),
    );
  }

  void play() {
    playerController.startPlayer();
    playerController.setFinishMode(finishMode: FinishMode.pause);
  }

  void pause() {
    playerController.pausePlayer();
  }
}

class MyPainter extends CustomPainter {
  Color lineColor;
  Color completeColor;
  double completePercent;
  double width;

  MyPainter(
      {required this.lineColor,
      required this.completeColor,
      required this.completePercent,
      required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    Paint line = new Paint()
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    Paint complete = new Paint()
      ..color = completeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    Offset center = new Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, line);
    double arcAngle = 2 * pi * (completePercent / 100);
    canvas.drawArc(new Rect.fromCircle(center: center, radius: radius), -pi / 2,
        arcAngle, false, complete);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

final playerWaveStyle = PlayerWaveStyle(
  fixedWaveColor: cBlack.withValues(alpha: 0.2),
  liveWaveColor: cPrimary,
  spacing: 3,
  waveThickness: 1.5,
  scaleFactor: 50,
);

class WaveCard extends StatelessWidget {
  final List<double> waves;
  final Color? color;
  final bool showLoader;

  const WaveCard(
      {super.key, required this.waves, this.color, this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      margin: EdgeInsets.symmetric(horizontal: 15),
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
              cornerRadius: 12, cornerSmoothing: cornerSmoothing),
          side: BorderSide(
              color: (color ?? cBlack).withValues(alpha: 0.2), width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        showLoader
            ? SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: cPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            : Icon(
                Icons.play_arrow_rounded,
                color: (color ?? cBlack),
                size: 30,
              ),
        SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 50,
            child: Row(
                children: List.generate(waves.length, (index) {
              var height = waves[index] * 100;
              return Expanded(
                child: Container(
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(),
                    color: (color ?? cBlack).withValues(alpha: 0.2),
                  ),
                  margin: EdgeInsets.all(0.7),
                  height: max(1.5, height),
                ),
              );
            })),
          ),
        )
      ]),
    );
  }
}

class AudioWavePlayerCard extends StatefulWidget {
  final PlayerController playerController;
  final Color? color;
  final isFromLiveURL;

  const AudioWavePlayerCard(
      {super.key,
      required this.playerController,
      this.color,
      this.isFromLiveURL = false});

  @override
  State<AudioWavePlayerCard> createState() => _AudioWavePlayerCardState();
}

class _AudioWavePlayerCardState extends State<AudioWavePlayerCard> {
  PlayerController? playerController;
  var isPlaying = false;
  StreamSubscription? listener;

  @override
  void initState() {
    playerController = widget.playerController;

    setState(() {
      isPlaying = true;
    });
    listener = playerController?.onPlayerStateChanged.listen((event) {
      isPlaying = event.isPlaying;
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      margin: EdgeInsets.symmetric(horizontal: 15),
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
              cornerRadius: 12, cornerSmoothing: cornerSmoothing),
          side: BorderSide(
              color: (widget.color ?? cBlack).withValues(alpha: 0.2),
              width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        GestureDetector(
          onTap: () {
            if (isPlaying) {
              pause();
            } else {
              play();
            }
          },
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: (widget.color ?? cBlack),
            size: 30,
          ),
        ),
        SizedBox(width: 5),
        AudioFileWaveforms(
          size: audioSize,
          playerController: playerController!,
          waveformType: WaveformType.fitWidth,
          playerWaveStyle: playerWaveStyle(),
        ),
      ]),
    );
  }

  PlayerWaveStyle playerWaveStyle() {
    return PlayerWaveStyle(
        fixedWaveColor: (widget.color ?? cBlack).withValues(alpha: 0.2),
        liveWaveColor: (widget.color ?? cBlack),
        spacing: 3,
        waveThickness: 1.5,
        scaleFactor: 50);
  }

  void pause() {
    playerController?.pausePlayer();
  }

  void play() {
    playerController?.startPlayer();
    playerController?.setFinishMode(finishMode: FinishMode.pause);
  }

  @override
  void dispose() {
    listener?.cancel();
    super.dispose();
  }
}
