import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/widgets/button_customizer.dart';
import 'package:ssdk_rsrc/models/button_params.dart';
import 'package:ssdk_rsrc/utils/custom_button_funcs.dart'; // Import the utilities

class ButtonCustomizerApp extends StatefulWidget {
  const ButtonCustomizerApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ButtonCustomizerAppState createState() => _ButtonCustomizerAppState();
}

class _ButtonCustomizerAppState extends State<ButtonCustomizerApp> {
  ButtonParams _buttonParams = ButtonParams();

  void _updateButtonParams(ButtonParams newParams) {
    setState(() {
      _buttonParams = newParams;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Button Customizer')),
      body: Stack(
        children: [
          // Button Preview Section with spacing
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25, // Adjust vertical position
            left: 0,
            right: 0,
            child: Center(
              child: createCustomButton(
                params: _buttonParams,
                text: "Custom Button",
                onPressed: () => debugPrint("Button Pressed!"),
              ),
            ),
          ),

          // Sliding Panel for Button Customization
          DraggableScrollableSheet(
            initialChildSize: 0.4, // Initial size of the panel
            minChildSize: 0.2,     // Minimum size of the panel
            maxChildSize: 0.9,     // Maximum size of the panel
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
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
                          onPressed: () {
                            showParamsDialog(
                              context: context,
                              params: _buttonParams,
                            );
                          },
                          child: const Text("Show & Export Parameters"),
                        ),
                      ),
                      // Button to import JSON file
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            await importJsonFromTextBox(
                              context: context,
                              onParamsChanged: (importedParams) {
                                _updateButtonParams(importedParams);
                              },
                            );
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
