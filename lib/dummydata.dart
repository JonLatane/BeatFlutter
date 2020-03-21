import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'drawing/sizeutil.dart';
import 'generated/protos/music.pb.dart';
import 'util.dart';

var section1 = Section()
  ..id = uuid.v4()
  ..name = "";
var score = Score()
  ..sections.addAll([
    section1,
  ]);