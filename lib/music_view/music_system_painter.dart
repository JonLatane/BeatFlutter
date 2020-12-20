import 'dart:math';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/painting.dart';
import 'package:unification/unification.dart';

import '../drawing/color_guide.dart';
import '../drawing/harmony_beat_renderer.dart';
import '../drawing/melody/melody.dart';
import '../drawing/melody/melody_clef_renderer.dart';
import '../drawing/melody/melody_color_guide.dart';
import '../drawing/melody/melody_staff_lines_renderer.dart';
import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/midi_theory.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../util/util.dart';

class MusicSystemPainter extends CustomPainter {
  static const double extraBeatsSpaceForClefs = 2;
  static const double staffHeight = 500;

  Paint _tickPaint = Paint()..style = PaintingStyle.fill;

  final String focusedMelodyId;
  final Score score;
  final Section section;
  final ValueNotifier<double> xScaleNotifier, yScaleNotifier;
  final Rect Function() visibleRect;
  final MusicViewMode musicViewMode;
  final ValueNotifier<double> colorblockOpacityNotifier,
      colorGuideOpacityNotifier,
      notationOpacityNotifier,
      sectionScaleNotifier;
  final ValueNotifier<Iterable<int>> colorboardNotesNotifier, keyboardNotesNotifier;
  final ValueNotifier<Iterable<MusicStaff>> staves;
  final ValueNotifier<Map<String, double>> partTopOffsets, staffOffsets;
  final ValueNotifier<Color> sectionColor;
  final ValueNotifier<Part> keyboardPart, colorboardPart, focusedPart, tappedPart;
  final ValueNotifier<int> highlightedBeat, focusedBeat, tappedBeat;
  final bool isCurrentScore, isPreview, renderPartNames;
  final double firstBeatOfSection;

  double get xScale => xScaleNotifier.value;

  double get yScale => yScaleNotifier.value;

  Melody get focusedMelody =>
      score.parts.expand((p) => p.melodies).firstWhere((m) => m.id == focusedMelodyId, orElse: () => null);

  int get numberOfBeats => /*isViewingSection ? section.harmony.beatCount :*/ score.beatCount;

  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;

  double get width => standardBeatWidth * numberOfBeats;

  int get colorGuideAlpha => (255 * colorGuideOpacityNotifier.value).toInt();

  MusicSystemPainter({
    this.isPreview,
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
    this.score,
    this.section,
    this.xScaleNotifier,
    this.yScaleNotifier,
    this.visibleRect,
    this.focusedMelodyId,
    this.colorblockOpacityNotifier,
    this.notationOpacityNotifier,
    this.isCurrentScore,
    this.renderPartNames,
  }) : super(
            repaint: Listenable.merge([
          colorblockOpacityNotifier,
          notationOpacityNotifier,
          colorboardNotesNotifier,
          keyboardNotesNotifier,
          staves,
          partTopOffsets,
          staffOffsets,
          keyboardPart,
          colorboardPart,
          focusedBeat,
          tappedBeat,
          BeatScratchPlugin.pressedMidiControllerNotes,
          BeatScratchPlugin.currentBeat,
          xScaleNotifier,
          yScaleNotifier,
        ])) {
    _tickPaint.color = Colors.black;
    _tickPaint.strokeWidth = 2.0;
  }

  double get harmonyHeight => min(100, 30 * yScale);

  double get idealSectionHeight => max(22, harmonyHeight);

  double get sectionHeight => idealSectionHeight * sectionScaleNotifier.value;

  double get melodyHeight => staffHeight * yScale;

