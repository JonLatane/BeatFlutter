import 'package:beatscratch_flutter_redux/expanded_section.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'animations/animations.dart';
import 'ui_models.dart';
import 'util.dart';
import 'music_theory.dart';

class PartConfiguration extends StatefulWidget {
  final Part part;
  final Function(VoidCallback) superSetState;

  const PartConfiguration({Key key, this.part, this.superSetState}) : super(key: key);
  @override
  _PartConfigurationState createState() => _PartConfigurationState();
}

class _PartConfigurationState extends State<PartConfiguration> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children:[
        Row(children: [
          Expanded(child:Text("MIDI Channel:")),

          Container(
            width: 25,
            child: RaisedButton(
              child: Icon(Icons.arrow_upward),
              onPressed: (widget.part.instrument.midiChannel < 16) ? () {
                widget.superSetState(() {
                  setState(() {
                    widget.part.instrument.midiChannel += 1;
                  });
                });
              } : null,
              padding: EdgeInsets.all(0),)),
          Container(
            width: 45,
            child: RaisedButton(onPressed: () {}, padding: EdgeInsets.all(0), child: Text(
              (widget.part.instrument.midiChannel + 1).toString()
            ))),
          Container(
            width: 25,
            child: RaisedButton(
              child: Icon(Icons.arrow_downward),
              onPressed: (widget.part.instrument.midiChannel >= 0) ? () {
                widget.superSetState(() {
                  setState(() {
                    widget.part.instrument.midiChannel -= 1;
                  });
                });
              } : null,
              padding: EdgeInsets.all(0),)),
        ]),
      ]
    );
  }
}
