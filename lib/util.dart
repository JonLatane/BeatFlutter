import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/rendering.dart';

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

var uuid = Uuid();
extension ContextUtils on BuildContext {
  bool get isTablet => MediaQuery.of(this).size.width > 500 && MediaQuery.of(this).size.height > 500;
  bool get isPhone => !isTablet;
  bool get isTabletOrLandscapey => MediaQuery.of(this).size.width > 500;
  bool get isLandscape => MediaQuery.of(this).size.width > MediaQuery.of(this).size.height;
  bool get isPortrait => !isLandscape;
}

class MethodCache<KeyType, ResultType> {
  bool enable = true;
  Map<KeyType, ResultType> _data = Map();
  ResultType putIfAbsent(KeyType key, ResultType Function() computation) {
    if(!enable) {
      return computation();
    }
    return _data.putIfAbsent(key, () => computation());
  }
  clear() { _data.clear(); }
}

/// Wrapper around [List<dynamic>] that calculates == and hashCode.
class ArgumentList {
  final List<dynamic> arguments;

  ArgumentList(this.arguments);

  @override bool operator ==(other) => other is ArgumentList && arguments.length == other.arguments.length
    && !arguments.asMap().entries.any((entry) => other.arguments[entry.key] != entry.value);
  @override int get hashCode {
    int result;
    arguments.forEach((arg) {
      if(result == null) {
        result = arg.hashCode;
      } else {
        result = result ^ arg.hashCode;
      }
    });
    return result ?? 0;
  }
}

class IncrementableValue extends StatelessWidget {
  final Function onIncrement;
  final Function onDecrement;
  final String value;
  final TextStyle textStyle;
  final double valueWidth;
  final VoidCallback onValuePressed;

  const IncrementableValue({Key key, this.onIncrement, this.onDecrement, this.value, this.textStyle, this.valueWidth = 45, this.onValuePressed,}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Row(children:[
      Container(
        width: 25,
        child: RaisedButton(
          child: Icon(Icons.arrow_upward),
          onPressed: onIncrement,
          padding: EdgeInsets.all(0),)),
      Container(
        width: valueWidth,
        child: RaisedButton(onPressed: onValuePressed, padding: EdgeInsets.all(0),
          child: Text(value ?? "null", style: textStyle ?? TextStyle(color: Colors.white),))),
      Container(
        width: 25,
        child: RaisedButton(
          child: Icon(Icons.arrow_downward),
          onPressed: onDecrement,
          padding: EdgeInsets.all(0),)),
    ]);
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
  _CustomRenderSliverToBoxAdapter createRenderObject(BuildContext context)
  => _CustomRenderSliverToBoxAdapter(setVisibleRect: setVisibleRect);
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
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = new SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
    setChildParentData(child, constraints, geometry);

    // Expose geometry
    setVisibleRect(Rect.fromLTWH(constraints.scrollOffset, 0.0, geometry.paintExtent, child.size.height));
  }

}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
    <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
    map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));

  E maxBy(int Function(E) valueFunction) => (isEmpty) ? null : reduce((value, element) {
    if(value == null) {
      return element;
    }
    if(valueFunction(element) > valueFunction(value)) {
      return element;
    }
    return value;
  });

  E minBy(int Function(E) valueFunction) => reduce((value, element) {
    if(value == null) {
      return element;
    }
    if(valueFunction(element) < valueFunction(value)) {
      return element;
    }
    return value;
  });

  Iterable<Iterable<E>> chunked(int chunkSize) {
    return _chunkIterable(this, chunkSize);
  }
}

Iterable<Iterable<E>> _chunkIterable<E>(Iterable<E> iterable, int chunkSize) {
  if(iterable.isEmpty) {
    return [];
  }
  return [iterable.take(chunkSize)]
      ..addAll(
        _chunkIterable(iterable.skip(chunkSize).toList(), chunkSize)
      );
}

extension FancyIterable on Iterable<int> {
  int get maximum => reduce(max);

  int get minimum => reduce(min);
}