import 'dart:ui';
import 'package:ssdk_rsrc/models/button_params.dart';

class LinkedApp {
  final String name; // Immutable property
  final Color appColor; // Now immutable!
  String buttonText;
  String userPic;
  String appPic;
  String userDisplayName;
  ButtonParams appButtonParams;
  bool isLinked;

  LinkedApp({
    required this.name,          // Name must be provided
    required this.appColor,      // Color must be provided and is final
    this.buttonText = "",
    this.userPic = "",
    this.appPic = "",
    this.userDisplayName = "Checking...",
    ButtonParams? appButtonParams,
    this.isLinked = false,
  }) : appButtonParams = appButtonParams ?? ButtonParams();
}
