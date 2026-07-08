import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Буцах — stack байвал pop, үгүй бол нүүр рүү
void popOrGoHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}

/// Цэснээс дэд хуудас нээх (буцах товч ажиллахын тулд push)
void openFromMenu(BuildContext context, String location) {
  context.push(location);
}
