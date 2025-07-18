// lib/views/skeleton_pages/skeleton_grid_loading.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/viewmodels/skeleton_viewmodel.dart';
import 'package:pomodoro/widgets/loading/skeleton/skeleton_grid_loading.dart';

class SkeletonGridPage extends StatelessWidget {
  const SkeletonGridPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SkeletonViewModel()..load(),
      child: Consumer<SkeletonViewModel>(
        builder: (_, vm, __) => Scaffold(
          appBar: AppBar(title: const Text('Grid Loading')),
          body: vm.isLoading
            ? const SkeletonGridLoading()
            : GridView.count(
                crossAxisCount: 2,
                children: List.generate(6, (i) => Center(child: Text('Item \$i'))),
              ),
        ),
      ),
    );
  }
}