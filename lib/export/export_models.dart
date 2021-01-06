import 'dart:io';

import 'package:dart_midi/dart_midi.dart';

import '../generated/protos/protos.dart';
import 'export_manager.dart';
import 'midi_export.dart';

enum ExportType { midi }

class BSExport {
  Score score;
  double tempoMultiplier;
  ExportType exportType;
  String sectionId;
  final List<String> partIds = [];

  BSExport(
      {this.score,
      this.exportType = ExportType.midi,
      this.tempoMultiplier = 1,
      this.sectionId});

  File call(ExportManager exportManager) {
    final midiFile = score.exportMidi(this);
    final fileHandle = exportManager.createExportFile(this);
    MidiWriter().writeMidiToFile(midiFile, fileHandle);
    return fileHandle;
  }

  Section get exportedSection => score.sections.isEmpty
      ? null
      : score.sections.firstWhere((s) => s.id == sectionId, orElse: () => null);

  bool includesSection(Section section) =>
      sectionId == null || sectionId == section.id;

  bool includesPart(Part part) =>
      partIds == null || partIds.isEmpty || partIds.contains(part.id);
}
