import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dart_midi/dart_midi.dart';

import '../generated/protos/protos.dart';
import 'export_manager.dart';
import 'midi_export.dart';

enum ExportType {
  midi
}

class BSExport {
  Score score;
  ExportType exportType;
  String sectionId;
  List<String> partIds;

  BSExport({this.score, this.exportType = ExportType.midi, this.sectionId, this.partIds});

  File call(ExportManager exportManager) {
    final midiFile = score.exportMidi(this);
    final fileHandle = exportManager.createExportFile(score, exportType);
    MidiWriter().writeMidiToFile(midiFile, fileHandle);
    return fileHandle;
  }
}