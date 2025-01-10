import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard functionality
import 'dart:convert'; // For JSON conversion
import 'button_customizer.dart';

class ButtonCustomizerApp extends StatefulWidget {
  @override
  _ButtonCustomizerAppState createState() => _ButtonCustomizerAppState();
}

class _ButtonCustomizerAppState extends State<ButtonCustomizerApp> {
  ButtonParams _buttonParams = ButtonParams();

  void _updateButtonParams(ButtonParams newParams) {
    setState(() {
      _buttonParams = newParams;
    });
  }

  // Function to import JSON
  Future<void> _importJsonFromTextBox() async {
  TextEditingController jsonController = TextEditingController();

  showDialog(
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
                decoration: InputDecoration(
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
              Navigator.of(context).pop(); // Close dialog without doing anything
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final jsonString = jsonController.text;
                final importedParams = ButtonParams.fromJson(jsonString);

                setState(() {
                  _buttonParams = importedParams; // Update button parameters
                  _updateButtonParams(importedParams);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Button parameters imported successfully!")),
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

  // Function to show current parameter values
  void _showParamsDialog() {
    final paramsJson = _formatParamsAsJson(_buttonParams);

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
                  const SnackBar(content: Text("Parameters copied to clipboard!")),
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

  // Function to format parameters as JSON
  String _formatParamsAsJson(ButtonParams params) {
    final paramsMap = {
      "backgroundColor": params.backgroundColor.toString(),
      "textColor": params.textColor.toString(),
      "borderRadius": params.borderRadius,
      "padding": params.padding.toString(),
      "elevation": params.elevation,
      "buttonWidth": params.buttonWidth,
      "buttonHeight": params.buttonHeight,
      "borderColor": params.borderColor.toString(),
      "borderWidth": params.borderWidth,
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

  Widget _createButton(String text, VoidCallback onPressed) {
    return Container(
      width: _buttonParams.buttonWidth, // Dynamic width
      height: _buttonParams.buttonHeight, // Dynamic height
      decoration: BoxDecoration(
        // Use gradient if enabled
        gradient: _buttonParams.useGradient
            ? LinearGradient(
                colors: [
                  _buttonParams.gradientStartColor,
                  _buttonParams.gradientEndColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: !_buttonParams.useGradient
            ? _buttonParams.backgroundColor
            : null, // Default color if gradient is not used
        borderRadius: _buttonParams.shape == BoxShape.rectangle
            ? BorderRadius.circular(_buttonParams.borderRadius)
            : null,
        boxShadow: [
          BoxShadow(
            color: _buttonParams.shadowColor,
            offset: _buttonParams.shadowOffset,
            blurRadius: _buttonParams.elevation,
          ),
        ],
        shape: _buttonParams.shape,
      ),
      child: ElevatedButton(
        onPressed: _buttonParams.isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0, // Avoid double shadows when using BoxShadow
          padding: _buttonParams.padding,
          shape: _buttonParams.shape == BoxShape.circle
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_buttonParams.borderRadius),
                ),
          side: BorderSide(
            color: _buttonParams.borderColor,
            width: _buttonParams.borderWidth,
          ),
          backgroundColor: Colors.transparent, // Make background transparent
        ),
        child: _buttonParams.isLoading
            ? CircularProgressIndicator(
                color: _buttonParams.textColor,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_buttonParams.leadingIcon != null)
                    Icon(
                      _buttonParams.leadingIcon,
                      color: _buttonParams.textColor,
                    ),
                  if (_buttonParams.leadingIcon != null) const SizedBox(width: 8),
                  Text(
                    text,
                    textAlign: _buttonParams.textAlign,
                    style: _buttonParams.textStyle.copyWith(
                      color: _buttonParams.textColor,
                      fontFamily: _buttonParams.fontFamily,
                    ),
                  ),
                  if (_buttonParams.trailingIcon != null) const SizedBox(width: 8),
                  if (_buttonParams.trailingIcon != null)
                    Icon(
                      _buttonParams.trailingIcon,
                      color: _buttonParams.textColor,
                    ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Button Customizer')),
      body: Stack(
        children: [
          // Button Preview Section with spacing
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25, // Adjust the vertical position
            left: 0,
            right: 0,
            child: Center(
              child: _createButton(
                "Custom Button",
                () => print("Button Pressed!"),
              ),
            ),
          ),

          // Sliding Panel for Button Customization
          DraggableScrollableSheet(
  initialChildSize: 0.4, // Initial size of the panel
  minChildSize: 0.2, // Minimum size of the panel
  maxChildSize: 0.9, // Maximum size of the panel
  builder: (BuildContext context, ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            // Button Customizer Widget
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ButtonCustomizer(
                initialParams: _buttonParams,
                onParamsChanged: _updateButtonParams,
              ),
            ),
            // Button to show/export current params
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _showParamsDialog,
                child: const Text("Show & Export Parameters"),
              ),
            ),
            // Button to import JSON file
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  await _importJsonFromTextBox();
                  setState(() {
                    // Rebuild sliders with imported JSON values
                  });
                },
                child: const Text("Import JSON Data"),
              ),
            ),
          ],
        ),
      ),
    );
  },
),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: ButtonCustomizerApp()));
