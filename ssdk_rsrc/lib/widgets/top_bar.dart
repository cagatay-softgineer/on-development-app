import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';
import 'package:ssdk_rsrc/widgets/chess_points.dart';
import 'package:ssdk_rsrc/widgets/glowing_overlapping_circles.dart';
import 'package:ssdk_rsrc/widgets/glowing_text.dart';

// Import your glowing text widget here if not in same file
// import 'glowing_text.dart';

class TopBar extends StatelessWidget {
  final String imageUrl;
  final String userName;
  final double size;
  final double nameFontSize;
  final int chainPoints;
  final int storePoints;

  const TopBar({
    super.key,
    required this.imageUrl,
    required this.userName,
    this.size = 75,
    this.nameFontSize = 32,
    required this.chainPoints,
    required this.storePoints,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: 0),
                            Column(
                              children: [GlowingOverlappingCircles(points: chainPoints)],
                            ),
                            SizedBox(width: 30),
                            Column(
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    imageUrl,
                                    width: 75,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        UserConstants.defaultAvatarUrl,
                                        width: 75,
                                        height: 75,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                GlowingText(
                                  text: userName,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            SizedBox(width: 30),
                            Column(children: [ChessPointsWidget(points: storePoints)]),
                            SizedBox(width: 0),
                          ],
                        );
  }
}
