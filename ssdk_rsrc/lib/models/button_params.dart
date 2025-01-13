import 'package:flutter/material.dart';
import 'dart:convert';
import '/models/all_icons.dart';

class ButtonParams {
  // Private fields
  Color _backgroundColor;
  Color _textColor;
  double _borderRadius;
  EdgeInsetsGeometry _padding;
  TextStyle _textStyle;
  double _elevation;
  double _buttonWidth;
  double _buttonHeight;
  Color _borderColor;
  double _letterSpacing;
  double _blurAmount;
  bool _useGradient;
  Color _gradientStartColor;
  Color _gradientEndColor;
  IconData? _leadingIcon;
  IconData? _trailingIcon;
  TextAlign _textAlign;
  bool _isEnabled;
  BoxShape _shape;
  Color _hoverColor;
  Color _focusColor;
  Color _shadowColor;
  Offset _shadowOffset;
  bool _isLoading;
  String _fontFamily;
  double _backgroundAlpha;
  double _iconSize;

  // Constructor with default values
  ButtonParams({
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    double borderRadius = 8.0,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    TextStyle textStyle =
        const TextStyle(fontSize: 16, color: Colors.white),
    double elevation = 4.0,
    double buttonWidth = 200.0,
    double buttonHeight = 50.0,
    Color borderColor = Colors.transparent,
    double letterSpacing = 0.0,
    double blurAmount = 0.0,
    bool useGradient = false,
    Color gradientStartColor = Colors.blue,
    Color gradientEndColor = Colors.purple,
    IconData? leadingIcon,
    IconData? trailingIcon,
    TextAlign textAlign = TextAlign.center,
    bool isEnabled = true,
    BoxShape shape = BoxShape.rectangle,
    Color hoverColor = Colors.blueAccent,
    Color focusColor = Colors.lightBlueAccent,
    Color shadowColor = Colors.black26,
    Offset shadowOffset = const Offset(2, 2),
    bool isLoading = false,
    String fontFamily = 'Roboto',
    double backgroundAlpha = 1.0, // Default opacity
    double iconSize = 12,
  })  : _backgroundColor = backgroundColor,
        _textColor = textColor,
        _borderRadius = borderRadius,
        _padding = padding,
        _textStyle = textStyle,
        _elevation = elevation,
        _buttonWidth = buttonWidth,
        _buttonHeight = buttonHeight,
        _borderColor = borderColor,
        _letterSpacing = letterSpacing,
        _blurAmount = blurAmount,
        _useGradient = useGradient,
        _gradientStartColor = gradientStartColor,
        _gradientEndColor = gradientEndColor,
        _leadingIcon = leadingIcon,
        _trailingIcon = trailingIcon,
        _textAlign = textAlign,
        _isEnabled = isEnabled,
        _shape = shape,
        _hoverColor = hoverColor,
        _focusColor = focusColor,
        _shadowColor = shadowColor,
        _shadowOffset = shadowOffset,
        _isLoading = isLoading,
        _fontFamily = fontFamily,
        _backgroundAlpha = backgroundAlpha,
        _iconSize = iconSize;

  // ==================== Getters ====================

  Color get backgroundColor => _backgroundColor;
  Color get textColor => _textColor;
  double get borderRadius => _borderRadius;
  EdgeInsetsGeometry get padding => _padding;
  TextStyle get textStyle => _textStyle;
  double get elevation => _elevation;
  double get buttonWidth => _buttonWidth;
  double get buttonHeight => _buttonHeight;
  Color get borderColor => _borderColor;
  double get letterSpacing => _letterSpacing;
  double get blurAmount => _blurAmount;
  bool get useGradient => _useGradient;
  Color get gradientStartColor => _gradientStartColor;
  Color get gradientEndColor => _gradientEndColor;
  IconData? get leadingIcon => _leadingIcon;
  IconData? get trailingIcon => _trailingIcon;
  TextAlign get textAlign => _textAlign;
  bool get isEnabled => _isEnabled;
  BoxShape get shape => _shape;
  Color get hoverColor => _hoverColor;
  Color get focusColor => _focusColor;
  Color get shadowColor => _shadowColor;
  Offset get shadowOffset => _shadowOffset;
  bool get isLoading => _isLoading;
  String get fontFamily => _fontFamily;
  double get backgroundAlpha => _backgroundAlpha;
  double get iconSize => _iconSize;

  // ==================== Setters ====================

  set backgroundColor(Color value) {
    _backgroundColor = value;
  }

  set textColor(Color value) {
    _textColor = value;
  }

  set borderRadius(double value) {
    _borderRadius = value;
  }

  set padding(EdgeInsetsGeometry value) {
    _padding = value;
  }

  set textStyle(TextStyle value) {
    _textStyle = value;
  }

  set elevation(double value) {
    _elevation = value;
  }

  set buttonWidth(double value) {
    _buttonWidth = value;
  }

  set buttonHeight(double value) {
    _buttonHeight = value;
  }

