import 'dart:math';

import 'base_music_renderer.dart';
import '../../generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../canvas_tone_drawer.dart';
import 'music_staff_lines_renderer.dart';

class MelodyClefRenderer extends BaseMusicRenderer {
  @override
  double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
  List<Clef> clefs; // = [Clef.treble, Clef.bass];

  static Path _trebleClefPath = parseSvgPathData(
      "M 592.10873,1275.9669 C 461.75172,1268.3902 328.65904,1186.6265 249.0601,1092.783 C 156.77394,983.97782 118.72592,836.04683 128.47199,714.56357 C 157.10277,357.61288 545.27831,146.63848 688.97108,-9.280262 C 785.15294,-113.64625 805.31643,-164.52308 826.79977,-218.19949 C 868.39181,-322.09965 875.09166,-443.8341 792.63375,-452.92251 C 713.90712,-461.59988 649.13737,-337.79201 620.20973,-253.17845 C 594.19587,-177.07331 576.90507,-100.71696 592.5563,13.979673 C 599.58954,65.50958 793.18636,1503.9125 796.45179,1526.2088 C 829.05589,1749.0255 701.63092,1841.2249 571.55248,1857.6251 C 290.65671,1893.038 200.52617,1607.5843 326.4212,1499.1719 C 423.34291,1415.7001 564.35026,1487.3615 556.73245,1624.5919 C 549.98693,1746.1391 430.80546,1749.7197 400.35244,1746.9429 C 447.10065,1830.7846 799.52998,1874.5871 745.41513,1495.7923 C 737.811,1442.5634 558.91549,90.842953 554.53112,60.595454 C 521.71238,-165.84753 516.71147,-345.08557 634.69182,-554.25141 C 678.24767,-631.46637 747.0821,-681.3156 780.87362,-674.7893 C 788.29962,-673.35526 795.69824,-670.62872 801.57144,-664.56827 C 892.07191,-571.31845 919.83494,-364.53202 909.9199,-245.74332 C 899.76736,-124.11391 894.1088,1.7993735 773.16902,148.63428 C 726.36601,205.45738 583.54553,330.63538 501.65851,402.55255 C 386.60107,503.59831 303.14756,591.85179 257.99323,698.31862 C 207.24886,817.97506 198.65826,968.6006 313.27268,1102.2505 C 379.20247,1177.7619 488.59222,1231.3424 580.65459,1232.4842 C 836.63719,1235.6628 911.39048,1109.4801 913.77904,966.58197 C 917.71126,731.28351 633.64596,642.32214 516.85762,804.10953 C 449.14212,897.92109 478.90552,996.66049 524.38411,1043.6371 C 539.99424,1059.7587 557.43121,1072.0395 573.92734,1078.8855 C 579.9056,1081.3654 593.96751,1087.9054 589.97593,1097.4779 C 586.6557,1105.4428 580.20702,1105.8904 574.33381,1105.1871 C 500.68573,1096.3544 419.13667,1025.958 399.0828,904.87212 C 369.86288,728.38801 525.6035,519.0349 747.9133,553.274 C 893.45572,575.68903 1028.5853,700.92182 1016.7338,934.11946 C 1006.5722,1133.9822 840.87996,1290.4262 592.10873,1275.9669 z");
  static Path _bassClefPath = parseSvgPathData(
      "M46.593,1.814c16.429,6.061,22.84,20.793,18.019,36.615c-4.08,13.392-12.446,23.87-23.83,31.962    C30.29,77.849,18.962,83.849,7.427,89.48c-0.507,0.247-1.605,0.185-1.874-0.162c-0.637-0.824-0.321-1.557,0.657-2.236    c6.66-4.617,13.521-8.995,19.826-14.061c13.186-10.593,21.679-24.134,23.958-41.147c0.693-5.175,0.587-10.387-0.781-15.466    c-1.404-5.217-4.386-8.989-8.422-10.997c-2.274-1.131-4.882-1.687-7.731-1.656C28.22,3.807,24.553,5.23,24.553,5.23    c-4.075,1.094-7.962,4.981-9.387,8.493c-0.759,1.872,0.258,3.629,2.275,3.713c0.851,0.035,1.756-0.127,2.566-0.405    c5.805-1.997,11.434,1.629,12.717,6.635c1.288,5.026-2.253,10.349-7.873,11.829c-7.101,1.871-14.661-2.16-16.414-9.089    c-1.289-5.096,0.289-9.794,3.124-14.09c4.377-6.632,10.97-9.698,18.415-11.333C36.121-0.366,44.489,1.037,46.593,1.814z     M70.673,39.731c0.015,3.575,2.657,6.239,6.177,6.23c3.44-0.009,6.187-2.816,6.165-6.3c-0.022-3.39-2.741-6.095-6.146-6.114    C73.325,33.527,70.658,36.189,70.673,39.731z M70.674,15.053c0.011,3.585,2.621,6.221,6.16,6.221c3.455,0,6.185-2.765,6.179-6.257    c-0.006-3.385-2.707-6.075-6.127-6.102C73.313,8.887,70.663,11.505,70.674,15.053z");
  draw(Canvas canvas) {
    canvas.save();
    canvas.translate(bounds.left, bounds.top);
    clefs.forEach((clef) {
      canvas.save();
      switch (clef) {
        case Clef.treble:
          canvas.translate(0.2 * bounds.width,
              33.2 * halfStepPhysicalDistance); // Position of clef
          canvas.scale(0.0092 * halfStepPhysicalDistance);
          canvas.drawPath(_trebleClefPath, alphaDrawerPaint);
          break;
        case Clef.bass:
          canvas.translate(0.2 * bounds.width,
              51.75 * halfStepPhysicalDistance); // Position of clef
          canvas.scale(.13 * halfStepPhysicalDistance);
          canvas.drawPath(_bassClefPath, alphaDrawerPaint);
          break;
        case Clef.tenor_treble:
          // TODO: Handle this case.
          break;
        case Clef.drum_treble:
          double top = pointFor(letter: NoteLetter.D, octave: 5);
          double bottom = pointFor(letter: NoteLetter.G, octave: 4);
          double x1 = 0.45 * bounds.width;
          double x2 = 0.55 * bounds.width;
          alphaDrawerPaint.preserveProperties(() {
            alphaDrawerPaint.strokeWidth = max(1, 4 * xScale);
            canvas.drawLine(
                Offset(x1, top), Offset(x1, bottom), alphaDrawerPaint);
            canvas.drawLine(
                Offset(x2, top), Offset(x2, bottom), alphaDrawerPaint);
          });

          canvas.translate(0.57 * bounds.width,
              39.2 * halfStepPhysicalDistance); // Position of clef
          canvas.scale(0.0025 * halfStepPhysicalDistance);
          canvas.drawPath(_trebleClefPath, alphaDrawerPaint);
          break;
        case Clef.drum_bass:
          double top = pointFor(letter: NoteLetter.F, octave: 3);
          double bottom = pointFor(letter: NoteLetter.B, octave: 2);
          double x1 = 0.45 * bounds.width;
          double x2 = 0.55 * bounds.width;
          alphaDrawerPaint.preserveProperties(() {
            alphaDrawerPaint.strokeWidth = max(1, 4 * xScale);
            canvas.drawLine(
                Offset(x1, top), Offset(x1, bottom), alphaDrawerPaint);
            canvas.drawLine(
                Offset(x2, top), Offset(x2, bottom), alphaDrawerPaint);
          });
          canvas.translate(0.59 * bounds.width,
              54.4 * halfStepPhysicalDistance); // Position of clef
          canvas.scale(.033 * halfStepPhysicalDistance);
          canvas.drawPath(_bassClefPath, alphaDrawerPaint);
          break;
      }
      canvas.restore();
    });
    canvas.restore();
//    clefs.expand((clef) => clef.notes).forEach((note) {
//      drawPitchwiseLine(canvas: canvas, pointOnToneAxis: pointForNote(note));
//    });
  }
}
