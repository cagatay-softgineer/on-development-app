import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

class ColorPalette{
  static Color gold = Color(0xFFD3AF37);
  static Color backgroundColor = Color(0xFF252930);
  static Color lightGray = Color(0xFF575B62);
  static Color white = Color(0xFFEFE9E3);
  static Color clickable = Color(0xFF87B3FF);
  static Color youtubeRed = Color(0xFFFF0000);
  static Color spotifyGreen = Color(0xFF1ED760);
  static Color linkedInBlue = Color(0xFF0072B1);
  static Color instagramPink = Color(0xFFC13584);

  // For Custom Buttons Params
  static String gold_ = "Color(0xFFD3AF37)";
  static String backgroundColor_ = "Color(0xFF252930)";
  static String lightGray_ = "Color(0xFF575B62)";
  static String white_ = "Color(0xFFEFE9E3)";
  static String clickable_ = "Color(0xFF87B3FF)";
  static String youtubeRed_ = "Color(0xFFFF0000)";
  static String spotifyGreen_ = "Color(0xFF1ED760)";
  static String linkedInBlue_ = "Color(0xFF0072B1)";
  static String instagramPink_ = "Color(0xFFC13584)";
}

class Transparent{
  static Color a00 = Color(0x00000000);
  static Color a11 = Color(0x11000000);
  static Color a22 = Color(0x22000000);
  static Color a33 = Color(0x33000000);
  static Color a44 = Color(0x44000000);
  static Color a55 = Color(0x55000000);
  static Color a66 = Color(0x66000000);
  static Color a77 = Color(0x77000000);
  static Color a88 = Color(0x88000000);
  static Color a99 = Color(0x99000000);
  static Color aAA = Color(0xAA000000);
  static Color aBB = Color(0xBB000000);
  static Color aCC = Color(0xCC000000);
  static Color aDD = Color(0xDD000000);
  static Color aEE = Color(0xEE000000);
  static Color aFF = Color(0xFF000000);

  static String a00_ = "Color(0x00000000)";
  static String a11_ = "Color(0x11000000)";
  static String a22_ = "Color(0x22000000)";
  static String a33_ = "Color(0x33000000)";
  static String a44_ = "Color(0x44000000)";
  static String a55_ = "Color(0x55000000)";
  static String a66_ = "Color(0x66000000)";
  static String a77_ = "Color(0x77000000)";
  static String a88_ = "Color(0x88000000)";
  static String a99_ = "Color(0x99000000)";
  static String aAA_ = "Color(0xAA000000)";
  static String aBB_ = "Color(0xBB000000)";
  static String aCC_ = "Color(0xCC000000)";
  static String aDD_ = "Color(0xDD000000)";
  static String aEE_ = "Color(0xEE000000)";
  static String aFF_ = "Color(0xFF000000)";
}

class Youtube{
  static Color red = Color(0xFFFF0000);
  static Color white = Color(0xFFFFFFFF);
  static Color almostBlack = Color(0xFF282828);
}

class Instagram{
  static Color yellow = Color(0xFFFFD600);
  static Color orange = Color(0xFFFF7A00);
  static Color pink = Color(0xFFFF0069);
  static Color purple = Color(0xFFD300C5);
  static Color violent = Color(0xFF7638FA);
}

class GradientPallette{
  static MeshGradient instagram = MeshGradient(
                            points: [
                              MeshGradientPoint(
                                position: const Offset(
                                  0.240,
                                  0.140,
                                ),
                                color: Instagram.violent,
                              ),
                              MeshGradientPoint(
                                position: const Offset(
                                  0.815,
                                  0.190,
                                ),
                                color: Instagram.purple,
                              ),
                              MeshGradientPoint(
                                position: const Offset(
                                  0.790,
                                  0.690,
                                ),
                                color: Instagram.pink,
                              ),
                              MeshGradientPoint(
                                position: const Offset(
                                  0.390,
                                  0.640,
                                ),
                                color: Instagram.orange,
                              ),
                              MeshGradientPoint(
                                position: const Offset(
                                  0.140,
                                  0.840,
                                ),
                                color: Instagram.yellow,
                              ),
                            ],
                            options: MeshGradientOptions(),
                            );

  static AnimatedMeshGradient animatedInstagram = AnimatedMeshGradient(
                            colors: [
                                Instagram.violent,
                                // Instagram.purple, // Animated Mesh Must Be have Max 4 Colors
                                Instagram.pink,
                                Instagram.orange,
                                Instagram.yellow,
                            ],
                            options: AnimatedMeshGradientOptions(
                              speed: 10,
                            ),
                            );

  static AnimatedMeshGradient animatedTest = AnimatedMeshGradient(
                            colors: [
                                ColorPalette.gold,
                                ColorPalette.backgroundColor,
                                ColorPalette.backgroundColor,
                                ColorPalette.backgroundColor,
                            ],
                            options: AnimatedMeshGradientOptions(
                              speed: 10,
                            ),
                            );

  static LinearGradient goldenOrder = LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [ColorPalette.gold,ColorPalette.backgroundColor]);

  static MeshGradient test = MeshGradient(
                            points: [
                              MeshGradientPoint(
                                position: const Offset(
                                  0.9,
                                  0.2,
                                ),
                                color: ColorPalette.gold,
                              ),
                              MeshGradientPoint(
                                position: const Offset(
                                  0.2,
                                  0.9,
                                ),
                                color: ColorPalette.backgroundColor,
                              ),
                            ],
                            options: MeshGradientOptions(
                              blend: 6,
                              noiseIntensity: 1
                            ),
                            );
}
