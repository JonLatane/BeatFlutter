import 'package:archive/archive.dart';
import 'package:base_x/base_x.dart';
import 'package:beatscratch_flutter_redux/midi_theory.dart';
import 'package:beatscratch_flutter_redux/my_platform.dart';
import 'package:unification/unification.dart';

import 'generated/protos/music.pb.dart';
import 'util.dart';

var _base58 = BaseXCodec('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ');

extension URLConversions on Score {
  String convertToUrl() {
    final dataString = toUrlHashValue();
    final prefix = MyPlatform.isDebug ? "http://localhost:8000/app-staging/" : "https://beatscratch.io/app/";
    final urlString = "$prefix#/score/$dataString";
    return urlString;
  }

  String toUrlHashValue() {
    final data = writeToBuffer();
    final bz2Data = BZip2Encoder().encode(data);
    final dataToConvert = (data.length <= bz2Data.length) ? data : bz2Data;
    final dataString = _base58.encode(dataToConvert);
    return dataString;
  }
}

Score scoreFromUrlHashValue(String urlString) {
  final dataBytes = _base58.decode(urlString);
  Score score;
  try {
    score = Score.fromBuffer(dataBytes);
  } catch (any) {
    try {
      score = Score.fromBuffer(BZip2Decoder().decodeBytes(dataBytes));
    } catch (any) {
    }
  }
  return score;
}

