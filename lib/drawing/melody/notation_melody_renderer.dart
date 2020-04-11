import 'dart:math';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/music_theory.dart';
import 'package:beatscratch_flutter_redux/music_notation_theory.dart';
import 'package:beatscratch_flutter_redux/util.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:quiver/cache.dart';
import 'package:unification/unification.dart';
import 'base_melody_renderer.dart';
import 'melody_staff_lines_renderer.dart';
import '../canvas_tone_drawer.dart';

enum Notehead { quarter, half, whole, percussion }
class NotationMelodyRenderer extends BaseMelodyRenderer {
//  static final ui.Image notehead = await loadUiImage("");
  @override bool showSteps = true;
  @override double normalizedDevicePitch = 0;
  double notationAlpha = 1;
  int maxSubdivisonsPerBeatUnder7 = 7;
  bool stemsUp = true;

//  (renderedMelodies + melody)
//    .filter { it.subdivisionsPerBeat <= 7 }
//  .maxBy { it.subdivisionsPerBeat }?.subdivisionsPerBeat ?: 7
  int maxSubdivisonsPerBeatUnder13 = 13;

//  val maxSubdivisonsPerBeatUnder13 = (renderedMelodies + melody)
//    .filter { it.subdivisionsPerBeat <= 13 }
//  .maxBy { it.subdivisionsPerBeat }?.subdivisionsPerBeat ?: 13
  int maxSubdivisonsPerBeat = 24;

//  val maxSubdivisonsPerBeat = (renderedMelodies + melody)
//    .maxBy { it.subdivisionsPerBeat }?.subdivisionsPerBeat ?: 24


  @override double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
  List<Clef> clefs = [Clef.treble, Clef.bass];

  draw(Canvas canvas, bool stemsUp) {
    bounds = overallBounds;
    canvas.save();
    canvas.translate(0, bounds.top);
    alphaDrawerPaint.color = Colors.black.withAlpha((255 * notationAlpha).toInt());
    _drawNotationMelody(canvas);
    canvas.restore();
  }

  _drawNotationMelody(Canvas canvas) {
    double maxBoundsWidthUnder7 = min(
      (overallBounds.right - overallBounds.left) / maxSubdivisonsPerBeatUnder7, letterStepSize * 10
    );
    double maxBoundsWidthUnder13 = min(
      (overallBounds.right - overallBounds.left) / maxSubdivisonsPerBeatUnder13, letterStepSize * 10
    );
    double maxBoundsWidth = min(
      (overallBounds.right - overallBounds.left) / maxSubdivisonsPerBeat, letterStepSize * 10
    );
    iterateSubdivisions(() {
      double boundsWidth = maxBoundsWidth;
      if (melody.subdivisionsPerBeat <= 7) {
        boundsWidth = maxBoundsWidthUnder7;
      } else if (melody.subdivisionsPerBeat <= 13) {
        boundsWidth = maxBoundsWidthUnder13;
      }
      bounds = Rect.fromLTRB(bounds.left, bounds.top, bounds.right + boundsWidth, bounds.bottom);


      colorGuideAlpha = 0;

      _drawNoteheadsLedgersAndStems(canvas);

    });

    double overallWidth = overallBounds.right - overallBounds.left;
    bounds = Rect.fromLTRB(overallWidth, bounds.top, overallWidth, bounds.bottom);
  }

