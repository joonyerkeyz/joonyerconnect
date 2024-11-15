// about_page.dart

import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JM Connect+', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const Text('Version: 2.0'),
            const SizedBox(height: 8),
             const Text('Released date: 21 October 2024'),
            const SizedBox(height: 8),
            const Text('Crafted with passion by Mokoena Nhlanhla Junior'),
            const SizedBox(height: 16),
            const Text('JM Connect+ is a social media app designed to connect people and share moments.'),
          ],
        ),
      ),
    );
  }
}