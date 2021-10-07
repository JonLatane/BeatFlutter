import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:recase/recase.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/midi_theory.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
import '../widget/incrementable_value.dart';
import '../widget/my_buttons.dart';
import '../widget/my_platform.dart';

class PartConfiguration extends StatefulWidget {
  final Part part;
  final Function(VoidCallback) superSetState;
  final double availableHeight;
  final bool visible;

  const PartConfiguration(
      {Key key,
      this.part,
      this.superSetState,
      this.availableHeight,
      this.visible})
      : super(key: key);

  @override
  _PartConfigurationState createState() => _PartConfigurationState();
}

class _PartConfigurationState extends State<PartConfiguration> {
  TextEditingController searchController = TextEditingController();
  ScrollController scrollController = ScrollController();

  int get midiChannel => widget.part?.instrument?.midiChannel;

  int get midiInstrument => widget.part?.instrument?.midiInstrument;

  int get midiMsb => widget.part?.instrument?.midiGm2Msb;

  int get midiLsb => widget.part?.instrument?.midiGm2Lsb;

  set midiChannel(int value) {
    widget.part?.instrument?.midiChannel = value;
  }

  set midiInstrument(int value) {
    var part = widget.part;
    if (part != null) {
      part.instrument.midiInstrument = value;
    }
  }

  bool get isHarmonic => widget?.part?.isHarmonic ?? false;

  bool get isDrum => widget?.part?.isDrum ?? false;
  String searchText = "";

  Widget _buildMidiInstrumentDisplay(
      BuildContext context, Animation<double> animation, item, int i) {
    String displayedChannel = "";
    String text = "Drums";
    bool isSelected = false;
    if (isDrum) {
      text = "Drums";
      isSelected = true;
    }
    if (item >= 0) {
      text = midiInstruments[item].titleCase.replaceAll("F X", "FX");
      isSelected = midiInstrument == item;
      displayedChannel = (item + 1).toString();
    }

    Widget tile = AnimatedContainer(
        duration: animationDuration,
        color: isSelected ? Colors.white : Colors.transparent,
        child: Column(children: [
          Text(
            displayedChannel,
            maxLines: 2,
            overflow: TextOverflow.fade,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? Colors.black
                    : BeatScratchPlugin.isSynthesizerAvailable
                        ? Colors.white
                        : Colors.white.withAlpha(127)),
          ),
          Expanded(
              child: RotatedBox(
            quarterTurns: 3,
            child: MyFlatButton(
                onPressed: isHarmonic &&
                        BeatScratchPlugin.isSynthesizerAvailable
                    ? () {
                        widget.superSetState(() {
                          setState(() {
                            midiInstrument = item;
                          });
                        });
                        BeatScratchPlugin.updatePartConfiguration(widget.part);
                      }
                    : null,
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 5),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(text,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.black
                                : BeatScratchPlugin.isSynthesizerAvailable
                                    ? Colors.white
                                    : Colors.white.withAlpha(127))))),
          ))
        ]));
    return SizeFadeTransition(
        key: Key("midi-instrument-display-$item"),
        sizeFraction: 0.0,
        curve: Curves.easeInOut,
        axis: Axis.vertical,
        animation: animation,
        child: tile);
  }

  @override
  dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<int> items = widget.part == null
        ? []
        : isHarmonic
            ? range(0, 128).toList()
            : [-1];
    if (searchText.trim().isNotEmpty && isHarmonic) {
      items = items
          .where((i) =>
              i == midiInstrument ||
              midiInstruments[i]
                  .toLowerCase()
                  .contains(searchController.text.toLowerCase()))
          .toList();
    }
    int maxMidiChannel = 15;
    if (MyPlatform.isIOS) {
      maxMidiChannel = 4;
    }
    double height = widget.visible ? 280 : 0;
    double bottomBlankSpaceHeight = context.isLandscapePhone && widget.visible
        ? MediaQuery.of(context).size.height * 0.15
        : 0;
    return SingleChildScrollView(
        controller: scrollController,
        child: AnimatedContainer(
            duration: animationDuration,
            curve: Curves.ease,
            height: height + bottomBlankSpaceHeight,
            child: Column(children: [
              Row(children: [
                Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text("Volume:",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.white))),
                SizedBox(
                  width: 50,
                ),
                Expanded(
                    child: MySlider(
                        value: max(
                            0.0,
                            min(
                                1.0,
                                widget.part == null
                                    ? 0
                                    : widget.part.instrument.volume)),
                        activeColor: Colors.white,
                        onChanged: (value) {
                          widget.superSetState(() {
                            setState(() {
                              widget.part?.instrument?.volume = value;
                              BeatScratchPlugin.updatePartConfiguration(
                                  widget.part);
                            });
                          });
                        }))
              ]),
              Row(children: [
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text("MIDI Channel:",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)))),
                IncrementableValue(
                  onDecrement: (isHarmonic && midiChannel > 0)
                      ? () {
                          if (midiChannel > 0) {
                            widget.superSetState(() {
                              setState(() {
                                midiChannel -= 1;
                                if (midiChannel == 9) {
                                  midiChannel -= 1;
                                }
                              });
                            });
                            BeatScratchPlugin.updatePartConfiguration(
                                widget.part);
                          }
                        }
                      : null,
                  onIncrement: (isHarmonic && midiChannel < maxMidiChannel)
                      ? () {
                          if (midiChannel < maxMidiChannel) {
                            widget.superSetState(() {
                              setState(() {
                                midiChannel += 1;
                                if (midiChannel == 9) {
                                  midiChannel += 1;
                                }
                              });
                            });
                            BeatScratchPlugin.updatePartConfiguration(
                                widget.part);
                          }
                        }
                      : null,
                  valueWidth: 100,
                  value: "Channel ${(midiChannel ?? -2) + 1}",
                ),
                // SizedBox(width: 5)
              ]),
              Row(children: [
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text("MIDI Instrument:",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)))),
                Container(
                  color: Colors.white,
                  // height: 36,
                  child: Row(
                    children: [
                      SizedBox(width: 3),
                      Icon(Icons.search, color: Colors.grey),
                      Container(
                          width: 95,
                          child: TextField(
                            style: TextStyle(fontSize: 12, color: Colors.black),
                            controller: searchController,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) {
                              setState(() {
                                searchText = value;
                              });
                            },
                            onTap: () {
                              if (context.isLandscapePhone) {
                                scrollController.animateTo(100,
                                    duration: animationDuration,
                                    curve: Curves.ease);
                              }
                            },
//          onTap: () {
//            if (!context.isTabletOrLandscapey) {
//              widget.hideMelodyView();
//            }
//          },
                            decoration: InputDecoration(
                                border: InputBorder.none, hintText: "Search"),
                          )),
                      Container(
                        width: 32,
                        height: 32,
                        child: MyFlatButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                searchController.value =
                                    searchController.value.copyWith(text: "");
                              });
                            },
                            child: Icon(Icons.close, color: Colors.black)),
                      )
                    ],
                  ),
                ),
                SizedBox(width: 5)
              ]),
              SizedBox(height: 2),
              Expanded(
                  child: ImplicitlyAnimatedList<int>(
                scrollDirection: Axis.horizontal,
                key: ValueKey("InstrumentPickerList"),
                areItemsTheSame: (oldItem, newItem) => oldItem != newItem,
                items: items,
                itemBuilder: _buildMidiInstrumentDisplay,
              )),
              AnimatedContainer(
                  duration: animationDuration,
                  curve: Curves.ease,
                  height: bottomBlankSpaceHeight),
            ])));
  }
}