  _drawNoteheadsLedgersAndStems(Canvas canvas) {
    MelodicAttack element = melody.melodicData.data[elementPosition % melody.length];
    MelodicAttack nextElement = melody.melodicData.data[elementPosition % melody.length];
    bool isChange = element != null;
    alphaDrawerPaint.color =
      ((isChange) ? Color(0xAA212121) : Color(0xAA424242)).withAlpha((notationAlpha * 255).toInt());

    List<int> tones = [];
    if (element != null) {
      tones = element.tones;
    }

    if (tones.isNotEmpty) {
      double boundsWidth = bounds.width;
      double maxFittableNoteheadWidth = (boundsWidth / 2.6).ceilToDouble();
      double noteheadWidth = min(letterStepSize * 2, maxFittableNoteheadWidth);
      double noteheadHeight = noteheadWidth; //(bounds.right - bounds.left)

      List<NoteSpecification> playbackNotes = getPlaybackNotes(tones, chord);//computePlaybackNotes(tones, chord);
      double maxCenter = -100000000;
      double minCenter = 100000000;
      bool hadStaggeredNotes = false;
      bool minWasStaggered = false;
      bool maxWasStaggered = false;
//      print("Rendering playbackNotes $playbackNotes");
      playbackNotes.forEach((note) {
        double center = pointForNote(note);
        minCenter = min(center, minCenter);
        maxCenter = max(center, maxCenter);

        Notehead notehead = Notehead.quarter;
        if(melody.instrumentType == InstrumentType.drum) {
          notehead = Notehead.percussion;
        }
        bool shouldStagger = playbackNotes.any((it) =>
          (it.diatonicValue % 2 == 0
            && (it.diatonicValue == note.diatonicValue + 1 || it.diatonicValue == note.diatonicValue - 1))
            ||
          (it.diatonicValue == note.diatonicValue
            && it.tone > note.tone)
        );
        hadStaggeredNotes = hadStaggeredNotes || shouldStagger;
        if (minCenter == center) minWasStaggered = shouldStagger;
        if (maxCenter == center) maxWasStaggered = shouldStagger;
        double top = center - (noteheadHeight / 2);
        double bottom = center + (noteheadHeight / 2);
        double left, right;
        if (shouldStagger) {
          left = bounds.right - noteheadWidth;
          right = bounds.right;
        } else {
          left = bounds.right - 1.9 * noteheadWidth;
          right = bounds.right - 0.9 * noteheadWidth;
        }
        Rect noteheadRect = Rect.fromLTRB(left, top, right, bottom);
        _drawFilledNotehead(canvas, noteheadRect);
        // Draw signs
        NoteSign previousSign;
//        val previousSign = previousSignOf(melody, harmony, note, elementPosition)
        NoteSign signToDraw;
        switch(note.sign) {
          case NoteSign.sharp:
            if(previousSign != NoteSign.sharp) signToDraw = NoteSign.sharp;
            break;
          case NoteSign.flat:
            if(previousSign != NoteSign.flat) signToDraw = NoteSign.flat;
            break;
          case NoteSign.double_flat:
            if(previousSign != NoteSign.double_flat) signToDraw = NoteSign.double_flat;
            break;
          case NoteSign.double_sharp:
            if(previousSign != NoteSign.double_sharp) signToDraw = NoteSign.double_sharp;
            break;
          case NoteSign.natural:
          default:
          if(previousSign != null && previousSign != NoteSign.natural) signToDraw = NoteSign.natural;
            break;
        }

        if(signToDraw != null) {
          double signLeft, signRight, signTop, signBottom;
          if(shouldStagger) {
            signLeft = bounds.right - 1.6 * noteheadWidth;
            signRight = bounds.right - 1.1 * noteheadWidth;
          } else {
            signLeft = bounds.right - 2.5 * noteheadWidth;
            signRight = bounds.right - 2.0 * noteheadWidth;
          }

          switch(signToDraw) {
            case NoteSign.flat:
            case NoteSign.double_flat:
              signTop = top - 2 * noteheadHeight / 3;
              signBottom = bottom;
              break;
            case NoteSign.double_sharp:
              signTop = top + noteheadHeight / 4;
              signBottom = bottom - noteheadHeight / 4;
              break;
            case NoteSign.sharp:
            case NoteSign.natural:
            default:
              signTop = top - noteheadHeight / 3;
              signBottom = bottom + noteheadHeight / 3;
          }
          Rect signRect = Rect.fromLTRB(signLeft, signTop, signRight, signBottom);
          _renderSign(canvas, signRect, signToDraw);
        }

        alphaDrawerPaint.strokeWidth = max(1, 1 * minScale);

//        drawable.setBounds(signLeft, signTop, signRight, signBottom)
//        drawable.alpha = (255 * alphaSource).toInt()
//        drawable.draw(this)
//        }
        _renderLedgerLines(canvas, note, left, right);
//      }
//
        // Draw the stem
        if (stemsUp) {
          double stemX = bounds.right - 0.965 * noteheadWidth;
          double startY = maxCenter + noteheadHeight * ( (maxWasStaggered) ? .1 : -.1);
          double stopY = minCenter - 3 * noteheadHeight;
          canvas.drawLine(Offset(stemX, startY), Offset(stemX, stopY), alphaDrawerPaint);
        } else {
          double stemX = (hadStaggeredNotes)
            ? bounds.right - 0.95 * noteheadWidth
            : bounds.right - 1.837 * noteheadWidth;
          double startY = minCenter + noteheadHeight *
            ((minWasStaggered || hadStaggeredNotes) ? -.1 : .1);
          double stopY = maxCenter + 3 * noteheadHeight;
          canvas.drawLine(Offset(stemX, startY), Offset(stemX, stopY), alphaDrawerPaint);
        }
      });
    }
  }

