// import 'export_models.dart';
import '../messages/bs_message.dart';
import 'package:flutter/material.dart';

import '../colors.dart';
import '../ui_models.dart';
import '../util/util.dart';

class MessagesUI {
  final Function(VoidCallback) setAppState;
  List<BSMessage> messages = [];

  MessagesUI(this.setAppState);

  static double _messageHeight(BuildContext context) =>
      context.isLandscapePhone ? 25 : 30;
  double height(BuildContext context) =>
      messages.where((m) => m.visible).length * _messageHeight(context);

  BSMessage sendMessage({
    required message,
    icon,
    color,
    timeout = const Duration(milliseconds: 5500),
    bool isError = false,
    String messageId,
    bool andSetState = false,
  }) {
    if (icon == null) {
      icon = isError
          ? Icon(Icons.warning, size: 18, color: color ?? chromaticSteps[7])
          : Icon(Icons.info, size: 18, color: color ?? chromaticSteps[0]);
    }
    if (messageId == null) {
      messageId = uuid.v4();
    }
    final bsMessage = BSMessage(
      id: messageId,
      message: message,
      timeout: timeout,
      icon: icon,
    );
    if (andSetState) {
      setAppState(() {
        messages.add(bsMessage);
      });
    } else {
      messages.add(bsMessage);
    }
    Future.delayed(Duration(milliseconds: 50), () {
      setAppState(() {
        bsMessage.visible = true;
      });
    });
    Future.delayed(timeout, () {
      setAppState(() {
        _removeMessage(bsMessage, icon: icon, message: message);
      });
    });
    return bsMessage;
  }

  _removeMessage(
    BSMessage bsMessage, {
    required icon,
    required message,
  }) {
    setAppState(() {
      bsMessage.visible = false;
    });
    Future.delayed(animationDuration * 5, () {
      setAppState(() {
        messages.remove(bsMessage);
      });
    });
  }

  Widget build({required BuildContext context}) {
    return Column(
        children: messages
            .map((m) => buildMessage(m, context: context))
            .toList(growable: false));
  }

  Widget buildMessage(
    BSMessage message, {
    required BuildContext context,
  }) {
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
          Expanded(
              child: Text(message.message,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: Colors.white,
                  )))
        ]));
  }

  static const TextStyle labelStyle =
      TextStyle(fontWeight: FontWeight.w200, color: Colors.white);
  static const TextStyle valueStyle =
      TextStyle(fontWeight: FontWeight.w600, color: Colors.white);
  static const EdgeInsets itemPadding =
      EdgeInsets.only(left: 5, top: 5, bottom: 5);
}
