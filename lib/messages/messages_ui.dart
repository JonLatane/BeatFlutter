
// import 'export_models.dart';
import 'package:beatscratch_flutter_redux/messages/bs_message.dart';
import 'package:flutter/material.dart';

import '../colors.dart';
import '../ui_models.dart';
import '../util/util.dart';

class MessagesUI {
  MessagesUI(this.setState);

  static double _messageHeight(BuildContext context) => context.isLandscapePhone ? 25 : 30;
  List<BSMessage> messages = [];
  double height(BuildContext context) => messages.length * _messageHeight(context);
  final Function(VoidCallback) setState;

  sendMessage({@required message, icon, color, timeout = const Duration(milliseconds: 1500),
  bool isError = false}) {
    if (icon == null) {
      icon = isError
        ? Icon(Icons.warning, size: 18, color: color ?? chromaticSteps[7])
        : Icon(Icons.info, size: 18, color: color ?? chromaticSteps[0]);
    }
    final bsMessage = BSMessage(message: message, timeout: timeout, icon: icon);
    messages.add(bsMessage);
    Future.delayed(timeout, () {
      setState((){
        bsMessage.visible = false;
        Future.delayed(animationDuration, () {
          removeMessage(bsMessage, icon: icon, message: message);
        });
      });
    });
  }

  removeMessage(BSMessage bsMessage, {@required icon, @required message, timeout = const Duration(milliseconds: 500),}) {
    setState((){
      bsMessage.visible = false;
    });
    Future.delayed(animationDuration, () {
      setState((){
        messages.remove(bsMessage);
      });
    });
  }

  Widget build({@required BuildContext context}) {
    return Column(children: messages.map((m) => buildMessage(m, context: context)).toList(growable: false));
  }

  Widget buildMessage(BSMessage message, {@required BuildContext context,}) {
    return AnimatedContainer(
      duration: animationDuration,
      height: message.visible ? _messageHeight(context) : 0,
      color: Color(0xFF212121),
      child: Row(children: [
        SizedBox(width: 5),
        AnimatedOpacity(
          duration: animationDuration,
          opacity: message.visible ? 1 : 0,
          child: message.icon),
        SizedBox(width: 5),
        Text(message.message,
          style: TextStyle(
            color: Colors.white,
          ))
      ]));
  }

  static const TextStyle labelStyle = TextStyle(fontWeight: FontWeight.w200, color: Colors.white);
  static const TextStyle valueStyle = TextStyle(fontWeight: FontWeight.w600, color: Colors.white);
  static const EdgeInsets itemPadding = EdgeInsets.only(left: 5, top: 5, bottom: 5);
}