  static Path _sharpPath = parseSvgPathData("M 86.102000,447.45700 L 86.102000,442.75300 L 88.102000,442.20100 L 88.102000,446.88100 L 86.102000,447.45700 z M 90.040000,446.31900 L 88.665000,446.71300 L 88.665000,442.03300 L 90.040000,441.64900 L 90.040000,439.70500 L 88.665000,440.08900 L 88.665000,435.30723 L 88.102000,435.30723 L 88.102000,440.23400 L 86.102000,440.80900 L 86.102000,436.15923 L 85.571000,436.15923 L 85.571000,440.98600 L 84.196000,441.37100 L 84.196000,443.31900 L 85.571000,442.93500 L 85.571000,447.60600 L 84.196000,447.98900 L 84.196000,449.92900 L 85.571000,449.54500 L 85.571000,454.29977 L 86.102000,454.29977 L 86.102000,449.37500 L 88.102000,448.82500 L 88.102000,453.45077 L 88.665000,453.45077 L 88.665000,448.65100 L 90.040000,448.26600 L 90.040000,446.31900 z");
  static Path _flatPath = parseSvgPathData("M 98.166,443.657 C 98.166,444.232 97.950425,444.78273 97.359,445.52188 C 96.732435,446.30494 96.205,446.75313 95.51,447.28013 L 95.51,443.848 C 95.668,443.449 95.901,443.126 96.21,442.878 C 96.518,442.631 96.83,442.507 97.146,442.507 C 97.668,442.507 97.999,442.803 98.142,443.393 C 98.158,443.441 98.166,443.529 98.166,443.657 z M 98.091,441.257 C 97.66,441.257 97.222,441.376 96.776,441.615 C 96.33,441.853 95.908,442.172 95.51,442.569 L 95.51,435.29733 L 94.947,435.29733 L 94.947,447.75213 C 94.947,448.10413 95.043,448.28013 95.235,448.28013 C 95.346,448.28013 95.483913,448.18713 95.69,448.06413 C 96.27334,447.71598 96.636935,447.48332 97.032,447.23788 C 97.482617,446.95792 97.99,446.631 98.661,445.991 C 99.124,445.526 99.459,445.057 99.667,444.585 C 99.874,444.112 99.978,443.644 99.978,443.179 C 99.978,442.491 99.795,442.002 99.429,441.713 C 99.015,441.409 98.568,441.257 98.091,441.257 z ");
  static Path _doubleSharpPath = parseSvgPathData("M 125.009,448.30721 C 124.27443,448.19192 123.52769,448.19209 122.7858,448.19294 C 122.77007,447.65011 122.85674,447.0729 122.6415,446.56343 C 122.49821,446.22426 122.22532,445.95665 121.98269,445.68155 C 121.59552,446.0278 121.27751,446.48475 121.24704,447.01638 C 121.21706,447.40767 121.23902,447.80085 121.2322,448.19294 C 120.4904,448.20416 119.74082,448.16828 119.009,448.314 C 119.15012,447.5863 119.11805,446.84171 119.13083,446.1048 C 119.6957,446.08953 120.30023,446.17101 120.82484,445.92526 C 121.13441,445.78023 121.39653,445.55295 121.6591,445.33676 C 121.3173,444.94965 120.87346,444.60861 120.33665,444.57651 C 119.93573,444.54485 119.53266,444.56793 119.13083,444.56097 C 119.10566,443.82949 119.19105,443.08855 119.03921,442.3663 C 119.76267,442.49697 120.50065,442.46343 121.2322,442.47284 C 121.24306,442.99383 121.18483,443.53381 121.33191,444.0355 C 121.44414,444.41838 121.74978,444.71293 122.0051,445.01521 C 122.36553,444.70111 122.69057,444.30706 122.75011,443.81412 C 122.804,443.36793 122.76123,442.91977 122.7858,442.47284 C 123.52263,442.45348 124.28215,442.54713 124.99535,442.314 C 124.88891,443.05711 124.87889,443.81152 124.88717,444.56097 C 124.36127,444.57582 123.80954,444.51747 123.30955,444.69457 C 122.92975,444.8291 122.63114,445.12341 122.32869,445.38325 C 122.65661,445.71867 123.0516,446.02802 123.5403,446.07368 C 123.98834,446.11554 124.43829,446.09658 124.88717,446.1048 C 124.89828,446.83958 124.86193,447.5825 125.009,448.30721 z ");
  static Path _doubleFlatPath = parseSvgPathData("M14.25 6v101.8c9.5-8.7 20.2-13.15 32.04-13.37 7.4 0 13.7 3.08 19 9.23 4.63 5.72 3.1 11.75 3.3 18.75.2 5.57-.5 11.26-3.46 18.47-1.06 2.97-.07 7.15-3.67 10.54l-8.56 7.96C37.3 170.78 21.65 182.36 6 194V6h8.25m25.7 108.8c-2.55-2.98-5.82-4.46-9.84-4.46-5.03 0-9.2 2.86-12.32 8.6-2.33 4.44-3.5 14.94-3.5 31.48v27.36c.22.84 6.14-4.35 17.77-15.6 6.35-5.93 10.48-12.93 12.38-21 .86-3.17 1.28-6.35 1.28-9.53 0-7-1.9-12.62-5.7-16.86")
    ..addPath(parseSvgPathData("M68.6 6v101.8c9.53-8.7 20.2-13.15 32.05-13.37 7.4 0 13.75 3.08 19.03 9.23 4.66 5.72 7.1 12.1 7.3 19.08.2 5.52-1.16 11.88-4.12 19.1-1.06 2.96-3.4 6.14-6.98 9.53l-8.57 7.96c-15.6 11.45-31.3 23-46.9 34.67V6h8.25m25.7 108.8c-2.53-2.98-5.8-4.46-9.83-4.46-5.06 0-9.2 2.86-12.36 8.6-2.32 4.44-3.5 14.94-3.5 31.48v27.36c.22.84 6.15-4.35 17.78-15.6 6.35-5.93 10.47-12.93 12.38-21 .84-3.17 1.27-6.35 1.27-9.53 0-7-1.9-12.62-5.7-16.86"), Offset.zero);
  static Path _naturalPath = parseSvgPathData("M 26.578125,106.17187 L 22.640625,107.57812 L 22.640625,75.375001 L 0,85.218751 L 0,1.6875 L 3.796875,1.4210855e-014 L 3.796875,32.765625 L 26.578125,22.359375 L 26.578125,106.17187 z M 22.640625,61.171871 L 22.640625,38.671875 L 3.796875,46.96875 L 3.796875,69.468751 L 22.640625,61.171871 z ");
  _renderSign(Canvas canvas, Rect signRect, NoteSign sign) {
//    canvas.drawRect(signRect, Paint()..style=PaintingStyle.fill..color=Colors.black26);
    print("Rendering sign: $sign");
    canvas.save();
    canvas.translate(signRect.topLeft.dx, signRect.topLeft.dy);
    Path signPath = _sharpPath;
    switch(sign) {
      case NoteSign.sharp:
        signPath = _sharpPath;
        canvas.scale(1.6 * minScale, 1.6 * minScale);
        canvas.translate(-84.19600,-436.0680 + 1);
//    canvas.scale(0.1);
        break;
      case NoteSign.flat:
        signPath = _flatPath;
        canvas.scale(1.8 * minScale, 1.8 * minScale);
        canvas.translate(-94.947,-433.75 + 1);
        break;
      case NoteSign.double_flat:
        signPath = _doubleFlatPath;
        break;
      case NoteSign.double_sharp:
        signPath = _doubleSharpPath;
        canvas.translate(-119.009,-441.814);
        break;
      case NoteSign.natural:
      default:
        signPath = _naturalPath;
        break;
    }
    canvas.drawPath(signPath, Paint()..style=PaintingStyle.fill..color=Colors.black);
    canvas.restore();
  }

