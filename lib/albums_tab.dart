import 'package:flutter/material.dart';

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Albums',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
