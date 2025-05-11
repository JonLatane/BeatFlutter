import 'dart:math';

import 'package:beatscratch_flutter_redux/widget/my_platform.dart';
import 'package:flutter/material.dart';

import '../util/util.dart';
import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../drawing/color_guide.dart';
import '../drawing/harmony_beat_renderer.dart';
import '../drawing/music/music.dart';
import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/midi_theory.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';

// Top level for rendering of music to a Canvas.
class MusicSystemPainter extends CustomPainter {
  Paint _tickPaint = Paint()..style = PaintingStyle.fill;

  final String focusedMelodyId;
  final Score score;
  final Section section;
  final TransformationController transformationController;
  final bool rescale;
  final Rect Function() visibleRect;
  final Rect Function() verticallyVisibleRect;
  final MusicViewMode musicViewMode;
  final ValueNotifier<double> colorblockOpacityNotifier,
      colorGuideOpacityNotifier,
      notationOpacityNotifier,
      sectionScaleNotifier;
  final ValueNotifier<Iterable<int>> colorboardNotesNotifier,
      keyboardNotesNotifier;
  final ValueNotifier<Map<String, List<int>>> bluetoothControllerPressedNotes;
  final ValueNotifier<Iterable<MusicStaff>> staves;
  final ValueNotifier<Map<String, double>> partTopOffsets, staffOffsets;
  final ValueNotifier<Color> sectionColor;
  final ValueNotifier<Part> keyboardPart,
      colorboardPart,
      focusedPart,
      tappedPart;
  final ValueNotifier<int> highlightedBeat, focusedBeat, tappedBeat;
  final bool isCurrentScore, isPreview, renderPartNames;
  final double firstBeatOfSection;
  final int systemsToRender;

  double get xScale => 1;
  double get yScale => 1;
  double get scale => transformationController.value.getMaxScaleOnAxis();

  Melody get focusedMelody => score.parts
      .expand((p) => p.melodies)
      .firstWhere((m) => m.id == focusedMelodyId, orElse: () => null);

  int get numberOfBeats => /*isViewingSection ? section.harmony.beatCount :*/
      score.beatCount;

  double get standardClefWidth => clefWidth;

  int get colorGuideAlpha => (255 * colorGuideOpacityNotifier.value).toInt();

  MusicSystemPainter(
      {this.isPreview,
      this.focusedBeat,
      this.tappedBeat,
      this.firstBeatOfSection,
      this.highlightedBeat,
      this.musicViewMode,
      this.colorGuideOpacityNotifier,
      this.sectionColor,
      this.focusedPart,
      this.tappedPart,
      this.keyboardPart,
      this.colorboardPart,
      this.staves,
      this.partTopOffsets,
      this.staffOffsets,
      this.sectionScaleNotifier,
      this.colorboardNotesNotifier,
      this.keyboardNotesNotifier,
      this.bluetoothControllerPressedNotes,
      this.score,
      this.section,
      this.transformationController,
      this.rescale = false,
      this.visibleRect,
      this.verticallyVisibleRect,
      this.focusedMelodyId,
      this.colorblockOpacityNotifier,
      this.notationOpacityNotifier,
      this.isCurrentScore,
      this.renderPartNames,
      this.systemsToRender = 1,
      List<Listenable> otherListenables = null})
      : super(
            repaint: Listenable.merge([
          colorblockOpacityNotifier,
          notationOpacityNotifier,
          colorboardNotesNotifier,
          keyboardNotesNotifier,
          bluetoothControllerPressedNotes,
          staves,
          partTopOffsets,
          staffOffsets,
          keyboardPart,
          colorboardPart,
          focusedBeat,
          tappedBeat,
          BeatScratchPlugin.pressedMidiControllerNotes,
          BeatScratchPlugin.currentBeat,
          transformationController,
          ...otherListenables
        ])) {
    _tickPaint.color = musicForegroundColor;
    _tickPaint.strokeWidth = 2.0;
  }

