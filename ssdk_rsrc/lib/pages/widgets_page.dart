import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';

/// A small helper for section headings
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

class WidgetShowroomPage extends StatelessWidget {
  const WidgetShowroomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Widget Showroom',style: TextStyle(color: Youtube.white)),backgroundColor: Youtube.almostBlack,),
      backgroundColor: Youtube.almostBlack,
      body: Stack(
        children: [
          // — Directly use your MeshGradient widget as the full-screen background —
          // Positioned.fill(child: GradientPallette.instagram),

          // — The scrollable content overlay —
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle('Buttons'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                    // TextButton(onPressed: () {}, child: const Text('Text')),
                    // OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                    // IconButton(
                    //   onPressed: () {},
                    //   icon: const Icon(Icons.thumb_up),
                    //   color: Colors.white,
                    // ),
                    // FloatingActionButton.small(
                    //   onPressed: () {},
                    //   child: const Icon(Icons.add),
                    // ),
                  ],
                ),

                const _SectionTitle('Text Styles'),
                // const Text('Headline 1', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                // const Text('Headline 2', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white70)),
                // const Text('Body text – lorem ipsum dolor sit amet.', style: TextStyle(fontSize: 16, color: Colors.white60)),

                const _SectionTitle('Form Fields & Toggles'),
                // TextField(
                //   decoration: InputDecoration(
                //     filled: true,
                //     fillColor: Colors.white,
                //     hintText: 'Enter some text…',
                //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                //   ),
                // ),
                // const SizedBox(height: 12),
                // CheckboxListTile(
                //   value: true,
                //   onChanged: (_) {},
                //   title: const Text('Checkbox option', style: TextStyle(color: Colors.white)),
                //   controlAffinity: ListTileControlAffinity.leading,
                // ),
                // SwitchListTile(
                //   value: false,
                //   onChanged: (_) {},
                //   title: const Text('Switch option', style: TextStyle(color: Colors.white)),
                // ),
                // Padding(
                //   padding: const EdgeInsets.symmetric(vertical: 12),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text('Slider', style: TextStyle(color: Colors.white)),
                //       Slider(value: 0.5, onChanged: (_) {}),
                //     ],
                //   ),
                // ),

                const _SectionTitle('Cards & Lists'),
                // Card(
                //   color: Colors.white.withOpacity(0.9),
                //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                //   child: ListTile(
                //     leading: const Icon(Icons.account_circle),
                //     title: const Text('ListTile in a Card'),
                //     subtitle: const Text('Subtitle text'),
                //     trailing: const Icon(Icons.chevron_right),
                //   ),
                // ),

                const _SectionTitle('MeshGradient Demo'),
                SizedBox(
                  height: 400,
                  child: GradientPallette.instagram,
                ),
                SizedBox(
                  height: 400,
                  child: GradientPallette.animatedInstagram,
                ),
                SizedBox(
                  height: 400,
                  child: GradientPallette.animatedTest,
                ),
                SizedBox(
                  height: 400,
                  child: GradientPallette.test,
                ),
                Container(
                  height: 400,
                  decoration: BoxDecoration(gradient:  GradientPallette.goldenOrder)
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
