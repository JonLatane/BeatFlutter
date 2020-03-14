import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'drawing/sizeutil.dart';
import 'generated/protos/music.pb.dart';
import 'util.dart';

var section1 = Section()
  ..id = uuid.v4()
  ..name = "Section 1";
var score = Score()
  ..parts.addAll([
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Drums"
        ..volume = 0.5
        ..type = InstrumentType.drum)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Piano"
        ..volume = 0.5
        ..type = InstrumentType.harmonic)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Bass"
        ..volume = 0.5
        ..type = InstrumentType.harmonic)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Muted Electric Jazz Guitar 1"
        ..volume = 0.5
        ..type = InstrumentType.harmonic)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Part 5"
        ..volume = 0.5
        ..type = InstrumentType.harmonic)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
  ])
  ..sections.addAll([
    section1,
    Section()
      ..id = uuid.v4()
      ..name = "Section 2",
    Section()
      ..id = uuid.v4()
      ..name = "Section 3",
    Section()
      ..id = uuid.v4()
      ..name = "Section 4",
    Section()
      ..id = uuid.v4()
      ..name = "Section 5"
  ]);