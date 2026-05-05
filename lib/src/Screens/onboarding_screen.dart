import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Discover Nearby Plans',
      'subtitle': 'Find spontaneous games, study sessions, and hangouts in your area.',
      'emoji': '🗺️',
    },
    {
      'title': 'Create Spontaneous Events',
      'subtitle': 'Set the time, place, and vibe — then invite trusted people nearby.',
      'emoji': '✨',
    },
    {
      'title': 'Join Instant Group Chats',
      'subtitle': 'Chat with your crew and stay in sync before you meet.',
      'emoji': '💬',
    },
    {
      'title': 'Build Your Crew',
      'subtitle': 'Connect with local friends, discover trusted hosts, and stay social.',
      'emoji': '🤝',
    },
  ];

  void _nextPage() {
    if (_index == _slides.length - 1) {
      widget.onCompleted();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: widget.onCompleted,
                          child: const Text('Skip', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(slide['emoji']!, style: const TextStyle(fontSize: 64)),
                      const SizedBox(height: 24),
                      Text(slide['title']!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      Text(slide['subtitle']!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.75))),
                      const Spacer(),
                      GlassmorphicContainer(
                        width: double.infinity,
                        height: 260,
                        borderRadius: 24,
                        blur: 20,
                        alignment: Alignment.center,
                        border: 1,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.onBackground.withOpacity(0.12),
                            Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.35),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.18),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Featured', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Text('Local recommendations, trending events, and trusted hosts—all in one feed.', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(
                              _slides.length,
                              (dotIndex) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: dotIndex == _index ? 24 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: dotIndex == _index ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            child: Text(_index == _slides.length - 1 ? 'Get Started' : 'Next'),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
