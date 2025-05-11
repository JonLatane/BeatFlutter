import 'dart:io';

import 'package:beatscratch_flutter_redux/midi/midi_writer.dart';
import 'package:collection/collection.dart';

import '../generated/protos/protos.dart';
import 'export_manager.dart';
import 'midi_export.dart';

enum ExportType { midi }

class BSExport {
  Score score;
  double tempoMultiplier;
  ExportType exportType;
  String? sectionId;
  final List<String> partIds = [];

  BSExport(this.score,
      {this.exportType = ExportType.midi,
      this.tempoMultiplier = 1,
      this.sectionId});

  File call(ExportManager exportManager) {
    final midiFile = score.exportMidi(this);
    final fileHandle = exportManager.createExportFile(this);
    MidiWriter().writeMidiToFile(midiFile, fileHandle);
    return fileHandle;
  }

  Section? get exportedSection => score.sections.isEmpty
      ? null
      : score.sections.firstWhereOrNull((s) => s.id == sectionId);

  bool includesSection(Section section) => sectionId == section.id;

  bool includesPart(Part part) => partIds.isEmpty || partIds.contains(part.id);
}