  static double calculateHarmonyHeight(double scale) => 10 / scale;
  static double calculateSectionHeight(double scale) =>
      calculateHarmonyHeight(scale);
  static double calculateSystemHeight(double scale, int partCount) =>
      calculateSectionHeight(scale) +
      calculateHarmonyHeight(scale) +
      (staffHeight * partCount) +
      systemPadding;

  double get harmonyHeight => calculateHarmonyHeight(scale);
  double get idealSectionHeight => 2 * harmonyHeight; //max(22, harmonyHeight);
  double get sectionHeight => idealSectionHeight * sectionScaleNotifier.value;

  double get melodyHeight => staffHeight * yScale;

  double translationTotal = 0;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = this.scale;
    if (rescale) {
      canvas.scale(scale);
    }
    translationTotal = -verticallyVisibleRect().top;
    canvas.translate(0, translationTotal);
    double translationIncrement =
        calculateSystemHeight(scale, score.parts.length);
    // print(
    //     "verticallyVisibleRect=${verticallyVisibleRect()}, translationIncrement=$translationIncrement");
    final int firstSystem =
        (verticallyVisibleRect().top / translationIncrement).floor();
    translationTotal += firstSystem * translationIncrement;
    canvas.translate(0, firstSystem * translationIncrement);
    for (int i = firstSystem; i < systemsToRender + 20; i++) {
      // print("Drawing system $i at $translationTotal");
      paintSystem(canvas, size,
          offsetStart: (visibleRect().width - clefWidth) * (i));
      translationTotal += translationIncrement;
      if (translationTotal * scale - translationIncrement >
          visibleRect().bottom) {
        break;
      }
      canvas.translate(0, translationIncrement);
    }
    canvas.restore();
    if (MyPlatform.isDebug)
      canvas.drawRect(
          verticallyVisibleRect(),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..color = musicForegroundColor.withAlpha(255));
  }

  bool isInBounds(Rect renderingRect) {
    bool inVerticalBounds = renderingRect.top + translationTotal <
            verticallyVisibleRect().bottom &&
        renderingRect.bottom + translationTotal > verticallyVisibleRect().top;
    return inVerticalBounds;
  }

  void paintSystem(Canvas canvas, Size size, {double offsetStart = 0}) {
    // return;
    // final startTime = DateTime.now().millisecondsSinceEpoch;
    bool drawContinuousColorGuide = false; //xScale <= 1;
//    canvas.clipRect(Offset.zero & size);

    // Calculate from which beat we should start drawing
    int startBeat =
        ((visibleRect().left + offsetStart - beatWidth) / beatWidth).floor();

    double top, left, right, bottom;
    left = startBeat * beatWidth - offsetStart;
//    canvas.drawRect(visibleRect(), Paint()..style=PaintingStyle.stroke..strokeWidth=10);

    staves.value.forEach((staff) {
      double staffOffset = staffOffsets.value.putIfAbsent(staff.id, () => 0);
      double top =
          visibleRect().top + harmonyHeight + sectionHeight + staffOffset;
      Rect staffLineBounds = Rect.fromLTRB(
          max(-offsetStart, visibleRect().left),
          top,
          max(-offsetStart, visibleRect().right),
          top + melodyHeight);
//      canvas.drawRect(staffLineBounds, Paint()..style=PaintingStyle.stroke..strokeWidth=10);
      _renderStaffLines(canvas,
          !(staff is DrumStaff) && drawContinuousColorGuide, staffLineBounds);
      Rect clefBounds = Rect.fromLTRB(
          max(-offsetStart, visibleRect().left),
          top,
          max(-offsetStart, visibleRect().left) + standardClefWidth,
          top + melodyHeight);
//      canvas.drawRect(clefBounds, Paint()..style=PaintingStyle.stroke..strokeWidth=10);

      _renderClefs(canvas, clefBounds, staff);
    });

    int renderingBeat =
        startBeat - extraBeatsSpaceForClefs.toInt(); // To make room for clefs
//    print("Drawing frame from beat=$renderingBeat. Colorblock alpha is ${colorblockOpacityNotifier.value}. Notation alpha is ${notationOpacityNotifier.value}");
    while (left < visibleRect().right + beatWidth) {
      if (renderingBeat >= 0) {
        // Figure out what beat of what section we're drawing
        int renderingSectionBeat = renderingBeat;
        Section renderingSection = this.section;
        int _beat = 0;
        int sectionIndex = 0;
        Section candidate = score.sections[sectionIndex];
        while (_beat + candidate.beatCount <= renderingBeat) {
          _beat += candidate.beatCount;
          renderingSectionBeat -= candidate.beatCount;
          sectionIndex += 1;
          if (sectionIndex < score.sections.length) {
            candidate = score.sections[sectionIndex];
          } else {
            candidate = null;
            break;
          }
        }
        renderingSection = candidate;
        if (renderingSectionBeat >= renderingSection.beatCount) {
          //TODO do this better...
          break;
        }

        // Draw the Section name if needed
        top = visibleRect().top;
        if (renderingSectionBeat == 0 && sectionHeight > 0) {
          //TODO Why does frame rate drop?
          double fontSize = sectionHeight * 0.6;
          double topOffset = sectionHeight * 0.05;
          if (fontSize <= 12) {
            topOffset -= 45 / fontSize;
            topOffset = max(-13, topOffset);
          }
//        print("fontSize=$fontSize topOffset=$topOffset");
          double opacityFactor =
              magicOpacityFactor(Rect.fromLTRB(left, 0, left, 0));
          TextSpan span = TextSpan(
              text: renderingSection.canonicalName,
              style: TextStyle(
                  fontFamily: "VulfSans",
                  fontSize: fontSize,
                  fontWeight: FontWeight.w100,
                  color: musicForegroundColor.withOpacity(opacityFactor *
                      (renderingSection.name.isNotEmpty ? 1 : 0.5))));
          TextPainter tp = TextPainter(
            text: span,
            strutStyle:
                StrutStyle(fontFamily: "VulfSans", fontWeight: FontWeight.w800),
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(
              canvas, new Offset(left + beatWidth * 0.08, top + topOffset));
        }
        top += sectionHeight;

        right = left + beatWidth;
        String sectionName = renderingSection.name;
        if (sectionName.isEmpty) {
          sectionName = renderingSection.id;
        }

        Rect harmonyBounds =
            Rect.fromLTRB(left, top, left + beatWidth, top + harmonyHeight);
        if (isInBounds(harmonyBounds)) {
          _renderHarmonyBeat(
              harmonyBounds, renderingSection, renderingSectionBeat, canvas);
        }
        top = top + harmonyHeight;

        staves.value.forEach((staff) async => doRenderMelodies(
            staff,
            renderingSection,
            canvas,
            left,
            right,
            top,
            renderingSectionBeat,
            renderingBeat));
      }
      left += beatWidth;
      renderingBeat += 1;
    }

    if (visibleRect().right > left) {
      double extraWidth = 0;
      double diff = left - visibleRect().left - beatWidth;
      if (offsetStart > 0 && diff < standardClefWidth + beatWidth) {
        extraWidth =
            standardClefWidth * max(0, (standardClefWidth - diff)) / beatWidth;
      }

      canvas.drawRect(
          Rect.fromLTRB(
              left - extraWidth,
              translationTotal +
                  visibleRect().top -
                  translationTotal +
                  sectionHeight,
              visibleRect().right,
              visibleRect().bottom - translationTotal),
          Paint()..color = musicBackgroundColor);
    }
  }

  doRenderMelodies(staff, renderingSection, canvas, left, right, top,
      renderingSectionBeat, renderingBeat) {
    staff.getParts(score, staves.value).forEach((part) {
      double partOffset = partTopOffsets.value.putIfAbsent(part.id, () => 0);
      List<Melody> melodiesToRender = renderingSection.melodies
          .where((melodyReference) =>
              melodyReference.playbackType !=
              MelodyReference_PlaybackType.disabled)
          .where((MelodyReference ref) =>
              part.melodies.any((melody) => melody.id == ref.melodyId) as bool)
          .map<Melody>((it) => score.melodyReferencedBy(it))
          .toList(growable: false);

      Rect melodyBounds = Rect.fromLTRB(
          left, top + partOffset, right, top + partOffset + melodyHeight);
      if (isInBounds(melodyBounds)) {
        _renderMelodies(
            part,
            melodiesToRender,
            canvas,
            melodyBounds,
            renderingSection,
            renderingSectionBeat,
            renderingBeat,
            left,
            staff,
            staves.value);
      }
      //        canvas.restore();
    });
  }

  _renderMelodies(
      Part part,
      List<Melody> melodiesToRender,
      Canvas canvas,
      Rect melodyBounds,
      Section renderingSection,
      int renderingSectionBeat,
      int renderingBeat,
      double left,
      MusicStaff staff,
      Iterable<MusicStaff> staffConfiguration) {
    double blackOpacity = 0;
    if (musicViewMode != MusicViewMode.score &&
        renderingSection.id != section.id) {
      blackOpacity = 0.12;
    }
    canvas.drawRect(
        melodyBounds,
        Paint()
          ..color = Colors.black.withOpacity(
              blackOpacity /* * colorblockOpacityNotifier.value*/));

    var renderQueue =
        List<Melody>.from(melodiesToRender.where((it) => it != focusedMelody));
    renderQueue.sort((a, b) => -a.averageTone.compareTo(b.averageTone));
    renderQueue.removeWhere((element) => element.midiData.data.keys.isEmpty);
    int index = 0;
    Map<double, bool> averageToneToStemsUp = Map();
    while (renderQueue.isNotEmpty) {
      // Draw highest Melody stems up, lowest stems down, second lowest stems up, second highest
      // down. And repeat.
      Melody melody;
      bool stemsUp;
      switch ((index + 4) % 4) {
        case 0:
          melody = renderQueue.removeAt(0);
          stemsUp =
              averageToneToStemsUp.putIfAbsent(melody.averageTone, () => true);
          break;
        case 1:
          melody = renderQueue.removeAt(renderQueue.length - 1);
          stemsUp =
              averageToneToStemsUp.putIfAbsent(melody.averageTone, () => false);
          break;
        case 2:
          melody = renderQueue.removeAt(renderQueue.length - 1);
          stemsUp =
              averageToneToStemsUp.putIfAbsent(melody.averageTone, () => true);
          break;
        default:
          melody = renderQueue.removeAt(0);
          stemsUp =
              averageToneToStemsUp.putIfAbsent(melody.averageTone, () => false);
      }

      _renderMelodyBeat(
          canvas,
          melody,
          melodyBounds,
          renderingSection,
          renderingSectionBeat,
          stemsUp,
          (focusedMelody == null) ? 1 : 0.2,
          renderQueue);
      index++;
    }

    final part = score.parts
        .firstWhere((p) => p.melodies.any((m) => m.id == focusedMelodyId));
    final parts = staff.getParts(score, staffConfiguration);
    if (parts.any((p) => p.id == part.id)) {
      double opacity = 1;
      if (!melodiesToRender.contains(focusedMelody)) {
        if (renderingSection.id == section.id) {
          opacity = 0.6;
        } else {
          opacity = 0;
        }
      }
      _renderMelodyBeat(canvas, focusedMelody, melodyBounds, renderingSection,
          renderingSectionBeat, true, opacity, renderQueue,
          renderLoopStarts: true);
    }

    try {
      if (renderingBeat != 0) {
        _renderMeasureLines(
            renderingSection, renderingSectionBeat, melodyBounds, canvas);
      }
    } catch (e) {
      print("exception rendering measure lines: $e");
    }

    if (!isPreview) {
      if (isCurrentScore &&
          renderingSection == section &&
          renderingSectionBeat == BeatScratchPlugin.currentBeat.value) {
        _renderCurrentBeat(canvas, melodyBounds, renderingSection,
            renderingSectionBeat, renderQueue, staff);
      } else if (isCurrentScore &&
              renderingSection == section &&
              renderingSectionBeat + firstBeatOfSection ==
                  highlightedBeat.value /* && BeatScratchPlugin.playing*/
          ) {
        canvas.drawRect(
            melodyBounds,
            Paint()
              ..style = PaintingStyle.fill
              ..color = sectionColor.value.withAlpha(55));
      } else if (isCurrentScore &&
          (renderingBeat == focusedBeat.value ||
              renderingBeat == tappedBeat.value)) {
        canvas.drawRect(
            melodyBounds,
            Paint()
              ..style = PaintingStyle.fill
              ..color = tappedPart.value.id == part.id &&
                      renderingBeat == tappedBeat.value
                  ? sectionColor.value.withOpacity(0.12)
                  : Colors.black12);
      }
      if (isCurrentScore &&
          (renderingBeat == tappedBeat.value) &&
          tappedPart.value.id == part.id) {
        canvas.drawRect(
            melodyBounds,
            Paint()
              ..style = PaintingStyle.fill
              ..color = sectionColor.value.withOpacity(0.12));
      }
    }
  }

  void _renderStaffLines(
      Canvas canvas, bool drawContinuousColorGuide, Rect bounds) {
    double alphaModifier = max(0.0,
        min(1.0, (visibleRect().right - bounds.left - clefWidth) / beatWidth));
    if (notationOpacityNotifier.value > 0) {
      MelodyStaffLinesRenderer()
        ..alphaDrawerPaint = (Paint()
          ..strokeWidth = 1 / sqrt(scale)
          ..color = musicForegroundColor.withAlpha(
              (255 * alphaModifier * notationOpacityNotifier.value).toInt()))
        ..bounds = bounds
        ..draw(canvas);
    }
    if (drawContinuousColorGuide && colorGuideAlpha > 0) {
      this.drawContinuousColorGuide(
          canvas, bounds.top - harmonyHeight, bounds.bottom);
    }
  }

  void _renderClefs(Canvas canvas, Rect bounds, MusicStaff staff) {
    double alphaModifier = max(0.0,
        min(1.0, (visibleRect().right - bounds.left - clefWidth) / beatWidth));
    if (notationOpacityNotifier.value > 0) {
      var clefs =
          (staff is DrumStaff || (staff is PartStaff && staff.part.isDrum))
              ? [Clef.drum_treble, Clef.drum_bass]
              : [Clef.treble, Clef.bass];
      MelodyClefRenderer()
        ..xScale = xScale
        ..yScale = yScale
        ..alphaDrawerPaint = (Paint()
          ..color = musicForegroundColor.withAlpha(
              (255 * notationOpacityNotifier.value * alphaModifier).toInt()))
        ..bounds = bounds
        ..clefs = clefs
        ..draw(canvas);
    }
    if (colorblockOpacityNotifier.value > 0) {
      MelodyPianoClefRenderer()
        ..xScale = xScale
        ..yScale = yScale
        ..alphaDrawerPaint = (Paint()
          ..color = musicForegroundColor.withAlpha(
              255 * alphaModifier * colorblockOpacityNotifier.value ~/ 3))
        ..bounds = bounds
        ..draw(canvas);
    }

    if (staff
        .getParts(score, staves.value)
        .any((element) => element.id == focusedPart.value.id)) {
      Rect highlight = Rect.fromPoints(
          bounds.topLeft.translate(-bounds.width / 13,
              notationOpacityNotifier.value * bounds.height / 6),
          bounds.bottomRight.translate(
              0, notationOpacityNotifier.value * -bounds.height / 10));
      canvas.drawRect(
          highlight,
          Paint()
            ..color =
                sectionColor.value.withAlpha((127 * alphaModifier).toInt()));
    }

    if (renderPartNames) {
      String text;
      if (staff is PartStaff) {
        text = staff.part.midiName;
      } else if (staff is AccompanimentStaff) {
        text = "Accompaniment";
      } else {
        text = "Drums";
      }

      double textOpacity = colorblockOpacityNotifier.value > 0.5 ? 0.8 : 1;
      TextSpan span = new TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: "VulfSans",
              fontSize: max(11, 10 / scale),
              fontWeight: FontWeight.w800,
              color: musicForegroundColor
                  .withOpacity(alphaModifier * textOpacity)));
      TextPainter tp = new TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, bounds.topLeft.translate(5 * xScale, 7 * yScale));
    }
  }

  Melody _colorboardDummyMelody = defaultMelody()
    ..id = "colorboardDummy"
    ..subdivisionsPerBeat = 1
    ..length = 1;
  Melody _keyboardDummyMelody = defaultMelody()
    ..id = "keyboardDummy"
    ..subdivisionsPerBeat = 1
    ..length = 1;

  void _renderCurrentBeat(
      Canvas canvas,
      Rect melodyBounds,
      Section renderingSection,
      int renderingSectionBeat,
      Iterable<Melody> otherMelodiesOnStaff,
      MusicStaff staff,
      {Paint backgroundPaint}) {
    canvas.drawRect(
        melodyBounds,
        backgroundPaint ?? Paint()
          ..style = PaintingStyle.fill
          ..color = musicForegroundColor.withOpacity(0.26));
    var staffParts = staff.getParts(score, staves.value);
    bool hasColorboardPart =
        staffParts.any((part) => part.id == colorboardPart.value.id);
    bool hasKeyboardPart =
        staffParts.any((part) => part.id == keyboardPart.value.id);
    if (hasColorboardPart || hasKeyboardPart) {
      _colorboardDummyMelody.setMidiDataFromSimpleMelody(
          {0: colorboardNotesNotifier.value.toList()});
      final keyboardNotes = keyboardNotesNotifier.value
          .followedBy(BeatScratchPlugin.pressedMidiControllerNotes.value)
          .followedBy(
              bluetoothControllerPressedNotes.value.values.expand((v) => v))
          .toSet();
      _keyboardDummyMelody.setMidiDataFromSimpleMelody({0: keyboardNotes});
      // Stem will be up
      double avgColorboardNote = colorboardNotesNotifier.value.isEmpty
          ? -100
          : colorboardNotesNotifier.value.reduce((a, b) => a + b) /
              colorboardNotesNotifier.value.length.toDouble();
      double avgKeyboardNote = keyboardNotes.isEmpty
          ? -100
          : keyboardNotes.reduce((a, b) => a + b) /
              keyboardNotes.length.toDouble();

      _keyboardDummyMelody.instrumentType =
          keyboardPart.value.instrument.type ?? InstrumentType.harmonic;
      if (hasColorboardPart) {
        _renderMelodyBeat(
            canvas,
            _colorboardDummyMelody,
            melodyBounds,
            renderingSection,
            renderingSectionBeat,
            avgColorboardNote > avgKeyboardNote,
            1,
            otherMelodiesOnStaff);
      }
      if (hasKeyboardPart) {
        _renderMelodyBeat(
            canvas,
            _keyboardDummyMelody,
            melodyBounds,
            renderingSection,
            renderingSectionBeat,
            avgColorboardNote <= avgKeyboardNote,
            1,
            otherMelodiesOnStaff);
      }
    }
  }

  double magicOpacityFactor(Rect melodyBounds) {
    double opacityFactor = 1;
    if (melodyBounds.left < visibleRect().left + (2 * beatWidth)) {
      double left = melodyBounds.left - visibleRect().left;
      opacityFactor = max(0, min(1, (left) / (2 * beatWidth)));
    }
    return opacityFactor * opacityFactor;
  }

  void _renderMeasureLines(Section renderingSection, int renderingSectionBeat,
      Rect melodyBounds, Canvas canvas) {
    double opacityFactor = magicOpacityFactor(melodyBounds);

    if (musicViewMode != MusicViewMode.score &&
        renderingSection.id != section.id) {
      int rsIndex =
          score.sections.indexWhere((s) => s.id == renderingSection.id);
      if (rsIndex > 0 &&
          renderingSectionBeat == 0 &&
          score.sections[rsIndex - 1].id == section.id) {
      } else
        opacityFactor *= 0.33;
    }
    MelodyMeasureLinesRenderer()
      ..section = renderingSection
      ..beatPosition = renderingSectionBeat
      ..notationAlpha = notationOpacityNotifier.value * opacityFactor
      ..colorblockAlpha = colorblockOpacityNotifier.value * opacityFactor
      ..overallBounds = melodyBounds
      ..draw(canvas, 1);
  }

  // void _renderSubdividedColorGuide(Harmony renderingHarmony, Rect melodyBounds,
  //     Section renderingSection, int renderingSectionBeat, Canvas canvas) {
  //   try {
  //     Melody colorGuideMelody = focusedMelody;
  //     if (colorGuideMelody == null) {
  //       colorGuideMelody = Melody()
  //         ..id = uuid.v4()
  //         ..subdivisionsPerBeat = renderingHarmony.subdivisionsPerBeat
  //         ..length = renderingHarmony.length;
  //     }
  //     //          if(colorblockOpacityNotifier.value > 0) {
  //     MelodyColorGuide()
  //       ..overallBounds = melodyBounds
  //       ..section = renderingSection
  //       ..beatPosition = renderingSectionBeat
  //       ..section = renderingSection
  //       ..drawPadding = 3
  //       ..nonRootPadding = 3
  //       ..drawnColorGuideAlpha = colorGuideAlpha
  //       ..isUserChoosingHarmonyChord = false
  //       ..isMelodyReferenceEnabled = true
  //       ..melody = colorGuideMelody
  //       ..drawColorGuide(canvas);
  //     //          }
  //   } catch (t) {
  //     print("failed to draw colorguide: $t");
  //   }
  // }

  void _renderHarmonyBeat(Rect harmonyBounds, Section renderingSection,
      int renderingSectionBeat, Canvas canvas) {
    double opacityFactor = magicOpacityFactor(harmonyBounds);
    HarmonyBeatRenderer()
      ..overallBounds = harmonyBounds
      ..section = renderingSection
      ..beatPosition = renderingSectionBeat
      ..opacityFactor = opacityFactor
      ..draw(canvas);
  }

  _renderMelodyBeat(
      Canvas canvas,
      Melody melody,
      Rect melodyBounds,
      Section renderingSection,
      int renderingSectionBeat,
      bool stemsUp,
      double alpha,
      Iterable<Melody> otherMelodiesOnStaff,
      {bool renderLoopStarts = false}) {
    double opacityFactor = magicOpacityFactor(melodyBounds);
    if (musicViewMode != MusicViewMode.score &&
        renderingSection.id != section.id) {
      opacityFactor *= 0.25;
    }
    if (renderLoopStarts &&
        renderingSectionBeat % (melody.length / melody.subdivisionsPerBeat) ==
            0 &&
        renderingSection.id == section.id) {
      Rect highlight = Rect.fromPoints(
          melodyBounds.topLeft.translate(-melodyBounds.width / 13, 0),
          melodyBounds.bottomLeft.translate(melodyBounds.width / 13, 0));
      canvas.drawRect(
          highlight, Paint()..color = sectionColor.value.withAlpha(127));
    }
    try {
      if (colorblockOpacityNotifier.value > 0) {
        ColorblockMusicRenderer()
          ..uiScale = scale
          ..overallBounds = melodyBounds
          ..section = renderingSection
          ..beatPosition = renderingSectionBeat
          ..colorblockAlpha =
              colorblockOpacityNotifier.value * alpha * opacityFactor
          ..drawPadding = 3
          ..nonRootPadding = 3
          ..isUserChoosingHarmonyChord = false
          ..isMelodyReferenceEnabled = true
          ..melody = melody
          ..draw(canvas);
      }
    } catch (e, s) {
      print("exception rendering colorblock: $e: \n$s");
    }
    try {
      if (notationOpacityNotifier.value > 0) {
        NotationMusicRenderer()
          ..otherMelodiesOnStaff = otherMelodiesOnStaff
          ..xScale = xScale
          ..yScale = yScale
          ..overallBounds = melodyBounds
          ..section = renderingSection
          ..beatPosition = renderingSectionBeat
          ..notationAlpha =
              notationOpacityNotifier.value * alpha * opacityFactor
          ..drawPadding = 3
          ..nonRootPadding = 3
          ..stemsUp = stemsUp
          ..isUserChoosingHarmonyChord = false
          ..isMelodyReferenceEnabled = true
          ..melody = melody
          ..draw(canvas);
      }
    } catch (e, s) {
      print("exception rendering notation: $e: \n$s");
    }
  }

  drawContinuousColorGuide(Canvas canvas, double top, double bottom) {
    // Calculate from which beat we should start drawing
    int renderingBeat =
        ((visibleRect().left - beatWidth) / beatWidth).floor() - 2;

    final double startOffset = renderingBeat * beatWidth;
    double left = startOffset;
    double chordLeft = left;
    Chord renderingChord;

    while (left < visibleRect().right + beatWidth) {
      if (renderingBeat < 0) {
        left += beatWidth;
        renderingBeat += 1;
        continue;
      }
      int renderingSectionBeat = renderingBeat;
      Section renderingSection = this.section;
      Harmony renderingHarmony = renderingSection.harmony;
      double beatLeft = left;
      for (int renderingSubdivision in range(
          renderingSectionBeat * renderingHarmony.subdivisionsPerBeat,
          (renderingSectionBeat + 1) * renderingHarmony.subdivisionsPerBeat -
              1)) {
        Chord chordAtSubdivision =
            renderingHarmony.changeBefore(renderingSubdivision) ?? cChromatic;
        if (renderingChord != chordAtSubdivision) {
          Rect renderingRect = Rect.fromLTRB(chordLeft, top, left, bottom);
          try {
            ColorGuide()
              ..renderVertically = true
              ..alphaDrawerPaint = Paint()
              ..halfStepsOnScreen = 88
              ..normalizedDevicePitch = 0
              ..bounds = renderingRect
              ..chord = renderingChord
              ..drawPadding = 0
              ..nonRootPadding = 0
              ..drawnColorGuideAlpha = colorGuideAlpha
              ..drawColorGuide(canvas);
          } catch (t) {
            print("failed to draw colorguide: $t");
          }
          chordLeft = left;
        }
        renderingChord = chordAtSubdivision;
        left += beatWidth / renderingHarmony.subdivisionsPerBeat;
      }
      left = beatLeft + beatWidth;
      renderingBeat += 1;
    }
    Rect renderingRect =
        Rect.fromLTRB(chordLeft, top + harmonyHeight, left, bottom);
    try {
      ColorGuide()
        ..renderVertically = true
        ..alphaDrawerPaint = Paint()
        ..halfStepsOnScreen = 88
        ..normalizedDevicePitch = 0
        ..bounds = renderingRect
        ..chord = renderingChord
        ..drawPadding = 0
        ..nonRootPadding = 0
        ..drawnColorGuideAlpha = colorGuideAlpha
        ..drawColorGuide(canvas);
    } catch (t) {
      print("failed to draw colorguide: $t");
    }
  }

  @override
  bool shouldRepaint(MusicSystemPainter oldDelegate) {
    return false;
  }
}

Matrix4 inverse(Matrix4 transform) => Matrix4.copy(transform)..invert();
Offset inverseTransformPoint(Matrix4 transform, Offset point) {
  if (MatrixUtils.isIdentity(transform)) return point;
  return MatrixUtils.transformPoint(inverse(transform), point);
}
