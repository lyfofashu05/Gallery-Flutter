import 'package:flutter/material.dart';

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Search',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