  @override
  void paint(Canvas canvas, Size size) {
    // return;
    final startTime = DateTime.now().millisecondsSinceEpoch;
    bool drawContinuousColorGuide = false; //xScale <= 1;
//    canvas.clipRect(Offset.zero & size);

    // Calculate from which beat we should start drawing
    int startBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor();

    double top, left, right, bottom;
    left = startBeat * standardBeatWidth;
//    canvas.drawRect(visibleRect(), Paint()..style=PaintingStyle.stroke..strokeWidth=10);

    staves.value.forEach((staff) {
      double staffOffset = staffOffsets.value.putIfAbsent(staff.id, () => 0);
      double top = visibleRect().top + harmonyHeight + sectionHeight + staffOffset;
      Rect staffLineBounds = Rect.fromLTRB(visibleRect().left, top, visibleRect().right, top + melodyHeight);
//      canvas.drawRect(staffLineBounds, Paint()..style=PaintingStyle.stroke..strokeWidth=10);
      _renderStaffLines(canvas, !(staff is DrumStaff) && drawContinuousColorGuide, staffLineBounds);
      Rect clefBounds =
          Rect.fromLTRB(visibleRect().left, top, visibleRect().left + 2 * standardBeatWidth, top + melodyHeight);
//      canvas.drawRect(clefBounds, Paint()..style=PaintingStyle.stroke..strokeWidth=10);

      _renderClefs(canvas, clefBounds, staff);
    });

//    left += 2 * standardBeatWidth;
    int renderingBeat = startBeat - extraBeatsSpaceForClefs.toInt(); // To make room for clefs
//    print("Drawing frame from beat=$renderingBeat. Colorblock alpha is ${colorblockOpacityNotifier.value}. Notation alpha is ${notationOpacityNotifier.value}");
//     bool keepRenderingBeats = true;
    while (left < visibleRect().right + standardBeatWidth) {
      // keepRenderingBeats &= DateTime.now().millisecondsSinceEpoch - startTime < 17;
      // if (!keepRenderingBeats) {
      //   break;
      // }
      if (renderingBeat >= 0) {
        // Figure out what beat of what section we're drawing
        int renderingSectionBeat = renderingBeat;
        Section renderingSection = this.section;
        // if (musicViewMode == MusicViewMode.score) {
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
        // }
        if (renderingSection == null) {
          break;
        }
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
          TextSpan span = TextSpan(
              text: renderingSection.name.isNotEmpty
                  ? renderingSection.name
                  : " Section ${renderingSection.id.substring(0, 5)}",
              style: TextStyle(
                  fontFamily: "VulfSans",
                  fontSize: fontSize,
                  fontWeight: FontWeight.w100,
                  color: renderingSection.name.isNotEmpty ? Colors.black : Colors.grey));
          TextPainter tp = TextPainter(
            text: span,
            strutStyle: StrutStyle(fontFamily: "VulfSans", fontWeight: FontWeight.w800),
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(canvas, new Offset(left + standardBeatWidth * 0.08, top + topOffset));
        }
        top += sectionHeight;

        Harmony renderingHarmony = renderingSection.harmony;
        right = left + standardBeatWidth;
        String sectionName = renderingSection.name;
        if (sectionName == null || sectionName.isEmpty) {
          sectionName = renderingSection.id;
        }

//      canvas.drawImageRect(filledNotehead, Rect.fromLTRB(0, 0, 24, 24),
//        Rect.fromLTRB(startOffset, top, startOffset + spacing/2, top + spacing / 2), _tickPaint);
        Rect harmonyBounds = Rect.fromLTRB(left, top, left + standardBeatWidth, top + harmonyHeight);
        _renderHarmonyBeat(harmonyBounds, renderingSection, renderingSectionBeat, canvas);
        top = top + harmonyHeight;

//      print("renderingSectionBeat=$renderingSectionBeat");

        staves.value.forEach((staff) {
          staff.getParts(score, staves.value).forEach((part) {
            double partOffset = partTopOffsets.value.putIfAbsent(part.id, () => 0);
            List<Melody> melodiesToRender = renderingSection.melodies
                .where((melodyReference) => melodyReference.playbackType != MelodyReference_PlaybackType.disabled)
                .where((ref) => part.melodies.any((melody) => melody.id == ref.melodyId))
                .map((it) => score.melodyReferencedBy(it))
                .toList();
            //        canvas.save();
            //        canvas.translate(0, partOffset);
            Rect melodyBounds = Rect.fromLTRB(left, top + partOffset, right, top + partOffset + melodyHeight);
            // if (!drawContinuousColorGuide) {
            //   _renderSubdividedColorGuide(
            //     renderingHarmony, melodyBounds, renderingSection, renderingSectionBeat, canvas);
            // }
            _renderMelodies(part, melodiesToRender, canvas, melodyBounds, renderingSection, renderingSectionBeat,
                renderingBeat, left, staff, staves.value);
            //        canvas.restore();
          });
        });
      }
      left += standardBeatWidth;
      renderingBeat += 1;
    }
//    if (drawContinuousColorGuide) {
//      this.drawContinuousColorGuide(canvas, visibleRect().top, visibleRect().bottom);
//    }
    if (visibleRect().right > left) {
      canvas.drawRect(Rect.fromLTRB(left, visibleRect().top + sectionHeight, visibleRect().right, visibleRect().bottom),
          Paint()..color = Colors.white);
      // canvas.drawRect(Rect.fromLTRB(left, visibleRect().top + sectionHeight, visibleRect().right, visibleRect().bottom),
      //   Paint()..color=Colors.black12);
    }
    final endTime = DateTime.now().millisecondsSinceEpoch;
//    print("MelodyPainter draw time from beat $startBeat, : ${endTime - startTime}ms");
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
    if (musicViewMode != MusicViewMode.score && renderingSection.id != section.id) {
      blackOpacity = 0.12;
    }
    canvas.drawRect(
        melodyBounds, Paint()..color = Colors.black.withOpacity(blackOpacity /* * colorblockOpacityNotifier.value*/));

    var renderQueue = List<Melody>.from(melodiesToRender.where((it) => it != focusedMelody));
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
          stemsUp = averageToneToStemsUp.putIfAbsent(melody.averageTone, () => true);
          break;
        case 1:
          melody = renderQueue.removeAt(renderQueue.length - 1);
          stemsUp = averageToneToStemsUp.putIfAbsent(melody.averageTone, () => false);
          break;
        case 2:
          melody = renderQueue.removeAt(renderQueue.length - 1);
          stemsUp = averageToneToStemsUp.putIfAbsent(melody.averageTone, () => true);
          break;
        default:
          melody = renderQueue.removeAt(0);
          stemsUp = averageToneToStemsUp.putIfAbsent(melody.averageTone, () => false);
      }

