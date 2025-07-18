// lib/views/skeleton_pages/pull_to_refresh_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/viewmodels/skeleton_viewmodel.dart';
import 'package:pomodoro/widgets/loading/skeleton/skeleton_list_loading.dart';

class PullToRefreshPage extends StatelessWidget {
  const PullToRefreshPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SkeletonViewModel()..load(),
      child: Consumer<SkeletonViewModel>(
        builder: (_, vm, __) => Scaffold(
          appBar: AppBar(title: const Text('Pull to Refresh')),
          body: RefreshIndicator(
            onRefresh: vm.refresh,
            child: vm.isLoading
              ? const SkeletonListLoading()
              : ListView.builder(
                  itemCount: 20,
                  itemBuilder: (_, i) => ListTile(title: Text('Item \$i')),
                ),
          ),
        ),
      ),
    );
  }
}