// import 'export_models.dart';
import 'package:beatscratch_flutter_redux/widget/my_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../colors.dart';
import '../ui_models.dart';
import '../util/util.dart';
import 'universe.dart';

class UniverseViewUI {
  bool visible = false;
  final Function(VoidCallback) setAppState;

  UniverseViewUI(this.setAppState);
  double height(BuildContext context) => !visible
      ? 0
      : MediaQuery.of(context).size.height > 800
          ? 400
          : MediaQuery.of(context).size.height > 600
              ? 300
              : MediaQuery.of(context).size.height > 500
                  ? 220
                  : 150;

  Widget build({@required BuildContext context, @required Color sectionColor}) {
    return AnimatedContainer(
        duration: animationDuration,
        padding: EdgeInsets.all(3),
        height: height(context),
        child: Column(
          children: [
            Row(
              children: [
                Transform.translate(
                    offset: Offset(0, 1.5),
                    child: Icon(FontAwesomeIcons.globe, color: Colors.white)),
                SizedBox(width: 3),
                Text("Beat",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                Text("Scratch",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w100)),
                SizedBox(width: 5),
                Text("Universe",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500)),
                Expanded(child: SizedBox()),
                // MyPopupMenuButton(itemBuilder: itemBuilder)
              ],
            ),
            Expanded(child: Container(color: Colors.black12, child: SizedBox()))
          ],
        ));
  }

  static const TextStyle labelStyle =
      TextStyle(fontWeight: FontWeight.w200, color: Colors.white);
  static const TextStyle valueStyle =
      TextStyle(fontWeight: FontWeight.w600, color: Colors.white);
  static const EdgeInsets itemPadding =
      EdgeInsets.only(left: 5, top: 5, bottom: 5);
}
