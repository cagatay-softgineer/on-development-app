import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:pomodoro/models/button_params.dart';

/// Formats the [ButtonParams] as a pretty-printed JSON string.
String formatParamsAsJson(ButtonParams params) {
  final paramsMap = {
    "backgroundColor": params.backgroundColor.toString(),
    "textColor": params.textColor.toString(),
    "borderRadius": params.borderRadius,
    "padding": params.padding.toString(),
    "elevation": params.elevation,
    "buttonWidth": params.buttonWidth,
    "buttonHeight": params.buttonHeight,
    "borderColor": params.borderColor.toString(),
    "letterSpacing": params.letterSpacing,
    "blurAmount": params.blurAmount,
    "useGradient": params.useGradient,
    "gradientStartColor": params.gradientStartColor.toString(),
    "gradientEndColor": params.gradientEndColor.toString(),
    "leadingIcon": params.leadingIcon?.toString() ?? "None",
    "trailingIcon": params.trailingIcon?.toString() ?? "None",
    "textAlign": params.textAlign.toString(),
    "isEnabled": params.isEnabled,
    "shape": params.shape.toString(),
    "shadowColor": params.shadowColor.toString(),
    "shadowOffset": params.shadowOffset.toString(),
    "isLoading": params.isLoading,
    "fontFamily": params.fontFamily,
  };
  return const JsonEncoder.withIndent("  ").convert(paramsMap);
}

/// Creates a custom button widget based on the given [ButtonParams].
Widget createCustomButton({
  required ButtonParams params,
  required String text,
  required VoidCallback onPressed,
}) {
  return Container(
    width: params.buttonWidth,
    height: params.buttonHeight,
    decoration: BoxDecoration(
      gradient: params.useGradient
          ? LinearGradient(
              colors: [
                params.gradientStartColor,
                params.gradientEndColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: !params.useGradient ? params.backgroundColor : null,
      borderRadius: params.shape == BoxShape.rectangle
          ? BorderRadius.circular(params.borderRadius)
          : null,
      boxShadow: [
        BoxShadow(
          color: params.shadowColor,
          offset: params.shadowOffset,
          blurRadius: params.elevation,
        ),
      ],
      shape: params.shape,
    ),
    child: ElevatedButton(
      onPressed: params.isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        elevation: 0, // Avoid double shadows when using BoxShadow
        padding: params.padding,
        shape: params.shape == BoxShape.circle
            ? const CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(params.borderRadius),
              ),
        side: BorderSide(
          color: params.borderColor,
          width: params.letterSpacing,
        ),
        backgroundColor: Colors.transparent,
      ),
      child: params.isLoading
          ? CircularProgressIndicator(
              color: params.textColor,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (params.leadingIcon != null)
                  Icon(
                    params.leadingIcon,
                    color: params.textColor,
                  ),
                if (params.leadingIcon != null) const SizedBox(width: 8),
                Text(
                  text,
                  textAlign: params.textAlign,
                  style: params.textStyle.copyWith(
                    color: params.textColor,
                    fontFamily: params.fontFamily,
                  ),
                ),
                if (params.trailingIcon != null) const SizedBox(width: 8),
                if (params.trailingIcon != null)
                  Icon(
                    params.trailingIcon,
                    color: params.textColor,
                  ),
              ],
            ),
    ),
  );
}

/// Shows a dialog to import JSON data for button parameters. When JSON is successfully parsed,
/// [onParamsChanged] is called with the new [ButtonParams].
Future<void> importJsonFromTextBox({
  required BuildContext context,
  required Function(ButtonParams) onParamsChanged,
}) async {
  final TextEditingController jsonController = TextEditingController();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Paste JSON Data"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Paste the JSON data below to import button parameters:",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: jsonController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Paste your JSON here...",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog without action
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final jsonString = jsonController.text;
                final importedParams = ButtonParams.fromJson(jsonString);
                onParamsChanged(importedParams);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Button parameters imported successfully!"),
                  ),
                );
                Navigator.of(context).pop(); // Close the dialog
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to import JSON: $e")),
                );
              }
            },
            child: const Text("Import"),
          ),
        ],
      );
    },
  );
}

/// Shows a dialog that displays the current button parameters in JSON format.
/// The JSON can be copied to the clipboard.
void showParamsDialog({
  required BuildContext context,
  required ButtonParams params,
}) {
  final paramsJson = formatParamsAsJson(params);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Current Button Parameters"),
        content: SingleChildScrollView(
          child: Text(
            paramsJson,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paramsJson));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Parameters copied to clipboard!"),
                ),
              );
            },
            child: const Text("Copy to Clipboard"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}
