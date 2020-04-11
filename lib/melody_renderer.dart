import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:beatscratch_flutter_redux/drawing/harmony_beat_renderer.dart';
import 'package:beatscratch_flutter_redux/drawing/melody/melody.dart';
import 'package:beatscratch_flutter_redux/drawing/melody/melody_clef_renderer.dart';
import 'package:beatscratch_flutter_redux/drawing/melody/melody_color_guide.dart';
import 'package:beatscratch_flutter_redux/drawing/melody/melody_staff_lines_renderer.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unification/unification.dart';
import 'drawing/color_guide.dart';
import 'drawing/drawing.dart';
import 'melody_view.dart';
import 'section_list.dart';
import 'part_melodies_view.dart';
import 'colorboard.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'util.dart';
import 'ui_models.dart';
import 'dummydata.dart';
import 'music_theory.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

const double unscaledStandardBeatWidth = 60.0;

class MelodyRenderer extends StatefulWidget {
  final MelodyViewMode melodyViewMode;
  final Score score;
  final Section section;
  final Melody focusedMelody;
  final RenderingMode renderingMode;
  final double xScale;
  final double yScale;
  final int currentBeat;
  final ValueNotifier<Set<int>> colorboardNotesNotifier;
  final ValueNotifier<Set<int>> keyboardNotesNotifier;

  const MelodyRenderer(
      {Key key,
      this.score,
      this.section,
      this.xScale,
      this.yScale,
      this.focusedMelody,
      this.renderingMode,
      this.currentBeat,
      this.colorboardNotesNotifier,
      this.keyboardNotesNotifier, this.melodyViewMode})
      : super(key: key);

  @override
  _MelodyRendererState createState() => _MelodyRendererState();
}

Rect _visibleRect = Rect.zero;

class _MelodyRendererState extends State<MelodyRenderer> with TickerProviderStateMixin {
  bool get isViewingSection => widget.section != null;

  int get numberOfBeats => isViewingSection ? widget.section.harmony.beatCount : widget.score.beatCount;

  double get xScale => widget.xScale;
  double get yScale => widget.yScale;
  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;

  double get overallCanvasHeight => heightFactor * yScale;
  double get overallCanvasWidth => (numberOfBeats + 1) * standardBeatWidth; // + 1 for clefs

  ScrollController verticalController = ScrollController();
  static const double heightFactor = 500;

  AnimationController configurationChangeAnimationController;
  ValueNotifier<double> colorblockOpacityNotifier;
  ValueNotifier<double> notationOpacityNotifier;
  ValueNotifier<int> currentBeatNotifier;
  ValueNotifier<double> sectionScaleNotifier;

  @override
  void initState() {
    super.initState();
    configurationChangeAnimationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    colorblockOpacityNotifier = ValueNotifier(0);
    notationOpacityNotifier = ValueNotifier(0);
    currentBeatNotifier = ValueNotifier(0);
    sectionScaleNotifier = ValueNotifier(0);
  }


  @override
  void dispose() {
    colorblockOpacityNotifier.dispose();
    notationOpacityNotifier.dispose();
    currentBeatNotifier.dispose();
    sectionScaleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String key = widget.score.id;
    if (widget.section != null) {
      key = widget.section.toString();
    }
    double colorblockOpacityValue = (widget.renderingMode == RenderingMode.colorblock) ? 1 : 0;
    double notationOpacityValue = (widget.renderingMode == RenderingMode.notation) ? 1 : 0;
    double sectionScaleValue = widget.melodyViewMode == MelodyViewMode.score ? 1 : 0;
    Animation animation1;
    animation1 = Tween<double>(begin: colorblockOpacityNotifier.value, end: colorblockOpacityValue)
        .animate(configurationChangeAnimationController)
          ..addListener(() {
            colorblockOpacityNotifier.value = animation1.value;
          });
    Animation animation2;
    animation2 = Tween<double>(begin: notationOpacityNotifier.value, end: notationOpacityValue)
        .animate(configurationChangeAnimationController)
          ..addListener(() {
            notationOpacityNotifier.value = animation2.value;
          });
      Animation animation3;
      animation3 = Tween<double>(begin: sectionScaleNotifier.value, end: sectionScaleValue)
        .animate(configurationChangeAnimationController)
        ..addListener(() {
          sectionScaleNotifier.value = animation3.value;
        });
    if (currentBeatNotifier.value != widget.currentBeat) {
      currentBeatNotifier.value = widget.currentBeat;
    }
    configurationChangeAnimationController.forward(from: 0);
    return SingleChildScrollView(
        key: Key(key),
        child: Container(
            height: heightFactor * yScale,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              slivers: [
                new CustomSliverToBoxAdapter(
                  setVisibleRect: (rect) {
                    _visibleRect = rect;
                  },
                  child: CustomPaint(
//                    key: Key("$overallCanvasWidth-$overallCanvasHeight"),
                    size: Size(overallCanvasWidth, overallCanvasHeight),
                    painter: new _MelodyPainter(
                      sectionScaleNotifier: sectionScaleNotifier,
                        score: widget.score,
                        section: widget.section,
                        xScale: widget.xScale,
                        yScale: widget.yScale,
                        focusedMelody: widget.focusedMelody,
                        colorblockOpacityNotifier: colorblockOpacityNotifier,
                        notationOpacityNotifier: notationOpacityNotifier,
                        currentBeatNotifier: currentBeatNotifier,
                        colorboardNotesNotifier: widget.colorboardNotesNotifier,
                        keyboardNotesNotifier: widget.keyboardNotesNotifier,
                        visibleRect: () => _visibleRect,
                        staffReferences: [_AccompanimentReference(), _DrumTrackReference()]),
                  ),
//          child: _MelodyPaint(
//            score: widget.score,
//            section: widget.section,
//            xScale: widget.xScale,
//            yScale: widget.yScale,
//            visibleRect: () => _visibleRect,
//            width: width,
//          ),
                )
              ],
            )));
  }
}