  set borderColor(Color value) {
    _borderColor = value;
  }

  set letterSpacing(double value) {
    _letterSpacing = value;
  }

  set blurAmount(double value) {
    _blurAmount = value;
  }

  set useGradient(bool value) {
    _useGradient = value;
  }

  set gradientStartColor(Color value) {
    _gradientStartColor = value;
  }

  set gradientEndColor(Color value) {
    _gradientEndColor = value;
  }

  set leadingIcon(IconData? value) {
    _leadingIcon = value;
  }

  set trailingIcon(IconData? value) {
    _trailingIcon = value;
  }

  set textAlign(TextAlign value) {
    _textAlign = value;
  }

  set isEnabled(bool value) {
    _isEnabled = value;
  }

  set shape(BoxShape value) {
    _shape = value;
  }

  set hoverColor(Color value) {
    _hoverColor = value;
  }

  set focusColor(Color value) {
    _focusColor = value;
  }

  set shadowColor(Color value) {
    _shadowColor = value;
  }

  set shadowOffset(Offset value) {
    _shadowOffset = value;
  }

  set isLoading(bool value) {
    _isLoading = value;
  }

  set fontFamily(String value) {
    _fontFamily = value;
  }

  set backgroundAlpha(double value) {
    // Ensure alpha is between 0.0 and 1.0
    if (value < 0.0) {
      _backgroundAlpha = 0.0;
    } else if (value > 1.0) {
      _backgroundAlpha = 1.0;
    } else {
      _backgroundAlpha = value;
    }
  }

  set iconSize(double value) {
    _iconSize = value;
  }

  // ==================== JSON Serialization ====================

  /// Converts the current instance to a JSON string
  String toJson() {
    final Map<String, dynamic> jsonData = {
      "backgroundColor": _backgroundColor.value.toString(),
      "textColor": _textColor.value.toString(),
      "borderRadius": _borderRadius,
      "padding": _padding.toString(),
      "textStyle": _textStyle.toString(),
      "elevation": _elevation,
      "buttonWidth": _buttonWidth,
      "buttonHeight": _buttonHeight,
      "borderColor": _borderColor.value.toString(),
      "letterSpacing": _letterSpacing,
      "blurAmount": _blurAmount,
      "useGradient": _useGradient,
      "gradientStartColor": _gradientStartColor.value.toString(),
      "gradientEndColor": _gradientEndColor.value.toString(),
      "leadingIcon": _leadingIcon?.codePoint.toString() ?? "None",
      "trailingIcon": _trailingIcon?.codePoint.toString() ?? "None",
      "textAlign": _textAlign.toString(),
      "isEnabled": _isEnabled,
      "shape": _shape.toString(),
      "hoverColor": _hoverColor.value.toString(),
      "focusColor": _focusColor.value.toString(),
      "shadowColor": _shadowColor.value.toString(),
      "shadowOffset": _shadowOffset.toString(),
      "isLoading": _isLoading,
      "fontFamily": _fontFamily,
      "backgroundAlpha": _backgroundAlpha,
    };
    return const JsonEncoder.withIndent("  ").convert(jsonData);
  }

  /// Factory method to create a ButtonParams object from a JSON string
  factory ButtonParams.fromJson(String jsonString) {
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    return ButtonParams(
      backgroundColor: _parseColor(jsonData['backgroundColor']),
      textColor: _parseColor(jsonData['textColor']),
      borderRadius: (jsonData['borderRadius'] as num).toDouble(),
      padding: _parseEdgeInsets(jsonData['padding']),
      textStyle: _parseTextStyle(jsonData['textStyle']),
      elevation: (jsonData['elevation'] as num).toDouble(),
      buttonWidth: (jsonData['buttonWidth'] as num).toDouble(),
      buttonHeight: (jsonData['buttonHeight'] as num).toDouble(),
      borderColor: _parseColor(jsonData['borderColor']),
      letterSpacing: (jsonData['letterSpacing'] as num).toDouble(),
      blurAmount: (jsonData['blurAmount'] as num).toDouble(),
      useGradient: jsonData['useGradient'] as bool,
      gradientStartColor: _parseColor(jsonData['gradientStartColor']),
      gradientEndColor: _parseColor(jsonData['gradientEndColor']),
      leadingIcon: _parseIconData(jsonData['leadingIcon']),
      trailingIcon: _parseIconData(jsonData['trailingIcon']),
      textAlign: _parseTextAlign(jsonData['textAlign']),
      isEnabled: jsonData['isEnabled'] as bool,
      shape: _parseBoxShape(jsonData['shape']),
      hoverColor: _parseColor(jsonData['hoverColor']),
      focusColor: _parseColor(jsonData['focusColor']),
      shadowColor: _parseColor(jsonData['shadowColor']),
      shadowOffset: _parseOffset(jsonData['shadowOffset']),
      isLoading: jsonData['isLoading'] as bool,
      fontFamily: jsonData['fontFamily'] as String,
      backgroundAlpha : (jsonData['backgroundAlpha'] as num).toDouble(),
      iconSize : (jsonData['iconSize'] as num).toDouble(),
    );
  }

