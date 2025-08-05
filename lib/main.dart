import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

// Import your fragment tabs
import 'all_photos_tab.dart';
import 'albums_tab.dart';
import 'for_you_tab.dart';
import 'search_tab.dart';

void main() => runApp(const MyApp());

enum _Tab { allPhotos, albums, forYou, search }

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallery',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'InterSemiBold',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'InterSemiBold',
      ),
      home: const HomePage(),
    );
  }
}

class PopIcon extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;

  const PopIcon({
    super.key,
    required this.child,
    required this.trigger,
    this.duration = const Duration(milliseconds: 195),
  });

  @override
  State<PopIcon> createState() => _PopIconState();
}

class _PopIconState extends State<PopIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  static const double peak = 1.25;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: peak)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: peak, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
    if (widget.trigger) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant PopIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0.0);
    } else if (!widget.trigger && oldWidget.trigger) {
      _controller.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) =>
          Transform.scale(scale: _animation.value, child: child),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _previousSelectedIndex = 0;

  static const Map<_Tab, String> _labels = {
    _Tab.allPhotos: "All Photos",
    _Tab.albums: "Albums",
    _Tab.forYou: "For You",
    _Tab.search: "Search",
  };

  static const Map<_Tab, IconData> _cupertinoFilledIcons = {
    _Tab.allPhotos: CupertinoIcons.photo_fill_on_rectangle_fill,
    _Tab.albums: CupertinoIcons.square_stack_fill,
    _Tab.forYou: CupertinoIcons.square_favorites_alt_fill,
    _Tab.search: CupertinoIcons.search,
  };

  static const double minNavItemWidth = 66;

  final List<Widget> _fragments = const [
    AllPhotosTab(),
    AlbumsTab(),
    ForYouTab(),
    SearchTab(),
  ];

  Widget navIcon({
    required IconData cupertinoIcon,
    required String label,
    required bool selected,
    required int index,
    double size = 26,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final color = selected
        ? CupertinoColors.activeBlue
        : theme.colorScheme.onSurfaceVariant;

    final isNewlySelected = index == _selectedIndex && index != _previousSelectedIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PopIcon(
          trigger: isNewlySelected,
          child: Icon(
            cupertinoIcon,
            size: size,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: minNavItemWidth,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'InterSemiBold',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            softWrap: false,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  void _onTap(int i) async {
    if (_selectedIndex != i) {
      if (await Vibration.hasVibrator() ?? true) {
        if (await Vibration.hasAmplitudeControl() ?? true) {
          Vibration.vibrate(duration: 80, amplitude: 128);
        } else {
          Vibration.vibrate(duration: 50);
        }
      }
      setState(() {
        _previousSelectedIndex = _selectedIndex;
        _selectedIndex = i;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update system nav bar to match theme
    final theme = Theme.of(context);
    final barColor = theme.colorScheme.surface;
    final barIconBrightness = theme.brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: barColor,
      systemNavigationBarIconBrightness: barIconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: barIconBrightness,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _fragments,
      ),
      bottomNavigationBar: CrystalNavigationBar(
        height: 70,
        borderWidth: 2,
        outlineBorderColor: dark ? Colors.white38 : Colors.black26,
        backgroundColor: theme.colorScheme.surface.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: _onTap,
        items: [
          for (int i = 0; i < _Tab.values.length; i++)
            CrystalNavigationBarItem(
              icon: navIcon(
                cupertinoIcon: _cupertinoFilledIcons[_Tab.values[i]]!,
                label: _labels[_Tab.values[i]]!,
                selected: _selectedIndex == i,
                index: i,
                context: context,
              ),
              unselectedIcon: navIcon(
                cupertinoIcon: _cupertinoFilledIcons[_Tab.values[i]]!,
                label: _labels[_Tab.values[i]]!,
                selected: false,
                index: i,
                context: context,
              ),
            ),
        ],
      ),
    );
  }
}
