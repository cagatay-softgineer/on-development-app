// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/pages/navigation_page.dart';
import 'package:ssdk_rsrc/providers/user_session.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';
import 'package:ssdk_rsrc/widgets/chain_day.dart';
import 'package:ssdk_rsrc/widgets/chain_step.dart';
import 'package:ssdk_rsrc/widgets/skeleton_provider.dart';
import 'package:ssdk_rsrc/widgets/top_bar.dart';
import 'package:ssdk_rsrc/widgets/glowing_text.dart';

class ChainPage extends StatefulWidget {
  final VoidCallback onBack;
  const ChainPage({super.key, required this.onBack});

  @override
  State<ChainPage> createState() => _ChainPageState();
}

class _ChainPageState extends State<ChainPage> {
  int chainStreak = 0;
  int maxChainStreak = 0;
  List history = [];
  String lastUpdateDate = '';
  bool isLoading = true;
  bool isMarking = false;
  bool broken = false;

  @override
  void initState() {
    super.initState();
    fetchChainStatus();
  }

  Future<void> fetchChainStatus() async {
    setState(() => isLoading = true);
    try {
      final result = await mainAPI.getChainStatus();
      setState(() {
        chainStreak = result['chain_streak'] ?? 0;
        maxChainStreak = result['max_chain_streak'] ?? 0;
        history = result['history'] ?? [];
        lastUpdateDate = result['last_update_date'] ?? '';
        broken = result['broken'] ?? false;
        UserSession.currentChainStreak = chainStreak;
      });
    } catch (e) {
      setState(() {
        chainStreak = 0;
        maxChainStreak = 0;
        history = [];
        lastUpdateDate = '';
        broken = false;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<DateTime?> generateMonthCalendar(DateTime today) {
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
    final totalDays = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday=0

    // Use a growable list!
    List<DateTime?> days = [];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    for (int d = 1; d <= totalDays; d++) {
      days.add(DateTime(today.year, today.month, d));
    }
    // Pad the last week with nulls
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  Set<String> getCompletedDaysSet(List history) {
    // Use yyyy-MM-dd for fast lookup
    return history
        .where((h) => h['action'] == 'completed')
        .map<String>((h) => h['date'].substring(0, 10))
        .toSet();
  }

  Future<void> markTodayCompleted() async {
    setState(() => isMarking = true);
    await mainAPI.updateChainStatus("completed");
    await fetchChainStatus();
    setState(() => isMarking = false);
  }

  bool isTodayCompleted() {
    final now = DateTime.now();
    try {
      final lastDate = DateTime.parse(lastUpdateDate);
      return lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back, color: ColorPalette.gold),
      //     onPressed: widget.onBack,
      //   ),
      //   backgroundColor: ColorPalette.backgroundColor,
      //   elevation: 0,
      // ),
      body: SkeletonProvider(
        isLoading: isLoading,
        baseColor: ColorPalette.lightGray,
        highlightColor: ColorPalette.gold.withOpacity(0.3),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading ? _buildSkeletonContent() : _buildRealContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonContent() {
    // int gridCount = 21;
    // int rowLen = 7;
    // List<bool> highlights = List.generate(
    //   gridCount,
    //   (i) => i > 2 && i < 6, // Example: cells 3,4,5 are highlighted/joined
    // );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Skeleton TopBar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Chain points (circle)
            Column(
              children: [
                SkeletonBox(
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(50),
                ),
                const SizedBox(height: 8),
                SkeletonBox(
                  width: 32,
                  height: 18,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            const SizedBox(width: 30),
            // Avatar + Username
            Column(
              children: [
                SkeletonBox(
                  width: 75,
                  height: 75,
                  borderRadius: BorderRadius.circular(50),
                ),
                const SizedBox(height: 20),
                SkeletonBox(
                  width: 120,
                  height: 32,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(width: 30),
            // Store points
            Column(
              children: [
                SkeletonBox(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 8),
                SkeletonBox(
                  width: 40,
                  height: 18,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Streak Text
        SkeletonBox(
          width: 180,
          height: 28,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        SkeletonBox(
          width: 100,
          height: 16,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 24),

        // Button placeholder
        SkeletonBox(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(height: 24),

        // History title
        SkeletonBox(
          width: 100,
          height: 18,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 10),

        // // Chain history skeleton grid
        // Expanded(
        //   child: GridView.builder(
        //     shrinkWrap: true,
        //     physics: const NeverScrollableScrollPhysics(),
        //     itemCount: gridCount,
        //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        //       crossAxisCount: 7,
        //       mainAxisSpacing: 10,
        //       crossAxisSpacing: 10,
        //       childAspectRatio: 1,
        //     ),
        //     itemBuilder: (context, i) {
        //       final completed = highlights[i];
        //       final left =
        //           (i % rowLen != 0) && highlights[i] && highlights[i - 1];
        //       final right =
        //           ((i + 1) % rowLen != 0) &&
        //           highlights[i] &&
        //           highlights[i + 1 < gridCount ? i + 1 : i];
        //       return ChainDaySkeletonWidget(
        //         highlight: completed,
        //         connectLeft: left,
        //         connectRight: right,
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }

  Widget _buildRealContent() {
    return Column(
      children: [
        TopBar(
          imageUrl: UserSession.userPIC ?? UserConstants.defaultAvatarUrl,
          userName: UserSession.userNAME ?? "",
          chainPoints: chainStreak,
          storePoints: 0,
          onChainTap: () => NavigationPage.of(context).showChain(),
        ),
        const SizedBox(height: 24),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomChainStepProgress(
              steps: 2,
              activeStep: broken ? 0 : 2,
              iconSize: 70,
            ),
            GlowingText(
              text: broken ? "Streak Broken" : "Current Streak: $chainStreak",
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorPalette.white,
              glowColor: broken ? Colors.redAccent : ColorPalette.gold,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Max Streak: $maxChainStreak",
          style: TextStyle(
            color: ColorPalette.white.withAlpha(120),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: Icon(
            isTodayCompleted() ? Icons.check : Icons.add_task,
            color:
                isTodayCompleted()
                    ? ColorPalette.white
                    : ColorPalette.gold, // <-- Set icon color here!
          ),
          label: Text(
            isTodayCompleted() ? "Today's completed!" : "Mark Today Completed!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorPalette.white, // <-- Set text color here!
            ),
          ),
          onPressed:
              isTodayCompleted() || isMarking ? null : markTodayCompleted,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isTodayCompleted() ? ColorPalette.lightGray : ColorPalette.gold,
            foregroundColor:
                ColorPalette
                    .white, // Used if icon/text do NOT set their own color
            // minimumSize: const Size(200, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // No need for textStyle here since it's set in Text above.
          ),
        ),

        const SizedBox(height: 16),
        GlowingText(
          text: "History",
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
    final days = generateMonthCalendar(today);
    final completedSet = getCompletedDaysSet(history);

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
        if (date == null) {
          return const SizedBox(); // Empty cell
        }

        final dateKey =
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final completed = completedSet.contains(dateKey);

        // Connect logic: only if previous/next days are also completed (ignore weekends)
        bool connectLeft = false, connectRight = false;
        if (index % 7 != 0 && days[index - 1] != null) {
          // not Sunday and previous cell is a day
          final prevDate = days[index - 1]!;
          final prevKey =
              "${prevDate.year.toString().padLeft(4, '0')}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}";
          connectLeft = completed && completedSet.contains(prevKey);
        }
        if ((index + 1) % 7 != 0 &&
            index + 1 < days.length &&
            days[index + 1] != null) {
          // not Saturday and next cell is a day
          final nextDate = days[index + 1]!;
          final nextKey =
              "${nextDate.year.toString().padLeft(4, '0')}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}";
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
