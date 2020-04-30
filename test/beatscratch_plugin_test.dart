import 'package:beatscratch_flutter_redux/dummydata.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('PlatformChannelPlugin');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('pushScore', () async {
    Score score = defaultScore();
    await BeatScratchPlugin.createScore(score);
    expect(await BeatScratchPlugin.getScoreId(), '42');
  });
}