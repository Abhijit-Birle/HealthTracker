import 'package:flutter/material.dart';
import 'dart:io';

class MealEntry {
  final String name;
  final String cals;
  final String time;
  final String nutrition;
  final String fiber;
  final String vitamins;
  final IconData icon;
  final File? image;
  final String? imageUrl;
  final String type;
  final DateTime dateTime;

  // Macros for chart
  final double protein;
  final double carbs;
  final double fat;

  MealEntry(
      this.name,
      this.cals,
      this.time,
      this.nutrition,
      this.fiber,
      this.vitamins,
      this.icon,
      this.image,
      this.type,
      this.dateTime,
      {
        this.imageUrl,
        this.protein = 20.0,
        this.carbs = 30.0,
        this.fat = 10.0
      }
      );
}