import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/data/providers/user_session.dart';
import 'package:pomodoro/viewmodels/chain_viewmodel.dart';
import 'package:pomodoro/resources/themes.dart';
import 'package:pomodoro/core/constants/user.dart';
import 'package:pomodoro/widgets/components/top_bar.dart';
import 'package:pomodoro/widgets/bar/chain_step.dart';
import 'package:pomodoro/widgets/text/glowing_text.dart';
import 'package:pomodoro/widgets/components/chain_day.dart';

/// Displays the user’s chain (streak) with history calendar.
class ChainPage extends StatelessWidget {
  final VoidCallback onBack;
  const ChainPage({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChainViewModel(),
      child: Consumer<ChainViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: ColorPalette.backgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(context, vm),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ChainViewModel vm) {
    final days = vm.generateMonthCalendar(DateTime.now());
    final completed = vm.getCompletedDaysSet(vm.history);

    return Column(
      children: [
        TopBar(
          imageUrl: UserSession.userPIC ?? UserConstants.defaultAvatarUrl,
          userName: UserSession.userNAME ?? '',
          chainPoints: vm.chainStreak,
          storePoints: 0,
          onChainTap: onBack,
        ),
        const SizedBox(height: 24),
        CustomChainStepProgress(
          steps: 2,
          activeStep: vm.broken ? 0 : 2,
          iconSize: 70,
        ),
        const SizedBox(height: 8),
        GlowingText(
          text: vm.broken
              ? 'Streak Broken'
              : 'Current Streak: \${vm.chainStreak}',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ColorPalette.white,
          glowColor: vm.broken ? Colors.redAccent : ColorPalette.gold,
        ),
        const SizedBox(height: 8),
        Text(
          'Max Streak: \${vm.maxChainStreak}',
          style: TextStyle(
            color: ColorPalette.white.withAlpha(120),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(
            vm.isTodayCompleted() ? Icons.check : Icons.add_task,
            color: vm.isTodayCompleted()
                ? ColorPalette.white
                : ColorPalette.gold,
          ),
          label: Text(
            vm.isTodayCompleted()
                ? "Today's completed!"
                : 'Mark Today Completed!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorPalette.white,
            ),
          ),
          onPressed: vm.isTodayCompleted() || vm.isMarking
              ? null
              : vm.markTodayCompleted,
          style: ElevatedButton.styleFrom(
            backgroundColor: vm.isTodayCompleted()
                ? ColorPalette.lightGray
                : ColorPalette.gold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorPalette.white,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) return const SizedBox();

              final key = date.toIso8601String().split('T').first;
              final done = completed.contains(key);

              bool left = false, right = false;
              if (index % 7 != 0 && days[index - 1] != null) {
                final prevKey = days[index - 1]!
                    .toIso8601String()
                    .split('T')
                    .first;
                left = done && completed.contains(prevKey);
              }
              if ((index + 1) % 7 != 0 && days[index + 1] != null) {
                final nextKey = days[index + 1]!
                    .toIso8601String()
                    .split('T')
                    .first;
                right = done && completed.contains(nextKey);
              }

              return ChainDayWidget(
                completed: done,
                connectLeft: left,
                connectRight: right,
                dayNumber: date.day,
                isToday: DateTime.now().day == date.day &&
                    DateTime.now().month == date.month &&
                    DateTime.now().year == date.year,
              );
            },
          ),
        ),
      ],
    );
  }
}
