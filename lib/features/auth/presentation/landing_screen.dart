import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background grid of album covers
          _AlbumGrid(),

          // Dark overlay gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.7, 1.0],
                colors: [
                  Color(0x99050A14),
                  Color(0x55050A14),
                  Color(0xDD050A14),
                  Color(0xFF050A14),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: CadenceColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.album, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'cadence',
                                style: TextStyle(
                                  color: CadenceColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          Text(
                            'Every album\nhas a story.',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: CadenceColors.textPrimary,
                                  height: 1.1,
                                ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Rate, review, and discover albums with people who care as much about music as you do.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: CadenceColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),

                          const SizedBox(height: 48),

                          ElevatedButton(
                            onPressed: () => context.push('/sign-up'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CadenceColors.primary,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          ),

                          const SizedBox(height: 12),

                          OutlinedButton(
                            onPressed: () => context.push('/sign-in'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: CadenceColors.textPrimary,
                              minimumSize: const Size(double.infinity, 52),
                              side: const BorderSide(color: CadenceColors.border, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),

                          const SizedBox(height: 8),

                          TextButton(
                            onPressed: () => ref.read(authProvider.notifier).signIn('guest@cadence.demo', 'demo'),
                            child: const Text('Try the demo without an account', style: TextStyle(color: CadenceColors.primaryLight, fontSize: 14)),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  final _urls = [
    'https://upload.wikimedia.org/wikipedia/en/f/f6/Kendrick_Lamar_-_To_Pimp_a_Butterfly.png',
    'https://upload.wikimedia.org/wikipedia/en/b/ba/Radioheadokcomputer.png',
    'https://upload.wikimedia.org/wikipedia/en/a/a0/Blonde_-_Frank_Ocean.jpeg',
    'https://upload.wikimedia.org/wikipedia/en/3/3b/Radiohead_-_In_Rainbows.png',
    'https://upload.wikimedia.org/wikipedia/en/7/70/Kanye_West_-_My_Beautiful_Dark_Twisted_Fantasy.png',
    'https://upload.wikimedia.org/wikipedia/en/9/9b/Tame_Impala_-_Currents.png',
    'https://upload.wikimedia.org/wikipedia/en/0/0d/Good_kid_maad_city.jpg',
    'https://upload.wikimedia.org/wikipedia/en/f/f4/Fleetwood_Mac_-_Rumours.png',
    'https://upload.wikimedia.org/wikipedia/en/8/84/Tyler_the_Creator_-_Igor.png',
    'https://upload.wikimedia.org/wikipedia/en/1/15/Frank_Ocean_-_Channel_Orange.png',
    'https://upload.wikimedia.org/wikipedia/en/b/bb/PetSoundsCover.jpg',
    'https://upload.wikimedia.org/wikipedia/en/9/9a/Purplerain.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: _urls.length,
      itemBuilder: (_, i) => Image.network(
        _urls[i % _urls.length],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(color: CadenceColors.surface),
      ),
    );
  }
}