class _StaffReference {
  final Part part;
  final bool isAccompaniment = false;
  double xPosition = 0.0;

  _StaffReference(this.part);
}

class _AccompanimentReference extends _StaffReference {
  @override
  bool isAccompaniment = true;

  _AccompanimentReference() : super(null);
}

class _DrumTrackReference extends _StaffReference {
  @override
  bool isAccompaniment = true;

  _DrumTrackReference() : super(null);
}

class _MelodyPainter extends CustomPainter {
  final Melody focusedMelody;
  final Score score;
  final Section section;
  final double xScale;
  final double yScale;
  final Rect Function() visibleRect;
  final List<_StaffReference> staffReferences;
  final ValueNotifier<double> colorblockOpacityNotifier, notationOpacityNotifier, sectionScaleNotifier;
  final ValueNotifier<int> currentBeatNotifier;
  final ValueNotifier<Set<int>> colorboardNotesNotifier;
  final ValueNotifier<Set<int>> keyboardNotesNotifier;

  bool get isViewingSection => section != null;

  int get numberOfBeats => isViewingSection ? section.harmony.beatCount : score.beatCount;

  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;

  double get width => standardBeatWidth * numberOfBeats;
  Paint _tickPaint = Paint()..style = PaintingStyle.fill;

  int get colorGuideAlpha => (255 * colorblockOpacityNotifier.value).toInt();

  _MelodyPainter({this.sectionScaleNotifier,
      this.colorboardNotesNotifier,
      this.keyboardNotesNotifier,
      this.currentBeatNotifier,
      this.score,
      this.section,
      this.xScale,
      this.yScale,
      this.visibleRect,
      this.staffReferences,
      this.focusedMelody,
      this.colorblockOpacityNotifier,
      this.notationOpacityNotifier})
      : super(
            repaint: Listenable.merge([
          colorblockOpacityNotifier,
          notationOpacityNotifier,
          currentBeatNotifier,
          colorboardNotesNotifier,
          keyboardNotesNotifier
        ])) {
    _tickPaint.color = Colors.black;
    _tickPaint.strokeWidth = 2.0;
  }

  double get harmonyHeight => min(100, 30 * yScale);
  double get idealSectionHeight => harmonyHeight;
  double get sectionHeight => idealSectionHeight * sectionScaleNotifier.value;

