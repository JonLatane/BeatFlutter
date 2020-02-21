import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

Duration animationDuration = const Duration(milliseconds: 300);
class SectionList extends StatelessWidget {
  final Axis scrollDirection;
  final bool visible;
  final Score score;
  final Section currentSection;
  final Function(Section) selectSection;

  const SectionList({Key key, this.scrollDirection, this.visible, this.score, this.currentSection, this.selectSection})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        height: (scrollDirection == Axis.vertical) ? MediaQuery.of(context).size.height : (visible) ? 36 : 0,
        width: (scrollDirection == Axis.horizontal) ? MediaQuery.of(context).size.width : (visible) ? 36 : 0,
        child: (scrollDirection == Axis.horizontal)
            ? Row(children: [
                Expanded(
                    child: ListView.builder(
                  scrollDirection: scrollDirection,
                  itemBuilder: (context, position) {
                    return RaisedButton(
                      color: (currentSection == score.sections[position]) ? Colors.white : Colors.white70,
                      child: Text(score.sections[position].name),
                      onPressed: () => {selectSection(score.sections[position])},
                    );
                  },
                  itemCount: score.sections.length,
                )),
                RaisedButton(
                  child: Text('+'),
                  onPressed: () => {
                    //selectSection(score.sections[position])
                  },
                )
              ])
            : Column(children: [
                Expanded(
                    child: ListView.builder(
                  scrollDirection: scrollDirection,
                  itemBuilder: (context, position) {
                    return RaisedButton(
                      color: (currentSection == score.sections[position]) ? Colors.white : Colors.grey,
                      child: Text(score.sections[position].name),
                      onPressed: () => {
                        //selectSection(score.sections[position])
                      },
                    );
                  },
                  itemCount: score.sections.length,
                )),
                RaisedButton(
                  child: Text('+'),
                  onPressed: () => {
                    //selectSection(score.sections[position])
                  },
                )
              ]));
  }
}
