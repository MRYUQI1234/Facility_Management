import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import '../../../../core/data/auth_repository.dart';

enum Season { summer, rainy, winter }

class Particle {
  double x, y, speed, opacity, size;
  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.opacity,
    required this.size,
  });
}

class WeatherPainter extends CustomPainter {
  final List<Particle> particles;
  final Season season;

  WeatherPainter({required this.particles, required this.season});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.0;

    for (var particle in particles) {
      if (season == Season.rainy) {
        paint.color = Colors.white.withOpacity(particle.opacity * 0.4);
        canvas.drawLine(
          Offset(particle.x, particle.y),
          Offset(particle.x, particle.y + 10),
          paint,
        );
      } else if (season == Season.winter) {
        paint.color = Colors.white.withOpacity(particle.opacity * 0.8);
        canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SeasonsOverlay extends StatefulWidget {
  final Season currentSeason;
  const SeasonsOverlay({super.key, required this.currentSeason});

  @override
  State<SeasonsOverlay> createState() => _SeasonsOverlayState();
}

class _SeasonsOverlayState extends State<SeasonsOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  double _flashOpacity = 0.0;
  DateTime _nextFlashTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _initParticles();
    _nextFlashTime = DateTime.now().add(Duration(seconds: 5 + _random.nextInt(10)));
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 100; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 2000,
        y: _random.nextDouble() * 1000,
        speed: 2 + _random.nextDouble() * 5,
        opacity: _random.nextDouble(),
        size: 1 + _random.nextDouble() * 3,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (widget.currentSeason == Season.summer) return;
    
    // Lightning logic for Rainy season
    if (widget.currentSeason == Season.rainy) {
      if (DateTime.now().isAfter(_nextFlashTime)) {
        _flashOpacity = 0.5 + _random.nextDouble() * 0.4;
        _nextFlashTime = DateTime.now().add(Duration(seconds: 10 + _random.nextInt(20)));
      }
      if (_flashOpacity > 0) {
        _flashOpacity -= 0.05;
        if (_flashOpacity < 0) _flashOpacity = 0;
      }
    } else {
      _flashOpacity = 0;
    }

    for (var p in _particles) {
      p.y += p.speed;
      if (widget.currentSeason == Season.winter) {
        p.x += math.sin(p.y / 20) * 0.5; // Swaying snow
      }
      
      if (p.y > 1000) {
        p.y = -20;
        p.x = _random.nextDouble() * 2000;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _updateParticles();
        return Stack(
          children: [
            // Seasonal Gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 1500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getSeasonColors(),
                ),
              ),
            ),
            
            // Particle Layer
            if (widget.currentSeason != Season.summer)
              CustomPaint(
                painter: WeatherPainter(particles: _particles, season: widget.currentSeason),
                size: Size.infinite,
              ),

            // Summer Heat Haze (Simulated with pulsating opacity)
            if (widget.currentSeason == Season.summer)
              Opacity(
                opacity: 0.1 + (math.sin(_controller.value * math.pi * 2) * 0.05),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0xFFFF9800), Colors.transparent],
                      radius: 1.5,
                    ),
                  ),
                ),
              ),

            // Lightning Flash Overlay
            if (_flashOpacity > 0)
              Container(
                color: Colors.white.withOpacity(_flashOpacity),
              ),
          ],
        );
      },
    );
  }

  List<Color> _getSeasonColors() {
    switch (widget.currentSeason) {
      case Season.summer:
        return [
          const Color(0xFF1A1C1E),
          const Color(0xFF2C2010), // Warm brown/orange hint
          const Color(0xFF000000),
        ];
      case Season.rainy:
        return [
          const Color(0xFF0F1419),
          const Color(0xFF1E2732), // Muted dark blue
          const Color(0xFF000000),
        ];
      case Season.winter:
        return [
          const Color(0xFF101418),
          const Color(0xFF243447), // Cold blue/grey
          const Color(0xFF000000),
        ];
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Season _currentSeason = Season.summer;
  Timer? _seasonTimer;

  @override
  void initState() {
    super.initState();
    _startSeasonCycle();
  }

  void _startSeasonCycle() {
    _seasonTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          _currentSeason = Season.values[(_currentSeason.index + 1) % Season.values.length];
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _seasonTimer?.cancel();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await AuthRepository.instance.login(email, password);

      setState(() => _isLoading = false);

      if (result['success']) {
        // Navigate to 3D Model Screen
        // We can pass the user's name or ID if available from response, 
        // strictly speaking we should fetch user profile but for now let's use part of email or hardcode
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Dynamic Seasonal Background
          SeasonsOverlay(currentSeason: _currentSeason),

          // 3D Model with Click Blocker
          // 3D Model with Click Blocker (Physical Shift Left)
          Positioned(
            left: -150, // Physical shift left for visual balance with card
            right: 150, 
            top: 150, 
            bottom: -150, 
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.9,
                  child: ModelViewer(
                    key: const ValueKey('house_auto_rotation_final'),
                    backgroundColor: Colors.transparent,
                    src: 'gulli_bulli_house.glb',
                    alt: "A 3D model of a futuristic building",
                    ar: false,
                    autoRotate: true, // Back to built-in for better performance
                    autoRotateDelay: 0,
                    rotationPerSecond: '5deg',
                    cameraControls: false,
                    disableZoom: true,
                    disableTap: true,
                    disablePan: true,
                    touchAction: TouchAction.none,
                    interactionPrompt: InteractionPrompt.none,
                    cameraOrbit: '0deg 90deg 220m', 
                    cameraTarget: 'auto', // The engine finds the true center
                    fieldOfView: '30deg',
                  ),
                ),
                // PointerInterceptor blocks ALL clicks on the iframe
                Positioned.fill(
                  child: PointerInterceptor(
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Atmosphere & Depth Layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),

          // 4. Branding Identity (Top-Left)
          Positioned(
            top: 60,
            left: 60,
            child: FadeInAnimation(
              delay: 300,
              child: _buildTitleSection(),
            ),
          ),

          // 5. Navigation/Status (Subtle Credits)
          Positioned(
            bottom: 40,
            left: 60,
            child: FadeInAnimation(
              delay: 800,
              child: Text(
                '© 2026 FCM GLOBAL - ARCHITECTURE OF THE FUTURE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 4.0,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ),

          // 6. Interaction Layer (Right-Aligned Login)
          SafeArea(
            child: Row(
              children: [
                const Spacer(flex: 14), // Even more space to push everything
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FadeInAnimation(
                        delay: 600,
                        child: _buildLoginForm(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30), // Smaller margin on the very right
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FACILITY',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            letterSpacing: 10.0,
            color: const Color(0xFFC5A059),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MANAGEMENT',
          style: GoogleFonts.inter(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            height: 0.9,
            color: Colors.white,
            letterSpacing: -2.0,
          ),
        ),
        Text(
          'SYSTEM',
          style: GoogleFonts.inter(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            height: 0.9,
            color: Colors.white,
            letterSpacing: -2.0,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 4,
          color: const Color(0xFFC5A059),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
                offset: const Offset(-10, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      color: const Color(0xFFC5A059),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SECURE ACCESS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: const Color(0xFFC5A059),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'ลงชื่อเข้าใช้งาน',
                  style: GoogleFonts.kanit(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เข้าสู่ระบบเพื่อจัดการพื้นที่โครงการของคุณ',
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Email/Username Field
                TextFormField(
                  controller: _emailController,
                  style: GoogleFonts.kanit(color: Colors.white),
                  cursorColor: const Color(0xFFC5A059),
                  decoration: _inputDecoration('อีเมล / ชื่อผู้ใช้'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล หรือ ชื่อผู้ใช้';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.kanit(color: Colors.white),
                  cursorColor: const Color(0xFFC5A059),
                  decoration: _inputDecoration('รหัสผ่าน'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                
                // Login Button
                SizedBox(
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B7348), Color(0xFFC5A059)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC5A059).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.black))
                          : Text(
                              'IDENTIFY',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Register Link
                Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.kanit(color: Colors.grey, fontSize: 13),
                          children: [
                            const TextSpan(text: 'ท่านยังไม่มีบัญชี? '),
                            TextSpan(
                              text: 'ลงทะเบียน',
                              style: GoogleFonts.kanit(
                                color: const Color(0xFFC5A059),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFFC5A059),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.kanit(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E1E1E), // Slightly lighter than card bg
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

// Simple Fade-In Animation Widget
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  const FadeInAnimation({super.key, required this.child, required this.delay});

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
