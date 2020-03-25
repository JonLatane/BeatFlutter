import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'drawing/sizeutil.dart';
import 'generated/protos/music.pb.dart';
import 'util.dart';

Chord cMaj7 = Chord()
  ..rootNote = (NoteName()..noteLetter = NoteLetter.C..noteSign = NoteSign.natural)
  ..chroma = 2047;
var section1 = Section()
  ..id = uuid.v4()
  ..name = ""
  ..harmony = (
    Harmony()
      ..id = uuid.v4()
      ..meter = (Meter()..defaultBeatsPerMeasure = 4)
      ..subdivisionsPerBeat = 4
      ..length = 64
      ..data.addAll({0: cMaj7, 1: cMaj7})
  );
var score = Score()
  ..sections.addAll([
    section1,
  ]);