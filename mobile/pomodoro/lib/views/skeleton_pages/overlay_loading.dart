// lib/views/skeleton_pages/overlay_loading.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/viewmodels/skeleton_viewmodel.dart';
import 'package:pomodoro/widgets/loading/overlay_loading.dart';

class OverlayLoadingPage extends StatelessWidget {
  const OverlayLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SkeletonViewModel()..load(),
      child: Consumer<SkeletonViewModel>(
        builder: (_, vm, __) => OverlayLoading(
          isLoading: vm.isLoading,
          child: Scaffold(
            appBar: AppBar(title: const Text('Overlay Loading')),
            body: const Center(child: Text('Main Content')),
          ),
        ),
      ),
    );
  }
}