      _renderMelodyBeat(canvas, melody, melodyBounds, renderingSection, renderingSectionBeat, stemsUp,
          (focusedMelody == null) ? 1 : 0.2, renderQueue);
      index++;
    }

    if (focusedMelody != null) {
      final part = score.parts.firstWhere((p) => p.melodies.any((m) => m.id == focusedMelodyId));
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
        _renderMelodyBeat(
            canvas, focusedMelody, melodyBounds, renderingSection, renderingSectionBeat, true, opacity, renderQueue,
            renderLoopStarts: true);
      }
    }

    try {
      if (renderingBeat != 0) {
        _renderMeasureLines(renderingSection, renderingSectionBeat, melodyBounds, canvas);
      }
    } catch (e) {
      print("exception rendering measure lines: $e");
    }

    if (!isPreview) {
      if (isCurrentScore &&
          renderingSection == section &&
          renderingSectionBeat == BeatScratchPlugin.currentBeat.value) {
        _renderCurrentBeat(canvas, melodyBounds, renderingSection, renderingSectionBeat, renderQueue, staff);
      } else if (isCurrentScore &&
              renderingSection == section &&
              renderingSectionBeat + firstBeatOfSection == highlightedBeat.value /* && BeatScratchPlugin.playing*/
          ) {
        canvas.drawRect(
            melodyBounds,
            Paint()
              ..style = PaintingStyle.fill
              ..color = sectionColor.value.withAlpha(55));
      } else if (isCurrentScore && (renderingBeat == focusedBeat.value || renderingBeat == tappedBeat.value)) {
        canvas.drawRect(
            melodyBounds,
            Paint()
              ..style = PaintingStyle.fill
              ..color = part != null && tappedPart.value?.id == part.id ? sectionColor.value.withOpacity(0.12) : Colors.black12);
      }
      if (isCurrentScore && (renderingBeat == tappedBeat.value) && part != null && tappedPart.value?.id == part.id) {
        canvas.drawRect(
          melodyBounds,
          Paint()
            ..style = PaintingStyle.fill
            ..color = sectionColor.value.withOpacity(0.12));
      }
    }
  }

  void _renderStaffLines(Canvas canvas, bool drawContinuousColorGuide, Rect bounds) {
    if (notationOpacityNotifier.value > 0) {
      MelodyStaffLinesRenderer()
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha((255 * notationOpacityNotifier.value).toInt()))
        ..bounds = bounds
        ..draw(canvas);
    }
    if (drawContinuousColorGuide && colorGuideAlpha > 0) {
      this.drawContinuousColorGuide(canvas, bounds.top - harmonyHeight, bounds.bottom);
    }
  }

  void _renderClefs(Canvas canvas, Rect bounds, MusicStaff staff) {
    if (notationOpacityNotifier.value > 0) {
      var clefs = (staff is DrumStaff || (staff is PartStaff && staff.part.isDrum))
          ? [Clef.drum_treble, Clef.drum_bass]
          : [Clef.treble, Clef.bass];
      MelodyClefRenderer()
        ..xScale = xScale
        ..yScale = yScale
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha((255 * notationOpacityNotifier.value).toInt()))
        ..bounds = bounds
        ..clefs = clefs
        ..draw(canvas);
    }
    if (colorblockOpacityNotifier.value > 0) {
      MelodyPianoClefRenderer()
        ..xScale = xScale
        ..yScale = yScale
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha(255 * colorblockOpacityNotifier.value ~/ 3))
        ..bounds = bounds
        ..draw(canvas);
    }

    if (staff.getParts(score, staves.value).any((element) => element.id == focusedPart.value?.id)) {
      Rect highlight = Rect.fromPoints(
          bounds.topLeft.translate(-bounds.width / 13, notationOpacityNotifier.value * bounds.height / 6),
          bounds.bottomRight.translate(0, notationOpacityNotifier.value * -bounds.height / 10));
      canvas.drawRect(highlight, Paint()..color = sectionColor.value.withAlpha(127));
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

      TextSpan span = new TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: "VulfSans",
              fontSize: max(11, 20 * yScale),
              fontWeight: FontWeight.w800,
              color: colorblockOpacityNotifier.value > 0.5 ? Colors.black87 : Colors.black));
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

  void _renderCurrentBeat(Canvas canvas, Rect melodyBounds, Section renderingSection, int renderingSectionBeat,
      Iterable<Melody> otherMelodiesOnStaff, MusicStaff staff,
      {Paint backgroundPaint}) {
    canvas.drawRect(
        melodyBounds,
        backgroundPaint ?? Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black26);
    var staffParts = staff.getParts(score, staves.value);
    bool hasColorboardPart = staffParts.any((part) => part.id == colorboardPart.value?.id);
    bool hasKeyboardPart = staffParts.any((part) => part.id == keyboardPart.value?.id);
    if (hasColorboardPart || hasKeyboardPart) {
      _colorboardDummyMelody.setMidiDataFromSimpleMelody({0: colorboardNotesNotifier.value.toList()});
      _keyboardDummyMelody.setMidiDataFromSimpleMelody(
          {0: keyboardNotesNotifier.value.followedBy(BeatScratchPlugin.pressedMidiControllerNotes.value).toList()});
      // Stem will be up
      double avgColorboardNote = colorboardNotesNotifier.value.isEmpty
          ? -100
          : colorboardNotesNotifier.value.reduce((a, b) => a + b) / colorboardNotesNotifier.value.length.toDouble();
      double avgKeyboardNote = keyboardNotesNotifier.value.isEmpty
          ? -100
          : keyboardNotesNotifier.value.reduce((a, b) => a + b) / keyboardNotesNotifier.value.length.toDouble();

      _keyboardDummyMelody.instrumentType = keyboardPart?.value?.instrument?.type ?? InstrumentType.harmonic;
      if (hasColorboardPart) {
        _renderMelodyBeat(canvas, _colorboardDummyMelody, melodyBounds, renderingSection, renderingSectionBeat,
            avgColorboardNote > avgKeyboardNote, 1, otherMelodiesOnStaff);
      }
      if (hasKeyboardPart) {
        _renderMelodyBeat(canvas, _keyboardDummyMelody, melodyBounds, renderingSection, renderingSectionBeat,
            avgColorboardNote <= avgKeyboardNote, 1, otherMelodiesOnStaff);
      }
    }
  }

  void _renderMeasureLines(Section renderingSection, int renderingSectionBeat, Rect melodyBounds, Canvas canvas) {
    double opacityFactor = 1;
    if (musicViewMode != MusicViewMode.score && renderingSection.id != section.id) {
      int rsIndex = score.sections.indexWhere((s) => s.id == renderingSection.id);
      if (rsIndex > 0 && renderingSectionBeat == 0 && score.sections[rsIndex - 1].id == section.id) {
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

  void _renderSubdividedColorGuide(
      Harmony renderingHarmony, Rect melodyBounds, Section renderingSection, int renderingSectionBeat, Canvas canvas) {
    try {
      Melody colorGuideMelody = focusedMelody;
      if (colorGuideMelody == null) {
        colorGuideMelody = Melody()
          ..id = uuid.v4()
          ..subdivisionsPerBeat = renderingHarmony.subdivisionsPerBeat
          ..length = renderingHarmony.length;
      }
      //          if(colorblockOpacityNotifier.value > 0) {
      MelodyColorGuide()
        ..overallBounds = melodyBounds
        ..section = renderingSection
        ..beatPosition = renderingSectionBeat
        ..section = renderingSection
        ..drawPadding = 3
        ..nonRootPadding = 3
        ..drawnColorGuideAlpha = colorGuideAlpha
        ..isUserChoosingHarmonyChord = false
        ..isMelodyReferenceEnabled = true
        ..melody = colorGuideMelody
        ..drawColorGuide(canvas);
      //          }
    } catch (t) {
      print("failed to draw colorguide: $t");
    }
  }

  void _renderHarmonyBeat(Rect harmonyBounds, Section renderingSection, int renderingSectionBeat, Canvas canvas) {
    HarmonyBeatRenderer()
      ..overallBounds = harmonyBounds
      ..section = renderingSection
      ..beatPosition = renderingSectionBeat
      ..draw(canvas);
  }

  _renderMelodyBeat(Canvas canvas, Melody melody, Rect melodyBounds, Section renderingSection, int renderingSectionBeat,
      bool stemsUp, double alpha, Iterable<Melody> otherMelodiesOnStaff,
      {bool renderLoopStarts = false}) {
    double opacityFactor = 1;
    if (melodyBounds.left < visibleRect().left + standardBeatWidth) {
      opacityFactor = max(0, min(1, (melodyBounds.left - visibleRect().left) / standardBeatWidth));
    }
    if (musicViewMode != MusicViewMode.score && renderingSection.id != section.id) {
      opacityFactor *= 0.25;
    }
    if (melody != null) {
      if (renderLoopStarts &&
          renderingSectionBeat % (melody.length / melody.subdivisionsPerBeat) == 0 &&
          renderingSection.id == section.id) {
        Rect highlight = Rect.fromPoints(melodyBounds.topLeft.translate(-melodyBounds.width / 13, 0),
            melodyBounds.bottomLeft.translate(melodyBounds.width / 13, 0));
        canvas.drawRect(highlight, Paint()..color = sectionColor.value.withAlpha(127));
      }
      try {
        if (colorblockOpacityNotifier.value > 0) {
          ColorblockMelodyRenderer()
            ..uiScale = xScale
            ..overallBounds = melodyBounds
            ..section = renderingSection
            ..beatPosition = renderingSectionBeat
            ..colorblockAlpha = colorblockOpacityNotifier.value * alpha * opacityFactor
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
          NotationMelodyRenderer()
            ..otherMelodiesOnStaff = otherMelodiesOnStaff
            ..xScale = xScale
            ..yScale = yScale
            ..overallBounds = melodyBounds
            ..section = renderingSection
            ..beatPosition = renderingSectionBeat
            ..notationAlpha = notationOpacityNotifier.value * alpha * opacityFactor
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
  }

  drawContinuousColorGuide(Canvas canvas, double top, double bottom) {
    // Calculate from which beat we should start drawing
    int renderingBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor() - 2;

    final double startOffset = renderingBeat * standardBeatWidth;
    double left = startOffset;
    double chordLeft = left;
    Chord renderingChord;

    while (left < visibleRect().right + standardBeatWidth) {
      if (renderingBeat < 0) {
        left += standardBeatWidth;
        renderingBeat += 1;
        continue;
      }
      int renderingSectionBeat = renderingBeat;
      Section renderingSection = this.section;
      if (renderingSection == null) {
        int _beat = 0;
        Section candidate = score.sections[0];
        while (_beat + candidate.beatCount <= renderingBeat) {
          _beat += candidate.beatCount;
          renderingSectionBeat -= candidate.beatCount;
        }
        renderingSection = candidate;
      }
      Harmony renderingHarmony = renderingSection.harmony;
      double beatLeft = left;
      for (int renderingSubdivision in range(renderingSectionBeat * renderingHarmony.subdivisionsPerBeat,
          (renderingSectionBeat + 1) * renderingHarmony.subdivisionsPerBeat - 1)) {
        Chord chordAtSubdivision =
            renderingHarmony.changeBefore(renderingSubdivision) ?? cChromatic; //TODO Is this default needed?
        if (renderingChord == null) {
          renderingChord = chordAtSubdivision;
        }
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
        left += standardBeatWidth / renderingHarmony.subdivisionsPerBeat;
      }
      left = beatLeft + standardBeatWidth;
      renderingBeat += 1;
    }
    Rect renderingRect = Rect.fromLTRB(chordLeft, top + harmonyHeight, left, bottom);
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
