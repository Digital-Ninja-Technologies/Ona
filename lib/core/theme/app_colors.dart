import 'package:flutter/material.dart';

/// The Ọ̀nà brand palette — Deep Green, Route Green, Sand, Cream, Charcoal,
/// and Way Gold — from the official brand guide (see the "Colours" section
/// of the brand asset package). Semantic names below map onto it so the
/// rest of the app never references raw brand names directly.
class AppColors {
  AppColors._();

  // --- Brand palette -------------------------------------------------
  static const deepGreen = Color(0xFF123A2C);
  static const routeGreen = Color(0xFF1B5E4B);
  static const sand = Color(0xFFEDE1CB);
  static const cream = Color(0xFFF5F0E6);
  static const charcoal = Color(0xFF16171A);
  static const wayGold = Color(0xFFD99B36);

  // --- Semantic roles --------------------------------------------------
  static const primary = routeGreen;
  static const primaryDark = deepGreen;
  static const gold = wayGold;
  static const orange = gold; // ratings / AI-generated badges
  static const teal = Color(0xFF2C7A6B);
  static const green = Color(0xFF3F7D5C);
  static const verified = Color(0xFF2F9E6E);
  static const yellowGold = Color(0xFFE8B25C);
  static const yellow = yellowGold;
  static const error = Color(0xFFC1442D);

  static const background = cream;
  static const surface = sand;
  static const text = charcoal;
  static const textSecondary = Color(0xFF6E6A5E);
  static const border = Color(0xFFDDD2BA);
}