  // ==================== Named Constructor ====================

  /// Named constructor to create a ButtonParams object from a Map
  ButtonParams.fromMap(Map<String, dynamic> jsonData)
      : _backgroundColor = _parseColor(jsonData['backgroundColor']),
        _textColor = _parseColor(jsonData['textColor']),
        _borderRadius = (jsonData['borderRadius'] as num).toDouble(),
        _padding = _parseEdgeInsets(jsonData['padding']),
        _textStyle = _parseTextStyle(jsonData['textStyle']),
        _elevation = (jsonData['elevation'] as num).toDouble(),
        _buttonWidth = (jsonData['buttonWidth'] as num).toDouble(),
        _buttonHeight = (jsonData['buttonHeight'] as num).toDouble(),
        _borderColor = _parseColor(jsonData['borderColor']),
        _letterSpacing = (jsonData['letterSpacing'] as num).toDouble(),
        _blurAmount = (jsonData['blurAmount'] as num).toDouble(),
        _useGradient = jsonData['useGradient'] as bool,
        _gradientStartColor = _parseColor(jsonData['gradientStartColor']),
        _gradientEndColor = _parseColor(jsonData['gradientEndColor']),
        _leadingIcon = _parseIconData(jsonData['leadingIcon']),
        _trailingIcon = _parseIconData(jsonData['trailingIcon']),
        _textAlign = _parseTextAlign(jsonData['textAlign']),
        _isEnabled = jsonData['isEnabled'] as bool,
        _shape = _parseBoxShape(jsonData['shape']),
        _hoverColor = _parseColor(jsonData['hoverColor']),
        _focusColor = _parseColor(jsonData['focusColor']),
        _shadowColor = _parseColor(jsonData['shadowColor']),
        _shadowOffset = _parseOffset(jsonData['shadowOffset']),
        _isLoading = jsonData['isLoading'] as bool,
        _fontFamily = jsonData['fontFamily'] as String,
        _backgroundAlpha = (jsonData['backgroundAlpha'] as num).toDouble(),
        _iconSize = (jsonData['iconSize'] as num).toDouble();

  // ==================== Helper Methods ====================

  static Color _parseColor(String colorString) {
    final regex = RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)');
    final match = regex.firstMatch(colorString);
    if (match != null) {
      final hexColor = match.group(1)!;
      return Color(int.parse(hexColor, radix: 16));
    }
    return Colors.transparent;
  }

  static EdgeInsetsGeometry _parseEdgeInsets(String paddingString) {
    final regex = RegExp(
        r'EdgeInsets\((\d+.?\d*), (\d+.?\d*), (\d+.?\d*), (\d+.?\d*)\)');
    final match = regex.firstMatch(paddingString);
    if (match != null) {
      return EdgeInsets.fromLTRB(
        double.parse(match.group(1)!),
        double.parse(match.group(2)!),
        double.parse(match.group(3)!),
        double.parse(match.group(4)!),
      );
    }
    return EdgeInsets.zero;
  }

  static TextStyle _parseTextStyle(String textStyleString) {
    // Basic parsing for fontSize and color
    final regex = RegExp(
        r'TextStyle\(fontSize: (\d+.?\d*), color: Color\(0x([0-9A-Fa-f]{8})\)\)');
    final match = regex.firstMatch(textStyleString);
    if (match != null) {
      final fontSize = double.parse(match.group(1)!);
      final color = Color(int.parse(match.group(2)!, radix: 16));
      return TextStyle(fontSize: fontSize, color: color);
    }
    return const TextStyle();
  }

  static Offset _parseOffset(String offsetString) {
    final regex = RegExp(r'Offset\((\d+.?\d*), (\d+.?\d*)\)');
    final match = regex.firstMatch(offsetString);
    if (match != null) {
      return Offset(
        double.parse(match.group(1)!),
        double.parse(match.group(2)!),
      );
    }
    return Offset.zero;
  }

  
  static IconData? _parseIconData(String iconString) {
    try {
      if (iconString == 'None' || iconString.trim().isEmpty) {
        return null;
      }
      return iconMapping[iconString] ?? Icons.help; // Return Icons.help if not found
    } catch (e) {
      // Log the error for debugging purposes
      //print('Error parsing icon: $e');
      return Icons.help; // Return a default icon in case of error
    }
  }

  static TextAlign _parseTextAlign(String textAlignString) {
    switch (textAlignString) {
      case 'TextAlign.center':
        return TextAlign.center;
      case 'TextAlign.left':
        return TextAlign.left;
      case 'TextAlign.right':
        return TextAlign.right;
      default:
        return TextAlign.start;
    }
  }

  static BoxShape _parseBoxShape(String shapeString) {
    return shapeString == 'BoxShape.circle' ? BoxShape.circle : BoxShape.rectangle;
  }
}