  _renderLedgerLines(Canvas canvas, NoteSpecification note, double left, double right) {
    try {
      if (!clefs.any((clef) => clef.covers(note))) {
        Clef nearestClef = clefs.minBy((it) =>
          min((note.diatonicValue - it.diatonicMax).abs(), (note.diatonicValue - it.diatonicMin).abs()));
        nearestClef.ledgersTo(note).forEach((ledger) {
          drawPitchwiseLine(
            canvas: canvas,
            pointOnToneAxis: pointFor(letter: ledger.letter, octave: ledger.octave),
            left: left - 3,
            right: right + 3
          );
        });
      }
    } catch(t) {
      print(t);
    }
  }

//  static List<List<dynamic>> _recentPlaybackNoteRequests = List();
  static Map<List<dynamic>, List<NoteSpecification>> _playbackNoteCache = Map();
  List<NoteSpecification> getPlaybackNotes(List<int> tones, Chord chord) {
    List<dynamic> key = [tones, chord];
    return _playbackNoteCache.putIfAbsent(key,
        () {
//          _recentPlaybackNoteRequests.remove(key);
//          _recentPlaybackNoteRequests.insert(0, key);
//          if(_recentPlaybackNoteRequests.length > 30000) {
//            _recentPlaybackNoteRequests.removeRange(10000, _recentPlaybackNoteRequests.length - 1);
//          }
        return computePlaybackNotes(tones, chord);
      }
    );
  }

  List<NoteSpecification> computePlaybackNotes(List<int> tones, Chord chord) => tones.map<NoteSpecification>((int tone) {

    int playbackTone = tone.playbackToneUnder(chord, melody);
    if(melody.interpretationType == MelodyInterpretationType.fixed_nonadaptive) {
      return playbackTone.naturalOrSharpNote;
    } else {
      return playbackTone.nameNoteUnderChord(chord);
    }
  }).toList();


  _drawFilledNotehead(Canvas canvas, Rect rect) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.58171824);
    var target = rect.shift(-rect.center);
    target = Rect.fromCenter(center: target.center, width: target.width, height: target.height * 0.7777777);
    canvas.drawOval(target, alphaDrawerPaint);
    canvas.restore();
  }
}
