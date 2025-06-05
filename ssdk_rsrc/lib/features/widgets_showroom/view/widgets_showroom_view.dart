import 'package:flutter/material.dart';
import '../../../styles/color_palette.dart';
import '../presenter/widgets_showroom_presenter.dart';

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class WidgetsShowroomView extends StatefulWidget {
  const WidgetsShowroomView({Key? key}) : super(key: key);

  @override
  State<WidgetsShowroomView> createState() => _WidgetsShowroomViewState();
}

class _WidgetsShowroomViewState extends State<WidgetsShowroomView> {
  late final WidgetsShowroomPresenter presenter;

  @override
  void initState() {
    super.initState();
    presenter = WidgetsShowroomPresenter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Showroom', style: TextStyle(color: Youtube.white)),
        backgroundColor: Youtube.almostBlack,
      ),
      backgroundColor: Youtube.almostBlack,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _SectionTitle('Buttons'),
                Wrap(spacing: 12, runSpacing: 12, children: []),
                _SectionTitle('Text Styles'),
                _SectionTitle('Form Fields & Toggles'),
                _SectionTitle('Cards & Lists'),
                _SectionTitle('MeshGradient Demo'),
                SizedBox(height: 400, child: GradientPallette.instagram),
                SizedBox(height: 400, child: GradientPallette.animatedInstagram),
                SizedBox(height: 400, child: GradientPallette.animatedTest),
                SizedBox(height: 400, child: GradientPallette.test),
                SizedBox(height: 400, child: DecoratedBox(decoration: BoxDecoration(gradient: GradientPallette.goldenOrder))),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
