import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:unification/unification.dart';
import 'package:collection/collection.dart';


import 'drawing/color_guide.dart';
import 'drawing/harmony_beat_renderer.dart';
import 'drawing/melody/melody.dart';
import 'drawing/melody/melody_clef_renderer.dart';
import 'drawing/melody/melody_color_guide.dart';
import 'drawing/melody/melody_staff_lines_renderer.dart';
import 'dummydata.dart';
import 'generated/protos/music.pb.dart';
import 'music_notation_theory.dart';
import 'music_theory.dart';
import 'ui_models.dart';
import 'util.dart';
import 'dart:math';

class MelodyRenderer extends StatefulWidget {
  final MelodyViewMode melodyViewMode;
  final Score score;
  final Section section;
  final Melody focusedMelody;
  final RenderingMode renderingMode;
  final double xScale;
  final double yScale;
  final int currentBeat;
  final ValueNotifier<Iterable<int>> colorboardNotesNotifier;
  final ValueNotifier<Iterable<int>> keyboardNotesNotifier;
  final List<MusicStaff> staves;
  final Part keyboardPart;
  final Part colorboardPart;

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
      this.keyboardNotesNotifier,
      this.melodyViewMode,
      this.staves, this.keyboardPart, this.colorboardPart})
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

  double get canvasHeightMagic => 1.3 - 0.3 * (widget.staves.length) / 5;
  double get overallCanvasHeight => (widget.staves.length * staffHeight * yScale * canvasHeightMagic) + 60;

  double get overallCanvasWidth => (numberOfBeats + 2) * standardBeatWidth; // + 1 for clefs

  ScrollController verticalController = ScrollController();
  static const double staffHeight = 500;

  AnimationController animationController;
  ValueNotifier<double> colorblockOpacityNotifier;
  ValueNotifier<double> notationOpacityNotifier;
  ValueNotifier<int> currentBeatNotifier;
  ValueNotifier<double> sectionScaleNotifier;

  // partTopOffsets are animated based off the Renderer's StaffConfigurations
  ValueNotifier<List<MusicStaff>> stavesNotifier;
  ValueNotifier<Map<String, double>> partTopOffsets;
  ValueNotifier<Map<String,double>> staffOffsets;

  ValueNotifier<Part> keyboardPart;
  ValueNotifier<Part> colorboardPart;
  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    colorblockOpacityNotifier = ValueNotifier(0);
    notationOpacityNotifier = ValueNotifier(0);
    currentBeatNotifier = ValueNotifier(0);
    sectionScaleNotifier = ValueNotifier(0);
    partTopOffsets = ValueNotifier(Map());
    staffOffsets = ValueNotifier(Map());
    stavesNotifier = ValueNotifier(widget.staves);
    keyboardPart = ValueNotifier(widget.keyboardPart);
    colorboardPart = ValueNotifier(widget.colorboardPart);
  }

  @override
  void dispose() {
    animationController.dispose();
    colorblockOpacityNotifier.dispose();
    notationOpacityNotifier.dispose();
    currentBeatNotifier.dispose();
    sectionScaleNotifier.dispose();
    partTopOffsets.dispose();
    staffOffsets.dispose();
    stavesNotifier.dispose();
    keyboardPart.dispose();
    colorboardPart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String key = widget.score.id;
    if (widget.section != null) {
      key = widget.section.toString();
    }
    _animateOpacitiesAndScale();
    _animateStaffAndPartPositions();
    if (currentBeatNotifier.value != widget.currentBeat) {
      currentBeatNotifier.value = widget.currentBeat;
    }
    animationController.forward(from: 0);
    return SingleChildScrollView(
//        key: Key(key),
        child: Container(
            height: overallCanvasHeight,
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
                    painter: new MusicSystemPainter(
                        sectionScaleNotifier: sectionScaleNotifier,
                        score: widget.score,
                        section: widget.section,
                        xScale: widget.xScale,
                        yScale: widget.yScale,
                        focusedMelody: widget.focusedMelody,
                        staves: stavesNotifier,
                        partTopOffsets: partTopOffsets,
                        staffOffsets: staffOffsets,
                        colorblockOpacityNotifier: colorblockOpacityNotifier,
                        notationOpacityNotifier: notationOpacityNotifier,
                        currentBeatNotifier: currentBeatNotifier,
                        colorboardNotesNotifier: widget.colorboardNotesNotifier,
                        keyboardNotesNotifier: widget.keyboardNotesNotifier,
                        visibleRect: () => _visibleRect,
                        keyboardPart: keyboardPart,
                        colorboardPart: colorboardPart,
                    ),
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
  
  void _animateStaffAndPartPositions() {
    var removedOffsets = staffOffsets.value.keys.where((id) => !widget.staves.any((staff) => staff.id == id));
    removedOffsets.forEach((removedStaffId) {
      Animation staffAnimation;
      staffAnimation = Tween<double>(begin: staffOffsets.value[removedStaffId], end: 0)
        .animate(animationController)
        ..addListener(() {
          staffOffsets.value[removedStaffId] = staffAnimation.value;
          staffOffsets.notifyListeners();
        });
    });
    widget.staves.asMap().forEach((staffIndex, staff) { 
      double staffPosition = staffIndex * staffHeight * yScale;
      double initialStaffPosition = staffOffsets.value.putIfAbsent(staff.id, () => 0);
      Animation staffAnimation;
      staffAnimation = Tween<double>(begin: initialStaffPosition, end: staffPosition)
        .animate(animationController)
        ..addListener(() {
          staffOffsets.value[staff.id] = staffAnimation.value;
          staffOffsets.notifyListeners();
        });
      staff.getParts(widget.score, widget.staves).forEach((part) {
        double partPosition = staffPosition;
        double initialPartPosition = partTopOffsets.value.putIfAbsent(part.id, () => 0);
        Animation partAnimation;
        partAnimation = Tween<double>(begin: initialPartPosition, end: partPosition)
          .animate(animationController)
          ..addListener(() {
            partTopOffsets.value[part.id] = partAnimation.value;
            partTopOffsets.notifyListeners();
          });
        
      });
      stavesNotifier.value = widget.staves;
      colorboardPart.value = widget.colorboardPart;
      keyboardPart.value = widget.keyboardPart;
    });
  }

  void _animateOpacitiesAndScale() {
    double colorblockOpacityValue = (widget.renderingMode == RenderingMode.colorblock) ? 1 : 0;
    double notationOpacityValue = (widget.renderingMode == RenderingMode.notation) ? 1 : 0;
    double sectionScaleValue = widget.melodyViewMode == MelodyViewMode.score ? 1 : 0;
    Animation animation1;
    animation1 = Tween<double>(begin: colorblockOpacityNotifier.value, end: colorblockOpacityValue)
        .animate(animationController)
          ..addListener(() {
            colorblockOpacityNotifier.value = animation1.value;
          });
    Animation animation2;
    animation2 = Tween<double>(begin: notationOpacityNotifier.value, end: notationOpacityValue)
        .animate(animationController)
          ..addListener(() {
            notationOpacityNotifier.value = animation2.value;
          });
    Animation animation3;
    animation3 = Tween<double>(begin: sectionScaleNotifier.value, end: sectionScaleValue)
        .animate(animationController)
          ..addListener(() {
            sectionScaleNotifier.value = animation3.value;
          });
  }
}


class MusicSystemPainter extends CustomPainter {
  final Melody focusedMelody;
  final Score score;
  final Section section;
  final double xScale;
  final double yScale;
  final Rect Function() visibleRect;
  final ValueNotifier<double> colorblockOpacityNotifier, notationOpacityNotifier, sectionScaleNotifier;
  final ValueNotifier<int> currentBeatNotifier;
  final ValueNotifier<Iterable<int>> colorboardNotesNotifier;
  final ValueNotifier<Iterable<int>> keyboardNotesNotifier;
  final ValueNotifier<Iterable<MusicStaff>> staves;
  final ValueNotifier<Map<String, double>> partTopOffsets;
  final ValueNotifier<Map<String, double>> staffOffsets;
  final ValueNotifier<Part> keyboardPart;
  final ValueNotifier<Part> colorboardPart;

  bool get isViewingSection => section != null;

  int get numberOfBeats => isViewingSection ? section.harmony.beatCount : score.beatCount;

  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;

  double get width => standardBeatWidth * numberOfBeats;
  Paint _tickPaint = Paint()..style = PaintingStyle.fill;

  int get colorGuideAlpha => (255 * colorblockOpacityNotifier.value).toInt();

  MusicSystemPainter({this.keyboardPart, this.colorboardPart, this.staves, this.partTopOffsets, this.staffOffsets,
    this.sectionScaleNotifier,
    this.colorboardNotesNotifier,
    this.keyboardNotesNotifier,
    this.currentBeatNotifier,
    this.score,
    this.section,
    this.xScale,
    this.yScale,
    this.visibleRect,
    this.focusedMelody,
    this.colorblockOpacityNotifier,
    this.notationOpacityNotifier})
    : super(
    repaint: Listenable.merge([
      colorblockOpacityNotifier, notationOpacityNotifier, currentBeatNotifier, colorboardNotesNotifier,
      keyboardNotesNotifier, staves,partTopOffsets,staffOffsets,keyboardPart,colorboardPart, 
      BeatScratchPlugin.pressedMidiControllerNotes
    ])) {
    _tickPaint.color = Colors.black;
    _tickPaint.strokeWidth = 2.0;
  }

  double get harmonyHeight => min(100, 30 * yScale);

  double get idealSectionHeight => harmonyHeight;

  double get sectionHeight => idealSectionHeight * sectionScaleNotifier.value;

  double get melodyHeight => _MelodyRendererState.staffHeight * yScale;

  @override
  void paint(Canvas canvas, Size size) {
    bool drawContinuousColorGuide = xScale <= 1;
//    canvas.clipRect(Offset.zero & size);

    // Calculate from which beat we should start drawing
    int renderingBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor();

    double top, left, right, bottom;
    left = renderingBeat * standardBeatWidth;
//    canvas.drawRect(visibleRect(), Paint()..style=PaintingStyle.stroke..strokeWidth=10);

    staves.value.forEach((staff) {
      double staffOffset = staffOffsets.value.putIfAbsent(staff.id, ()=>0);
      double top = visibleRect().top + harmonyHeight + sectionHeight + staffOffset;
      Rect staffLineBounds = Rect.fromLTRB(visibleRect().left, top, visibleRect().right, top + melodyHeight);
//      canvas.drawRect(staffLineBounds, Paint()..style=PaintingStyle.stroke..strokeWidth=10);
      _renderStaffLines(canvas, drawContinuousColorGuide, staffLineBounds);
      Rect clefBounds = Rect.fromLTRB(visibleRect().left, top,
        visibleRect().left + 2*standardBeatWidth, top + melodyHeight);
//      canvas.drawRect(clefBounds, Paint()..style=PaintingStyle.stroke..strokeWidth=10);

      _renderClefs(canvas, clefBounds, staff);
    });

//    left += 2 * standardBeatWidth;
    renderingBeat -= 2; // To make room for clefs
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
      if(renderingSectionBeat >= renderingSection.beatCount) { //TODO do this better...
        break;
      }

      // Draw the Section name if needed
      top = visibleRect().top;
      if (renderingSectionBeat == 0) {
        double fontSize = sectionHeight * 0.6;
        double topOffset = sectionHeight * 0.05;
        if(fontSize <= 12) {
          topOffset -= 45/fontSize;
          topOffset = max(-13, topOffset);
        }
//        print("fontSize=$fontSize topOffset=$topOffset");
        TextSpan span = new TextSpan(
          text: renderingSection.name.isNotEmpty
            ? renderingSection.name
            : " Section ${renderingSection.id.substring(0, 5)}",
          style: TextStyle(
            fontFamily: "VulfSans",
            fontSize: fontSize,
            fontWeight: FontWeight.w100,
            color: renderingSection.name.isNotEmpty ? Colors.black : Colors.grey));
        TextPainter tp = new TextPainter(
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
          double partOffset = partTopOffsets.value.putIfAbsent(part.id, ()=>0);
          List<Melody> melodiesToRender = renderingSection.melodies
              .where((melodyReference) => melodyReference.playbackType != MelodyReference_PlaybackType.disabled)
              .where((ref) => part.melodies.any((melody) => melody.id == ref.melodyId))
              .map((it) => score.melodyReferencedBy(it))
              .toList();
  //        canvas.save();
  //        canvas.translate(0, partOffset);
          Rect melodyBounds = Rect.fromLTRB(left, top + partOffset, right, top + partOffset + melodyHeight);
          if (!drawContinuousColorGuide) {
            _renderSubdividedColorGuide(renderingHarmony, melodyBounds, renderingSection, renderingSectionBeat, canvas);
          }
          _renderMelodies(melodiesToRender, canvas, melodyBounds, renderingSection, renderingSectionBeat, renderingBeat, left, staff);
  //        canvas.restore();
        });
      });
      left += standardBeatWidth;
      renderingBeat += 1;
    }
//    if (drawContinuousColorGuide) {
//      this.drawContinuousColorGuide(canvas, visibleRect().top, visibleRect().bottom);
//    }
  }

  void _renderMelodies(List<Melody> melodiesToRender, Canvas canvas, Rect melodyBounds, Section renderingSection,
    int renderingSectionBeat, int renderingBeat, double left, MusicStaff staff) {
    var renderQueue = List<Melody>.from(melodiesToRender.where((it) => it != focusedMelody));
    renderQueue.sort((a, b) => -a.averageTone.compareTo(b.averageTone));
    int index = 0;
    while (renderQueue.isNotEmpty) {
      // Draw highest Melody stems up, lowest stems down, second lowest stems up, second highest
      // down. And repeat.
      Melody melody;
      bool stemsUp;
      switch (index % 4) {
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

      _renderMelodyBeat(canvas, melody, melodyBounds, renderingSection, renderingSectionBeat, stemsUp,
        (focusedMelody == null) ? 1 : 0.66, renderQueue);
      index++;
    }

    if (focusedMelody != null && melodiesToRender.contains(focusedMelody)) {
      _renderMelodyBeat(
        canvas, focusedMelody, melodyBounds, renderingSection, renderingSectionBeat, true, 1, renderQueue);
    }

    try {
      if (notationOpacityNotifier.value > 0 && renderingBeat != 0) {
        _renderNotationMeasureLines(renderingSection, renderingSectionBeat, melodyBounds, canvas);
      }
    } catch (e) {
      print("exception rendering measure lines: $e");
    }

    if (renderingBeat == currentBeatNotifier.value) {
      _renderCurrentBeat(canvas, melodyBounds, renderingSection, renderingSectionBeat, renderQueue, staff);
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
        ? [ Clef.drum_treble, Clef.drum_bass ]
        : [ Clef.treble, Clef.bass ];
    MelodyClefRenderer()
        ..xScale = xScale
        ..yScale = yScale
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha((255 * notationOpacityNotifier.value).toInt()))
        ..bounds = bounds
        ..clefs = clefs
        ..draw(canvas);

    }

    String text;
    if(staff is PartStaff) {
      text = staff.part.midiName;
    } else if(staff is AccompanimentStaff) {
      text = "Accompaniment";
    } else {
      text = "Drums";
    }
    TextSpan span = new TextSpan(text: text,
      style: TextStyle(
        fontFamily: "VulfSans",
        fontSize: 20 * yScale,
        fontWeight: FontWeight.w800,
        color: colorblockOpacityNotifier.value > 0.5 ? Colors.white : Colors.black));
    TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr,);
    tp.layout();
    tp.paint(canvas, bounds.topLeft.translate(5 * xScale, 50 * yScale));
  }

  Melody _colorboardDummyMelody = defaultMelody()
    ..subdivisionsPerBeat = 1
    ..length = 1;
  Melody _keyboardDummyMelody = defaultMelody()
    ..subdivisionsPerBeat = 1
    ..length = 1;

  void _renderCurrentBeat(Canvas canvas, Rect melodyBounds, Section renderingSection, int renderingSectionBeat,
    Iterable<Melody> otherMelodiesOnStaff, MusicStaff staff) {
    canvas.drawRect(
      melodyBounds,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black26);
    var staffParts = staff.getParts(score, staves.value);
    bool hasColorboardPart = staffParts.any((part) => part.id == colorboardPart.value.id);
    bool hasKeyboardPart = staffParts.any((part) => part.id == keyboardPart.value.id);
    if (hasColorboardPart || hasKeyboardPart) {
      _colorboardDummyMelody.melodicData.data[0] = MelodicAttack()
        ..tones.addAll(colorboardNotesNotifier.value);
      _keyboardDummyMelody.melodicData.data[0] = MelodicAttack()
        ..tones
          .addAll(keyboardNotesNotifier.value.followedBy(BeatScratchPlugin.pressedMidiControllerNotes.value));

      // Stem will be up
      double avgColorboardNote = colorboardNotesNotifier.value.isEmpty
        ? -100
        : colorboardNotesNotifier.value.reduce((a, b) => a + b) / colorboardNotesNotifier.value.length.toDouble();
      double avgKeyboardNote = keyboardNotesNotifier.value.isEmpty
        ? -100
        : keyboardNotesNotifier.value.reduce((a, b) => a + b) / keyboardNotesNotifier.value.length.toDouble();

      _keyboardDummyMelody.instrumentType = keyboardPart?.value?.instrument?.type ?? InstrumentType.harmonic;
      if(hasColorboardPart) {
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
      if(hasKeyboardPart) {
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

  void _renderNotationMeasureLines(
    Section renderingSection, int renderingSectionBeat, Rect melodyBounds, Canvas canvas) {
    MelodyMeasureLinesRenderer()
      ..section = renderingSection
      ..beatPosition = renderingSectionBeat
      ..notationAlpha = notationOpacityNotifier.value
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
    bool stemsUp, double alpha, Iterable<Melody> otherMelodiesOnStaff) {
    double opacityFactor = 1;
    if (melodyBounds.left < visibleRect().left + standardBeatWidth) {
      opacityFactor = max(0, min(1, (melodyBounds.left - visibleRect().left) / standardBeatWidth));
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
