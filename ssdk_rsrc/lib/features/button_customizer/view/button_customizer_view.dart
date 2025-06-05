import 'package:flutter/material.dart';
import '../../../widgets/button_customizer.dart';
import '../../../models/button_params.dart';
import '../../../utils/custom_button_funcs.dart';
import '../presenter/button_customizer_presenter.dart';

class ButtonCustomizerView extends StatefulWidget {
  const ButtonCustomizerView({super.key});

  @override
  State<ButtonCustomizerView> createState() => _ButtonCustomizerViewState();
}

class _ButtonCustomizerViewState extends State<ButtonCustomizerView> {
  late final ButtonCustomizerPresenter presenter;

  @override
  void initState() {
    super.initState();
    presenter = ButtonCustomizerPresenter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Button Customizer')),
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: createCustomButton(
                params: presenter.params,
                text: 'Custom Button',
                onPressed: () => debugPrint('Button Pressed!'),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, controller) {
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
                  controller: controller,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ButtonCustomizer(
                          initialParams: presenter.params,
                          onParamsChanged: (newParams) {
                            setState(() {
                              presenter.update(newParams);
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () => presenter.showParams(context),
                          child: const Text('Show & Export Parameters'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            await presenter.importParams(context, () => setState(() {}));
                          },
                          child: const Text('Import JSON Data'),
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