  @override
  void paint(Canvas canvas, Size size) {
    bool drawContinuousColorGuide = xScale <= 1;
    canvas.clipRect(Offset.zero & size);

    // Calculate from which beat we should start drawing
    int renderingBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor();

    double top, left, right, bottom;
    left = renderingBeat * standardBeatWidth;
//    canvas.drawRect(visibleRect(), Paint()..style=PaintingStyle.stroke..strokeWidth=10);

    Rect staffLineBounds = Rect.fromLTRB(
      visibleRect().left, visibleRect().top + harmonyHeight + sectionHeight, visibleRect().right, visibleRect().bottom);
    _renderStaffLines(canvas, drawContinuousColorGuide, staffLineBounds);
    Rect clefBounds = Rect.fromLTRB(
      visibleRect().left, visibleRect().top + harmonyHeight + sectionHeight, visibleRect().left + standardBeatWidth, visibleRect().bottom);

    _renderClefs(canvas, drawContinuousColorGuide, staffLineBounds);

    renderingBeat -= 1; // To make room for clefs
//    print("Drawing frame from beat=$renderingBeat. Colorblock alpha is ${colorblockOpacityNotifier.value}. Notation alpha is ${notationOpacityNotifier.value}");
    while (left < visibleRect().right + standardBeatWidth) {
      if (renderingBeat < 0) {
        left += standardBeatWidth;
        renderingBeat += 1;
        continue;
      }

      // Figure out what beat of what section we're drawing
      int renderingSectionBeat = renderingBeat;
      Section renderingSection = this.section;
      if (renderingSection == null) {
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
      }
      if (renderingSection == null) {
        break;
      }

      // Draw the Section name if needed
      top = visibleRect().top;
      if(renderingSectionBeat == 0) {
        double fontSize = sectionHeight * 0.6;
        double topOffset = max(0, 30/pow(fontSize, 0.7 + 0.2 * fontSize/20));
//        print("fontSize=$fontSize topOffset=$topOffset");
        TextSpan span = new TextSpan(text: renderingSection.name.isNotEmpty
          ? renderingSection.name
          : " Section ${renderingSection.id.substring(0, 5)}",
          style: TextStyle(fontFamily: "VulfSans", fontSize: fontSize, fontWeight: FontWeight.w100,
            color: renderingSection.name.isNotEmpty ? Colors.black : Colors.grey));
        TextPainter tp = new TextPainter(text: span,
          strutStyle: StrutStyle(fontFamily: "VulfSans", fontWeight: FontWeight.w800),
          textAlign: TextAlign.left, textDirection: TextDirection.ltr,);
        tp.layout();
        tp.paint(canvas, new Offset(left + standardBeatWidth * 0.08, top - topOffset));
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

      Rect melodyBounds = Rect.fromLTRB(left, top, right, visibleRect().bottom);
      if (!drawContinuousColorGuide) {
        _renderSubdividedColorGuide(renderingHarmony, melodyBounds, renderingSection, renderingSectionBeat, canvas);
      }

      List<Melody> melodiesToRender = renderingSection.melodies
        .where((melodyReference) => melodyReference.playbackType != MelodyReference_PlaybackType.disabled)
        .where((it) => it != focusedMelody)
        .map((it) => score.melodyReferencedBy(it))
        .toList();
      if(focusedMelody == null) {
        melodiesToRender.sort((a,b) => -a.averageTone.compareTo(b.averageTone));
      }
      var melodyToRenderSelectionAndPlaybackWith = (focusedMelody == null)
        ? melodiesToRender.maxBy((it) => it.subdivisionsPerBeat)
        : null;

      var renderQueue = List<Melody>.from(melodiesToRender);
      int index = 0;
      while(renderQueue.isNotEmpty) {
        // Draw highest Melody stems up, lowest stems down, second lowest stems up, second highest
        // down. And repeat.
        Melody melody;
        bool stemsUp;
        switch(index % 4) {
          case 0:
            melody = renderQueue.removeAt(0);
            stemsUp = true;
            break;
          case 1:
            melody = renderQueue.removeAt(renderQueue.length - 1);
            stemsUp = false;
            break;
          case 2:
            melody = renderQueue.removeAt(renderQueue.length - 1);
            stemsUp = true;
            break;
          default:
          melody = renderQueue.removeAt(0);
          stemsUp = false;
        }

        _renderMelodyBeat(canvas, melody, melodyBounds, renderingSection, renderingSectionBeat,
          stemsUp, (focusedMelody == null) ? 1 : 0.66);
        index++;
      }

      if(focusedMelody != null) {
        _renderMelodyBeat(canvas, focusedMelody, melodyBounds, renderingSection, renderingSectionBeat, true, 1);
      }

      try {
        if (notationOpacityNotifier.value > 0 && renderingBeat != 0) {
          _renderNotationMeasureLines(renderingSection, renderingSectionBeat, melodyBounds, canvas);
        }
      } catch (e) {
        print("exception rendering measure lines: $e");
      }

      if (renderingBeat == currentBeatNotifier.value) {
        _renderCurrentBeat(canvas, melodyBounds, renderingSection, renderingSectionBeat);
      }

      left += standardBeatWidth;
      renderingBeat += 1;
    }
//    if (drawContinuousColorGuide) {
//      this.drawContinuousColorGuide(canvas, visibleRect().top, visibleRect().bottom);
//    }
  }

  void _renderStaffLines(Canvas canvas, bool drawContinuousColorGuide, Rect bounds) {
    if (notationOpacityNotifier.value > 0) {
      MelodyStaffLinesRenderer()
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha((255 * notationOpacityNotifier.value).toInt()))
        ..bounds = bounds
        ..draw(canvas);
    }
    if (drawContinuousColorGuide && colorGuideAlpha > 0) {
      this.drawContinuousColorGuide(canvas, visibleRect().top + sectionHeight, visibleRect().bottom);
    }
  }
  void _renderClefs(Canvas canvas, bool drawContinuousColorGuide, Rect bounds) {
    if (notationOpacityNotifier.value > 0) {
      MelodyClefRenderer()
      ..xScale = xScale
        ..yScale = yScale
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha((255 * notationOpacityNotifier.value).toInt()))
        ..bounds = bounds
        ..draw(canvas);
    }
  }

  Melody _colorboardDummyMelody = defaultMelody()..subdivisionsPerBeat=1..length=1;
  Melody _keyboardDummyMelody = defaultMelody()..subdivisionsPerBeat=1..length=1;
  void _renderCurrentBeat(Canvas canvas, Rect melodyBounds, Section renderingSection, int renderingSectionBeat) {
    canvas.drawRect(
        melodyBounds,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black26);
    _colorboardDummyMelody.melodicData.data[0] = MelodicAttack()..tones.addAll(colorboardNotesNotifier.value);
    _keyboardDummyMelody.melodicData.data[0] = MelodicAttack()..tones.addAll(keyboardNotesNotifier.value);

    // Stem will be up
    double avgColorboardNote = colorboardNotesNotifier.value.isEmpty ? -100
      : colorboardNotesNotifier.value.reduce((a,b) => a+b)/colorboardNotesNotifier.value.length.toDouble();
    double avgKeyboardNote = keyboardNotesNotifier.value.isEmpty ? -100
      : keyboardNotesNotifier.value.reduce((a,b) => a+b)/keyboardNotesNotifier.value.length.toDouble();

    _renderMelodyBeat(canvas, _colorboardDummyMelody, melodyBounds, renderingSection, renderingSectionBeat, avgColorboardNote > avgKeyboardNote, 1);
    _renderMelodyBeat(canvas, _keyboardDummyMelody, melodyBounds, renderingSection, renderingSectionBeat, avgColorboardNote <= avgKeyboardNote, 1);

  }

  void _renderNotationMeasureLines(Section renderingSection, int renderingSectionBeat, Rect melodyBounds, Canvas canvas) {
    MelodyMeasureLinesRenderer()
      ..section = renderingSection
      ..beatPosition = renderingSectionBeat
      ..notationAlpha = notationOpacityNotifier.value
      ..overallBounds = melodyBounds
      ..draw(canvas, 1);
  }

  void _renderSubdividedColorGuide(Harmony renderingHarmony, Rect melodyBounds, Section renderingSection, int renderingSectionBeat, Canvas canvas) {
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

  _renderMelodyBeat(
      Canvas canvas, Melody melody, Rect melodyBounds, Section renderingSection, int renderingSectionBeat, bool stemsUp, double alpha) {
    double opacityFactor = 1;
    if(melodyBounds.left < visibleRect().left + standardBeatWidth) {
      opacityFactor = max(0, min(1,
        (melodyBounds.left - visibleRect().left) / standardBeatWidth
      ));
    }
    if (melody != null) {
      try {
        if (colorblockOpacityNotifier.value > 0) {
          ColorblockMelodyRenderer()
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
      } catch (e) {
        print("exception rendering colorblock: $e");
      }
      try {
        if (notationOpacityNotifier.value > 0) {
          NotationMelodyRenderer()
            ..xScale = xScale
            ..yScale = yScale
            ..overallBounds = melodyBounds
            ..section = renderingSection
            ..beatPosition = renderingSectionBeat
            ..section = renderingSection
            ..notationAlpha = notationOpacityNotifier.value * alpha * opacityFactor
            ..drawPadding = 3
            ..nonRootPadding = 3
            ..stemsUp = stemsUp
            ..isUserChoosingHarmonyChord = false
            ..isMelodyReferenceEnabled = true
            ..melody = melody
            ..draw(canvas, true);
        }
      } catch (e) {
        print("exception rendering notation: $e");
      }
    }
  }

  drawContinuousColorGuide(Canvas canvas, double top, double bottom) {
    // Calculate from which beat we should start drawing
    int renderingBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor();

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
  bool shouldRepaint(_MelodyPainter oldDelegate) {
    return false;
  }
}
