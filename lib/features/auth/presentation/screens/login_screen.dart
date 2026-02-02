import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../core/data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Form State
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPanelOpen = false;
  bool _isPasswordVisible = false;
  bool _isButtonHovered = false;
  static const Color accentGold = Color(0xFFC5A059);
  static const Color deepGold = Color(0xFF8B7348);
  int _currentFeatureIndex = 0;

  int _currentSeasonIndex = 0;
  int _previousSeasonIndex = 0;
  late AnimationController _weatherController;
  late AnimationController _seasonTransitionController;

  bool _isTransitioning = false;

  final List<Map<String, dynamic>> _seasons = [
    {
      'name': 'SUMMER',
      'label': 'HOT & VIBRANT',
      'colors': [const Color(0xFF2C1E12), const Color(0xFF0D0D0E)],
      'accent': const Color(0xFFFFB74D),
      'exposure': 1.8,
      'weather': 'haze',
    },
    {
      'name': 'RAINY',
      'label': 'SOFT & HUMID',
      'colors': [const Color(0xFF1A2226), const Color(0xFF0D0D0E)],
      'accent': const Color(0xFF4DB6AC),
      'exposure': 0.8,
      'weather': 'rain',
    },
    {
      'name': 'WINTER',
      'label': 'CRISP & COLD',
      'colors': [const Color(0xFF141A2F), const Color(0xFF0D0D0E)],
      'accent': const Color(0xFF81D4FA),
      'exposure': 1.3,
      'weather': 'snow',
    },
  ];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.home_work_rounded,
      'title': 'Smart Building',
      'desc': 'Monitor every room in one tap.'
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': 'Live Dashboard',
      'desc': 'See repairs & status in real-time.'
    },
    {
      'icon': Icons.build_circle_rounded,
      'title': 'Quick Repairs',
      'desc': 'Report issues, track fixes instantly.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _weatherController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _seasonTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _cycleFeatures();
    _cycleSeasons();
  }

  void _cycleSeasons() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 7));
      if (mounted && !_isPanelOpen) {
        setState(() {
          _previousSeasonIndex = _currentSeasonIndex;
          _currentSeasonIndex = (_currentSeasonIndex + 1) % _seasons.length;
          _isTransitioning = true;
        });
        _seasonTransitionController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _isTransitioning = false;
              _previousSeasonIndex = _currentSeasonIndex;
            });
          }
        });
      }
    }
  }

  void _cycleFeatures() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _currentFeatureIndex = (_currentFeatureIndex + 1) % _features.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _weatherController.dispose();
    _seasonTransitionController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await AuthRepository.instance.login(email, password);

      setState(() => _isLoading = false);

      if (result['success']) {
        final userId = result['data']['userId'];
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/3d_model',
            arguments: userId ?? 'User',
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'], style: GoogleFonts.kanit()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 950;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(screenWidth, isMobile),
          if (!isMobile && !_isPanelOpen) _buildGeometricAccents(),
          if (!isMobile && !_isPanelOpen) _buildHeroTagline(),
          if (!isMobile) _buildFeatureTicker(),
          Positioned(
            top: 40,
            left: isMobile ? 24 : 60,
            child: _buildBranding(),
          ),
          if (!isMobile && !_isPanelOpen)
            Positioned(
              right: 60,
              top: 40,
              child: _buildAccessButton(),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            top: 0,
            bottom: 0,
            right: _isPanelOpen ? 0 : -500,
            width: isMobile ? screenWidth : 500,
            child: _buildPanel(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(double screenWidth, bool isMobile) {
    return AnimatedBuilder(
      animation: _seasonTransitionController,
      builder: (context, child) {
        final t = _seasonTransitionController.value;
        final currentSeason = _seasons[_currentSeasonIndex];
        final previousSeason = _seasons[_previousSeasonIndex];

        final List<Color> colors = [
          Color.lerp(
              previousSeason['colors'][0], currentSeason['colors'][0], t)!,
          Color.lerp(
              previousSeason['colors'][1], currentSeason['colors'][1], t)!,
        ];

        final exposure = lerpDouble(
          previousSeason['exposure'],
          currentSeason['exposure'],
          t,
        )!;

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: colors,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: isMobile ? 0.3 : 0.8,
                child: ModelViewer(
                  key: const ValueKey('fcm_house_model_stable'),
                  backgroundColor: Colors.transparent,
                  src: 'assets/models/house.glb',
                  alt: 'FCM House Model',
                  autoRotate: true,
                  autoPlay: true,
                  cameraControls: false,
                  disableZoom: true,
                  exposure: exposure,
                  shadowIntensity: 1.0,
                  shadowSoftness: 0.0,
                  rotationPerSecond: '10deg',
                  cameraTarget: 'auto 1m auto',
                  cameraOrbit: '45deg 75deg 80%',
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: _isTransitioning ? (1.0 - t) : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          previousSeason['accent'].withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: _isTransitioning ? t : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          currentSeason['accent'].withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: _isTransitioning ? (1.0 - t) : 0.0,
                child: _buildWeatherEffect(
                  previousSeason['weather'],
                  previousSeason['accent'],
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: _isTransitioning ? t : 1.0,
                child: _buildWeatherEffect(
                  currentSeason['weather'],
                  currentSeason['accent'],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherEffect(String type, Color color) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _weatherController,
        builder: (context, child) {
          return CustomPaint(
            painter: WeatherPainter(
              type: type,
              color: color,
              progress: _weatherController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranding() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: accentGold.withOpacity(0.5), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shield_rounded, color: accentGold, size: 24),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FCM PLATFORM',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2)),
            Text('ENTERPRISE QUALITY MANAGEMENT',
                style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: accentGold.withOpacity(0.9),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTicker() {
    final feature = _features[_currentFeatureIndex];
    return Positioned(
      bottom: 60,
      left: 60,
      child: SizedBox(
        width: 320,
        height: 70,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Row(
            key: ValueKey(_currentFeatureIndex),
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentGold.withOpacity(0.3)),
                ),
                child: Icon(feature['icon'], color: accentGold, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(feature['title'],
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(feature['desc'],
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _isPanelOpen = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [deepGold, accentGold]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: accentGold.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login_rounded, color: Colors.black, size: 18),
              const SizedBox(width: 10),
              Text('Sign In',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
            left: BorderSide(color: Colors.white.withAlpha(20), width: 1)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Stack(
            children: [
              if (!isMobile)
                Positioned(
                  top: 32,
                  right: 32,
                  child: IconButton(
                    onPressed: () => setState(() => _isPanelOpen = false),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white30, size: 24),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05)),
                  ),
                ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign In',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Welcome back. Please enter your credentials.',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 48),
          _buildField('Email', _emailController, Icons.email_outlined),
          const SizedBox(height: 24),
          _buildField('Password', _passwordController, Icons.lock_outline,
              isPassword: true),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () {},
                child: const Text('Forgot password?',
                    style: TextStyle(color: accentGold, fontSize: 13))),
          ),
          const SizedBox(height: 40),
          _buildPrimaryButton('Sign In'),
          const SizedBox(height: 32),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Don\'t have an account?',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Sign Up',
                        style: TextStyle(
                            color: accentGold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon,
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white38)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white24, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white24,
                          size: 18),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonHovered = true),
      onExit: (_) => setState(() => _isButtonHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
              colors: _isButtonHovered
                  ? [accentGold, deepGold]
                  : [deepGold, accentGold]),
          boxShadow: [
            BoxShadow(
                color: accentGold.withOpacity(_isButtonHovered ? 0.4 : 0.15),
                blurRadius: _isButtonHovered ? 30 : 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _login,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : Text(text,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 1)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroTagline() {
    final season = _seasons[_currentSeasonIndex];
    return Positioned(
      top: 140,
      right: 60,
      width: 450,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: season['accent'], shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('${season['name']} - ${season['label']}',
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: season['accent'],
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Manage Your Property,',
              textAlign: TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.1)),
          Text('Effortlessly.',
              textAlign: TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: accentGold,
                  height: 1.1)),
          const SizedBox(height: 16),
          Text(
              'One platform, complete control. Monitor repairs and manage assets with precision.',
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                  fontSize: 15, color: Colors.white38, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildGeometricAccents() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
            painter: GeometricAccentPainter(accentGold.withOpacity(0.15))),
      ),
    );
  }
}

class GeometricAccentPainter extends CustomPainter {
  final Color color;
  GeometricAccentPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dashPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double i = 0; i < size.width; i += 100)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), dashPaint);
    for (double i = 0; i < size.height; i += 100)
      canvas.drawLine(Offset(0, i), Offset(size.width, i), dashPaint);
    canvas.drawLine(
        Offset(size.width * 0.7, 40), Offset(size.width * 0.95, 40), paint);
    canvas.drawLine(
        Offset(size.width * 0.7, 48), Offset(size.width * 0.9, 48), paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 40, paint);
    canvas.drawLine(
        Offset(40, size.height * 0.2), Offset(40, size.height * 0.8), paint);
    for (double j = size.height * 0.2; j < size.height * 0.8; j += 40)
      canvas.drawLine(Offset(40, j), Offset(55, j), paint);
    canvas.drawArc(Rect.fromLTWH(size.width * 0.7, size.height * 0.1, 400, 400),
        0, 1.5, false, paint);
    final diamondPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.1)
      ..lineTo(size.width * 0.12, size.height * 0.13)
      ..lineTo(size.width * 0.1, size.height * 0.16)
      ..lineTo(size.width * 0.08, size.height * 0.13)
      ..close();
    canvas.drawPath(diamondPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WeatherPainter extends CustomPainter {
  final String type;
  final Color color;
  final double progress;
  WeatherPainter(
      {required this.type, required this.color, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;
    final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (type == 'rain')
      _drawRain(canvas, size, paint, time);
    else if (type == 'snow')
      _drawSnow(canvas, size, paint, time);
    else if (type == 'haze') _drawHaze(canvas, size, paint, time);
  }

  void _drawRain(Canvas canvas, Size size, Paint paint, double time) {
    paint.style = PaintingStyle.stroke;
    for (int i = 0; i < 60; i++) {
      double seed = (i * 2.5) % 10.0;
      double speed = 500.0 + (seed * 500.0);
      double length = 4.0 + (seed * 8.0);
      double thickness = 0.4 + (seed * 0.2);
      double windSway = -3.0 - (math.sin(time * 0.4 + i) * 1.5);
      double x =
          (size.width * ((i * 19.3) % 10 / 10.0) + time * 60) % size.width;
      double y =
          (size.height * ((i * 27.7) % 10 / 10.0) + time * speed) % size.height;
      paint.strokeWidth = thickness * 3.0;
      paint.color = color.withOpacity(0.04);
      canvas.drawLine(Offset(x, y), Offset(x + windSway, y + length), paint);
      paint.strokeWidth = thickness;
      paint.color = color.withOpacity(0.35);
      canvas.drawLine(Offset(x, y), Offset(x + windSway, y + length), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size, Paint paint, double time) {
    for (int i = 0; i < 60; i++) {
      double randomSeed = (i * 1.5) % 10.0;
      double speed = 50.0 + (randomSeed * 10);
      double driftWidth = 20.0 + (randomSeed * 5);
      double x = (size.width * ((i * 13.7) % 10 / 10.0) +
              (math.sin(time * 0.8 + i) * driftWidth)) %
          size.width;
      double y =
          (size.height * ((i * 23.3) % 10 / 10.0) + time * speed) % size.height;
      double particleSize = 1.0 + (randomSeed * 0.2);
      canvas.drawCircle(
          Offset(x, y), particleSize, paint..color = color.withOpacity(0.4));
      canvas.drawCircle(Offset(x, y), particleSize + 2.0,
          paint..color = color.withOpacity(0.05));
    }
  }

  void _drawHaze(Canvas canvas, Size size, Paint paint, double time) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;
    for (int i = 0; i < 15; i++) {
      double x = (size.width * (i / 15.0) + math.sin(time * 0.5 + i) * 20) %
          size.width;
      double startY = size.height * 0.7;
      double endY = size.height * 0.9;
      Path path = Path();
      path.moveTo(x, startY);
      for (double j = 1; j <= 5; j++) {
        double segmentY = startY + (endY - startY) * (j / 5);
        double offsetX = math.sin(time * 2 + i + j) * 8;
        path.lineTo(x + offsetX, segmentY);
      }
      canvas.drawPath(path, paint..color = color.withOpacity(0.1));
    }
  }

  @override
  bool shouldRepaint(covariant WeatherPainter oldDelegate) => true;
}
