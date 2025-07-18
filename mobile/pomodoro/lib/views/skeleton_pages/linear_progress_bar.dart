// lib/views/skeleton_pages/linear_progress_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/viewmodels/skeleton_viewmodel.dart';
import 'package:pomodoro/widgets/loading/linear_progress_bar.dart';

class LinearProgressPage extends StatelessWidget {
  const LinearProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SkeletonViewModel()..load(),
      child: Consumer<SkeletonViewModel>(
        builder: (_, vm, __) => Scaffold(
          appBar: AppBar(title: const Text('Linear Progress')),
          body: vm.isLoading
            ? const LinearProgressBar()
            : const Center(child: Text('Progress Complete')),
        ),
      ),
    );
  }
}