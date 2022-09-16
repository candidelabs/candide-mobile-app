import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class SharedAxisRoute<T> extends PageRoute<T> {
  SharedAxisRoute({this.duration = const Duration(milliseconds: 450), required this.builder, this.transitionType=SharedAxisTransitionType.vertical}) : super();

  final WidgetBuilder builder;
  final SharedAxisTransitionType transitionType;
  final Duration duration;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  String get barrierLabel => "";

  @override
  Duration get transitionDuration => duration;

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.transparent;


  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: transitionType,
      child: child,
    );
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

}