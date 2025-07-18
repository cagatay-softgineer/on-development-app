// lib/views/skeleton_pages/skeleton_list_loading.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/viewmodels/skeleton_viewmodel.dart';
import 'package:pomodoro/widgets/loading/skeleton/skeleton_list_loading.dart';

class SkeletonListPage extends StatelessWidget {
  const SkeletonListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SkeletonViewModel()..load(),
      child: Consumer<SkeletonViewModel>(
        builder: (_, vm, __) => Scaffold(
          appBar: AppBar(title: const Text('List Loading')),
          body: vm.isLoading
            ? const SkeletonListLoading()
            : ListView.separated(
                itemCount: 10,
                separatorBuilder: (_,__) => const Divider(),
                itemBuilder: (_, i) => ListTile(title: Text('Row \$i')),
              ),
        ),
      ),
    );
  }
}