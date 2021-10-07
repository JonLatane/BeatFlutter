import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

launchURL(
  String url, {
  bool forceSafariVC,
  bool forceWebView,
  bool enableJavaScript,
  bool enableDomStorage,
  bool universalLinksOnly,
  Map<String, String> headers,
  Brightness statusBarBrightness,
  String webOnlyWindowName,
}) async {
  if (await canLaunch(url)) {
    await launch(
      url,
      forceSafariVC: forceSafariVC,
      forceWebView: forceWebView,
      enableJavaScript: enableJavaScript,
      enableDomStorage: enableDomStorage,
      universalLinksOnly: universalLinksOnly,
      headers: headers,
      statusBarBrightness: statusBarBrightness,
      webOnlyWindowName: webOnlyWindowName,
    );
  } else {
    throw 'Could not launch $url';
  }
}

extension ContextUtils on BuildContext {
  bool get isTablet =>
      MediaQuery.of(this).size.width > 550 &&
      MediaQuery.of(this).size.height > 500;

  bool get isPhone => !isTablet;

  bool get isTabletOrLandscapey => MediaQuery.of(this).size.width > 550;

  bool get isLandscape =>
      MediaQuery.of(this).size.width > MediaQuery.of(this).size.height;

  bool get isPortrait => !isLandscape;

  bool get isLandscapePhone => isLandscape && isPhone;

  bool get isPortraitPhone => isPortrait && isPhone;
}

extension Capitalize on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

Future<ui.Image> loadUiImage(String imageAssetPath) async {
  final ByteData data = await rootBundle.load(imageAssetPath);
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

class CustomSliverToBoxAdapter extends SingleChildRenderObjectWidget {
  final Function(Rect) setVisibleRect;

  const CustomSliverToBoxAdapter({
    this.setVisibleRect,
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  _CustomRenderSliverToBoxAdapter createRenderObject(BuildContext context) =>
      _CustomRenderSliverToBoxAdapter(setVisibleRect: setVisibleRect);
}

class _CustomRenderSliverToBoxAdapter extends RenderSliverSingleBoxAdapter {
  final Function(Rect) setVisibleRect;

  _CustomRenderSliverToBoxAdapter({
    this.setVisibleRect,
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child.size.width;
        break;
      case Axis.vertical:
        childExtent = child.size.height;
        break;
    }
    assert(childExtent != null);
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = new SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
    setChildParentData(child, constraints, geometry);

    // Expose geometry
    setVisibleRect(Rect.fromLTWH(constraints.scrollOffset, 0.0,
        geometry.paintExtent, child.size.height));
  }
}
