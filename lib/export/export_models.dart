import 'package:flutter/foundation.dart';
import '../generated/protos/protos.dart';

enum ExportType {
  midi
}

class BSExport {
  Score score;
  ExportType exportType;
  String sectionId;
  List<String> partIds;

  BSExport({this.score, this.exportType, this.sectionId, this.partIds});
}