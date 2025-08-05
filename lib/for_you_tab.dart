import 'package:flutter/material.dart';

class ForYouTab extends StatelessWidget {
  const ForYouTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'For You',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
