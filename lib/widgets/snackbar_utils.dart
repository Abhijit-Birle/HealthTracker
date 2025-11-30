import 'package:flutter/material.dart';
import 'dart:ui';

void showFuturisticSnackBar(BuildContext context, String title, Color color, {String? subtitle, Widget? icon, bool isRive = false, String? emoji}) {
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E2129).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.5)),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)]
                      ),
                      child: Row(
                          children: [
                            if(icon != null) icon
                            else if (emoji != null) Text(emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 15),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                      if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))
                                    ]
                                )
                            )
                          ]
                      )
                  )
              )
          )
      )
  );
}