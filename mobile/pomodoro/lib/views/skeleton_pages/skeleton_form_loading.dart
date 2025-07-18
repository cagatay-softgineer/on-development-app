// lib/views/skeleton_pages/skeleton_form_loading.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/viewmodels/skeleton_viewmodel.dart';
import 'package:pomodoro/widgets/loading/skeleton/skeleton_form_loading.dart';

class SkeletonFormPage extends StatelessWidget {
  const SkeletonFormPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SkeletonViewModel()..load(),
      child: Consumer<SkeletonViewModel>(
        builder: (_, vm, __) => Scaffold(
          appBar: AppBar(title: const Text('Form Loading')),
          body: vm.isLoading
            ? const SkeletonFormLoading()
            : const Center(child: Text('Form Loaded')),
        ),
      ),
    );
  }
}