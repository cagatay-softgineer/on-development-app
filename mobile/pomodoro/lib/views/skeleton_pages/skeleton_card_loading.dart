// lib/views/skeleton_pages/skeleton_card_loading.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/viewmodels/skeleton_viewmodel.dart';
import 'package:pomodoro/widgets/loading/skeleton/skeleton_card_loading.dart';

class SkeletonCardPage extends StatelessWidget {
  const SkeletonCardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SkeletonViewModel()..load(),
      child: Consumer<SkeletonViewModel>(
        builder: (_, vm, __) => Scaffold(
          appBar: AppBar(title: const Text('Card Loading')),
          body: vm.isLoading
            ? const SkeletonCardLoading()
            : const Center(child: Text('Cards Loaded')),
        ),
      ),
    );
  }
}