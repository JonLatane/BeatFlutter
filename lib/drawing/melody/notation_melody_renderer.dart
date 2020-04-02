import 'dart:math';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/music_theory.dart';
import 'package:beatscratch_flutter_redux/music_notation_theory.dart';
import 'package:beatscratch_flutter_redux/util.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
    alphaDrawerPaint.strokeWidth = 3;
//    alphaDrawerPaint.strokeWidth = max(1.0, bounds.width * 0.008);

//    double alphaMultiplier = (isMelodyReferenceEnabled) ? 1.0 : 2.0 / 3;
    _drawNotationMelody(canvas);
//
    NoteSpecification highestDiatonicNote = clefs.expand((clef) => clef.notes).maxBy((e) => e.diatonicValue);
    NoteSpecification lowestDiatonicNote = clefs.expand((clef) => clef.notes).minBy((e) => e.diatonicValue);

//    if(isFinalBeat) {
//      print("final beat is beat $beatPosition");
//      drawTimewiseLineRelativeToBounds(
//        canvas: canvas,
//        leftSide: true,
//        alpha: notationAlpha,
//        strokeWidth: 3,
//        startY: pointForNote(highestDiatonicNote),
//        stopY: pointForNote(lowestDiatonicNote),
//      );
//    }
//TODO Most of this code can go up into MelodyRenderer
//    paint.color = color(android.R.color.black).withAlpha(
//    if (focusedMelody != null) (255 * notationAlpha / 3f).toInt()
//    else (255 * notationAlpha).toInt()
//    )
//    var melodiesToRender = sectionMelodiesOfPartType.filter { it != focusedMelody }
//    if(focusedMelody == null) {
//    melodiesToRender = melodiesToRender.sortedByDescending { otherMelody ->
//    otherMelody.averageTone!!
//    }
//    }
//    val melodyToRenderSelectionAndPlaybackWith = when(focusedMelody) {
//    null -> melodiesToRender.maxBy { it.subdivisionsPerBeat }
//    else -> null
//    }
//    // Render queue is accessed from two directions; in order from highest to lowest Melody
//    val renderQueue = melodiesToRender.toMutableList()
//    var index = 0
//    while(renderQueue.isNotEmpty()) {
//    // Draw highest Melody stems up, lowest stems down, second lowest stems up, second highest
//    // down. And repeat.
//    val (otherMelody, stemsUp) = when (index % 4) {
//    0    -> renderQueue.removeAt(0) to true
//    1    -> renderQueue.removeAt(renderQueue.size - 1) to false
//    2    -> renderQueue.removeAt(renderQueue.size - 1) to true
//    else -> renderQueue.removeAt(0) to false
//    }
//    val drawSelectionAndPlayback = otherMelody == melodyToRenderSelectionAndPlaybackWith
//    this.drawNotationMelody(
//      canvas: canvas,
//    drawAlpha: viewModel.openedMelody?.let { notationAlpha / 3 } ?: notationAlpha,
//    stemsUp: stemsUp
//    )
//    index++
//    }
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
      print("Rendering playbackNotes $playbackNotes");
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
//        notehead.setBounds(left, top, right, bottom)
//        notehead.alpha = (255 * alphaSource).toInt()
//        notehead.draw(this)
//
//        // Draw signs
//        val previousSign = previousSignOf(melody, harmony, note, elementPosition)
//        when (note.sign) {
//        Note.Sign.Sharp -> when(previousSign) {
//        Note.Sign.Sharp -> null
//        else -> sharpPool
//        }
//        Note.Sign.Flat  -> when(previousSign) {
//        Note.Sign.Flat -> null
//        else -> flatPool
//        }
//        Note.Sign.DoubleSharp -> when(previousSign) {
//        Note.Sign.DoubleSharp -> null
//        else -> doubleSharpPool
//        }
//        Note.Sign.DoubleFlat -> when(previousSign) {
//        Note.Sign.DoubleFlat -> null
//        else -> doubleFlatPool
//        }
//        Note.Sign.Natural, Note.Sign.None -> when(previousSign) {
//        Note.Sign.Natural, Note.Sign.None -> null
//        else -> naturalPool
//        }
//        }?.borrow()
//          ?.apply { alpha = (255 * alphaSource).toInt() }
//          ?.let { drawable ->
//        val (signLeft, signRight) = if (shouldStagger) {
//        (bounds.right - 1.6f * noteheadWidth).toInt() to (bounds.right - 1.1f * noteheadWidth).toInt()
//        } else {
//        (bounds.right - 2.5f * noteheadWidth).toInt() to (bounds.right - 2.0f * noteheadWidth).toInt()
//        }
//        val (signTop, signBottom) = when (note.sign) {
//        Note.Sign.Flat, Note.Sign.DoubleFlat ->
//        top - 2 * noteheadHeight / 3 to bottom
//        Note.Sign.DoubleSharp ->
//        top + noteheadHeight / 4 to bottom - noteheadHeight / 4
//        Note.Sign.Sharp, Note.Sign.Natural, Note.Sign.None ->
//        top - noteheadHeight / 3 to bottom + noteheadHeight / 3
//        }
//        drawable.setBounds(signLeft, signTop, signRight, signBottom)
//        drawable.alpha = (255 * alphaSource).toInt()
//        drawable.draw(this)
//        }
//        renderLedgerLines(note, left, right)
//      }
//
//      // Draw the stem
//      if (stemsUp) {
//        val stemX = bounds.right - 0.95 * noteheadWidth
//        val startY = maxCenter + noteheadHeight * (if (maxWasStaggered) .2f else -.2f)
//        val stopY = minCenter - 3 * noteheadHeight
//        drawLine(stemX, startY, stemX, stopY, paint)
//      } else {
//        val stemX = if (hadStaggeredNotes) bounds.right - 0.95 * noteheadWidth
//        else bounds.right - 1.85 * noteheadWidth
//        val startY = minCenter + noteheadHeight * when {
//        minWasStaggered || hadStaggeredNotes -> -.2
//        else -> .2
//        }
//        double stopY = maxCenter + 3 * noteheadHeight;
//        canvas.drawLine(Offset(stemX, startY), Offset(stemX, stopY), alphaDrawerPaint);
      });
    }
  }

  hello() {
    Map<List<dynamic>, List<NoteSpecification>> cache = Map();


  }

  static List<List<dynamic>> _recentPlaybackNoteRequests = List();
  static Map<List<dynamic>, List<NoteSpecification>> _playbackNoteCache = Map();
  List<NoteSpecification> getPlaybackNotes(List<int> tones, Chord chord) {
    List<dynamic> key = [tones, chord];
    return _playbackNoteCache.putIfAbsent(key,
        () {
          _recentPlaybackNoteRequests.remove(key);
          _recentPlaybackNoteRequests.insert(0, key);
          if(_recentPlaybackNoteRequests.length > 30000) {
            _recentPlaybackNoteRequests.removeRange(10000, _recentPlaybackNoteRequests.length - 1);
          }
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
