import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:uuid/uuid.dart';
import 'ui_models.dart';

import 'animations/size_fade_transition.dart';

var uuid = Uuid();
class SectionList extends StatelessWidget {
  final Axis scrollDirection;
  final bool visible;
  final Score score;
  final Color sectionColor;
  final Section currentSection;
  final Function(Section) selectSection;
  final Function(VoidCallback) setState;

  const SectionList({Key key, this.scrollDirection, this.visible, this.score, this.currentSection, this.selectSection, this.sectionColor, this.setState})
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
            child: Padding(padding: EdgeInsets.all(2), child:
            getList(context)
//            ListView.builder(
//              scrollDirection: scrollDirection,
//              itemBuilder: (context, position) {
//                return RaisedButton(
//                  color: (currentSection == score.sections[position]) ? sectionColor : Colors.white,
//                  child: Text(score.sections[position].name, style: TextStyle(fontWeight: FontWeight.w100),),
//                  onPressed: () => {selectSection(score.sections[position])},
//                );
//              },
//              itemCount: score.sections.length,
//            )
            )),
                RaisedButton(
                  child: Icon(Icons.add),
                  onPressed: () {
                    print("inserting section");
                    setState( () {
                      score.sections.insert(
                        score.sections.indexOf(currentSection) + 1,
                        Section()
                          ..id = uuid.v4()
                          ..name = "New Section"
                      );
                    });
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
                  child: Icon(Icons.add),
                  onPressed: () {
                    print("inserting section");
                    setState( () {
                      score.sections.insert(
                        score.sections.indexOf(currentSection) + 1,
                        Section()
                          ..id = uuid.v4()
                          ..name = "New Section"
                      );
                    });
                  },
                )
              ]));
  }

  Widget getList(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<Section>(
      scrollDirection: scrollDirection,
      // The current items in the list.
      items: score.sections,
      // Called by the DiffUtil to decide whether two object represent the same item.
      // For example, if your items have unique ids, this method should check their id equality.
      areItemsTheSame: (a, b) => a.id == b.id,
      onReorderFinished: (item, oldIndex, newIndex, newItems) {
        // Remember to update the underlying data when the list has been
        // reordered.
        setState(() {
//          if (newIndex > oldIndex) {
//            newIndex -= 1;
//          }
          Section toMove = score.sections.removeAt(oldIndex);
          score.sections.insert(newIndex, toMove);
//          widget.score.parts
//            ..clear()
//            ..addAll(newItems);
        });
      },
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, item, index) {
        // Specifiy a transition to be used by the ImplicitlyAnimatedList.
        // In this case a custom transition.
        return Reorderable(
          // Each item must have an unique key.
          key: Key(item.id),
          builder: (context, dragAnimation, inDrag) {
            final t = dragAnimation.value;
            final tile = Handle(delay: const Duration(milliseconds: 250), child: _Section(
              sectionColor: sectionColor,
              selectSection: selectSection,
              currentSection: currentSection,
              section: item,
            ));

            // If the item is in drag, only return the tile as the
            // SizeFadeTransition would clip the shadow.
            if (t > 0.0) {
              return SizeFadeTransition(
                sizeFraction: 0.7,
                curve: Curves.easeInOut,
//                axis: scrollDirection,
                animation: animation,
                child: tile);
            }
            return SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              axis: scrollDirection,
              animation: animation,
              child: tile);
          });
      },
      // An optional builder when an item was removed from the list.
      // If not specified, the List uses the itemBuilder with
      // the animation reversed.
//      removeItemBuilder: (context, animation, oldItem) {
//        return FadeTransition(
//          opacity: animation,
//          child: _buildPart(oldItem),
//        );
//      },
    );
  }
}

class _Section extends StatefulWidget {
  final Section currentSection;
  final Section section;
  final Color sectionColor;
  final Function(Section) selectSection;

  const _Section({Key key, this.section, this.selectSection, this.currentSection, this.sectionColor}) : super(key: key);
  @override
  _SectionState createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _editing = false;
  FocusNode _focus = FocusNode();
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    _controller.text = widget.section.name;
  }

  void _onFocusChange(){
    if(!_focus.hasFocus) {
      _editing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () { widget.selectSection(widget.section); setState(() { _editing = !_editing; }); },
      child:RaisedButton(
      color: (widget.currentSection == widget.section) ? widget.sectionColor : Colors.white,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: _editing ? 200 : null,
        child: _editing ? TextField(
          autofocus: true,
          focusNode: _focus,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(fontWeight: FontWeight.w100, fontSize: 11),
          controller: TextEditingController()
            ..text = widget.section.name,
          onChanged: (value) {
            widget.section.name = value;
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Section Name"
          ),
        ) : Text(widget.section.name, style: TextStyle(fontWeight: FontWeight.w100),)
      ),
      onPressed: () {
        widget.selectSection(widget.section);
      },
    ));
  }
}
