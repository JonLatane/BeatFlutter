import 'package:flutter/material.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';

class PartMelodiesView extends StatelessWidget {
  final Score score;
  final Axis axis;

  PartMelodiesView({this.score, this.axis = Axis.horizontal});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: axis,
      itemBuilder: (context, position) {
        return (axis == Axis.horizontal)
          ? Container(
          width: 120,
          child: Column(children: [
            Expanded(flex:0,child:RaisedButton(
              color: score.parts[position].instrument.type == InstrumentType.drum ? Colors.brown : Colors.black,
              padding: EdgeInsets.all(0),
              child: Text(score.parts[position].instrument.name, style: TextStyle(color: Colors.white)),
              onPressed: () => {},
            )),
            Expanded(
              child: ListView.builder(
                scrollDirection: (axis == Axis.horizontal) ? Axis.vertical : Axis.horizontal,
                itemBuilder: (context, melodyPosition) =>
                  RaisedButton(onPressed: () {}, child: Text("Melody ${melodyPosition + 1}")),
                itemCount: score.parts[position].melodies.length))
          ]))
          : Row(children: [
          RaisedButton(
            color: Colors.black,
            child: Text(score.parts[position].instrument.name, style: TextStyle(color: Colors.white)),
            onPressed: () => {},
          )
        ]);
      },
      itemCount: score.parts.length,
    );
  }
}