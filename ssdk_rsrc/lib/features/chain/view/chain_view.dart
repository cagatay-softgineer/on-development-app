import 'package:flutter/material.dart';
import '../../../styles/color_palette.dart';
import '../../../widgets/skeleton_provider.dart';
import '../../../widgets/top_bar.dart';
import '../../../constants/default/user.dart';
import '../../../providers/userSession.dart';
import '../../../widgets/chain_step.dart';
import '../../../widgets/glowing_text.dart';
import '../../../widgets/chain_day.dart';
import '../presenter/chain_presenter.dart';
import '../router/chain_router.dart';

class ChainView extends StatefulWidget {
  final VoidCallback onBack;
  const ChainView({super.key, required this.onBack});

  @override
  State<ChainView> createState() => _ChainViewState();
}

class _ChainViewState extends State<ChainView> {
  late final ChainPresenter presenter;
  late final ChainRouter router;

  @override
  void initState() {
    super.initState();
    presenter = ChainPresenter();
    router = ChainRouter();
    presenter.fetchChainStatus().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      body: SkeletonProvider(
        isLoading: presenter.isLoading,
        baseColor: ColorPalette.lightGray,
        highlightColor: ColorPalette.gold.withOpacity(0.3),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: presenter.isLoading
                ? const SizedBox()
                : _buildRealContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildRealContent() {
    return Column(
      children: [
        TopBar(
          imageUrl: UserSession.userPIC ?? UserConstants.defaultAvatarUrl,
          userName: UserSession.userNAME ?? '',
          chainPoints: presenter.chainStreak,
          storePoints: 0,
          onChainTap: widget.onBack,
        ),
        const SizedBox(height: 24),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomChainStepProgress(
              steps: 2,
              activeStep: presenter.broken ? 0 : 2,
              iconSize: 70,
            ),
            GlowingText(
              text: presenter.broken
                  ? 'Streak Broken'
                  : 'Current Streak: ${presenter.chainStreak}',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorPalette.white,
              glowColor:
                  presenter.broken ? Colors.redAccent : ColorPalette.gold,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Max Streak: ${presenter.maxChainStreak}',
          style: TextStyle(
            color: ColorPalette.white.withAlpha(120),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: Icon(
            presenter.isTodayCompleted() ? Icons.check : Icons.add_task,
            color: presenter.isTodayCompleted()
                ? ColorPalette.white
                : ColorPalette.gold,
          ),
          label: Text(
            presenter.isTodayCompleted()
                ? "Today's completed!"
                : 'Mark Today Completed!',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorPalette.white,
            ),
          ),
          onPressed: presenter.isTodayCompleted() || presenter.isMarking
              ? null
              : () async {
                  await presenter.markTodayCompleted();
                  setState(() {});
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: presenter.isTodayCompleted()
                ? ColorPalette.lightGray
                : ColorPalette.gold,
            foregroundColor: ColorPalette.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GlowingText(
          text: 'History',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ColorPalette.white,
          glowColor: ColorPalette.gold,
        ),
        const SizedBox(height: 10),
        _buildHistoryGrid(),
      ],
    );
  }

  Widget _buildHistoryGrid() {
    final today = DateTime.now();
    final days = presenter.generateMonthCalendar(today);
    final completedSet = presenter.getCompletedDaysSet(presenter.history);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final date = days[index];
        if (date == null) return const SizedBox();
        final dateKey =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final completed = completedSet.contains(dateKey);
        bool connectLeft = false, connectRight = false;
        if (index % 7 != 0 && days[index - 1] != null) {
          final prevDate = days[index - 1]!;
          final prevKey =
              '${prevDate.year.toString().padLeft(4, '0')}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}';
          connectLeft = completed && completedSet.contains(prevKey);
        }
        if ((index + 1) % 7 != 0 &&
            index + 1 < days.length &&
            days[index + 1] != null) {
          final nextDate = days[index + 1]!;
          final nextKey =
              '${nextDate.year.toString().padLeft(4, '0')}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}';
          connectRight = completed && completedSet.contains(nextKey);
        }
        return ChainDayWidget(
          completed: completed,
          connectLeft: connectLeft,
          connectRight: connectRight,
          dayNumber: date.day,
          isToday: today.day == date.day,
        );
      },
    );
  }
}
