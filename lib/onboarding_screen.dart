import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:novo_app/main.dart'; // Import para navegar para HomeScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<double> _progressValues = [0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 1.0];

  // Animation Controllers
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  // Colors - Paleta premium e vibrante
  final Color _primaryColor = const Color(0xFF667eea);
  final Color _secondaryColor = const Color(0xFF764ba2);
  final Color _accentPink = const Color(0xFFf093fb);
  final Color _accentGold = const Color(0xFFf5af19);

  // Controllers & State
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _churchController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedDate;
  String _selectedState = 'SP'; // Default
  String _selectedCountry = 'Brasil';
  
  // Faith & Ministry
  String? _selectedFaith;
  String _selectedMinistry = 'Participante';

  // Interests
  List<String> _selectedInterests = [];
  final List<String> _availableInterests = [
    'Música', 'Leitura', 'Esportes', 'Teologia', 'Viagens', 'Café', 
    'Cinema', 'Missões', 'Crianças', 'Tecnologia', 'Culinária', 'Natureza'
  ];

  @override
  void initState() {
    super.initState();
    
    // Floating animation for decorative elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatingAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Pulse animation for hearts
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _churchController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    // Navigate to TutorialScreen first, then HomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TutorialScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Premium
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor,
                  _secondaryColor,
                  _accentPink.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Animated Decorative Elements
          ..._buildFloatingDecorations(),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildWelcomeStep(),
                      _buildBasicInfoStep(),
                      _buildBioStep(),
                      _buildLocationStep(),
                      _buildInterestsStep(),
                      _buildFaithStep(),
                      _buildChurchStep(),
                      _buildPhotosStep(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingDecorations() {
    return [
      // Large floating bubble top-left
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Positioned(
            top: -80 + _floatingAnimation.value,
            left: -60,
            child: _buildGlassBubble(220, opacity: 0.08),
          );
        },
      ),
      // Medium bubble bottom-right
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Positioned(
            bottom: -120 + _floatingAnimation.value * 0.7,
            right: -80,
            child: _buildGlassBubble(320, opacity: 0.06),
          );
        },
      ),
      // Small floating heart top-right
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Positioned(
            top: 120 - _floatingAnimation.value * 0.5,
            right: 40,
            child: Transform.rotate(
              angle: math.pi / 12,
              child: Icon(
                Icons.favorite,
                color: Colors.white.withOpacity(0.15),
                size: 40,
              ),
            ),
          );
        },
      ),
      // Small bubble center-left
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 20 + _floatingAnimation.value * 0.3,
            child: _buildGlassBubble(60, opacity: 0.1),
          );
        },
      ),
      // Tiny floating cross
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Positioned(
            bottom: 200 + _floatingAnimation.value * 0.8,
            left: 60,
            child: Icon(
              Icons.add,
              color: Colors.white.withOpacity(0.12),
              size: 30,
            ),
          );
        },
      ),
    ];
  }

  Widget _buildGlassBubble(double size, {double opacity = 0.1}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(opacity * 1.5),
            Colors.white.withOpacity(opacity * 0.5),
            Colors.white.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(opacity),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          if (_currentPage > 0)
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: _previousPage,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Passo ${_currentPage + 1}/8',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 48),
            
          const SizedBox(height: 10),
          // Progress Bar with glow effect
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progressValues[_currentPage],
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: _primaryColor.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  // --- WELCOME STEP - Tela de Boas-Vindas Premium ---

  Widget _buildWelcomeStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
        child: Column(
          children: [
            const Spacer(flex: 1),
            
            // Animated Logo/Icon with glow
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          // Heart icon
                          const Icon(
                            Icons.favorite_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 50),
            
            // Main Title with elegant typography
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, Colors.white.withOpacity(0.9)],
              ).createShader(bounds),
              child: const Text(
                'Bem-vindo ao',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // App Name - Big and Bold
            const Text(
              'Par Cristão',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
                height: 1.1,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            

            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Conecte-se com pessoas que compartilham sua fé, valores e propósito de vida. Sua história de amor pode começar aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.6,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            
            const Spacer(flex: 1),
            
            // Feature highlights
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureHighlight(Icons.verified_user_outlined, 'Perfis\nVerificados'),
                _buildFeatureHighlight(Icons.favorite_border, 'Interesses\nReais'),
                _buildFeatureHighlight(Icons.church_outlined, 'Fé em\nComum'),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // CTA Button Premium
            _buildPremiumButton(
              'Começar Minha Jornada',
              Icons.arrow_forward_rounded,
              _nextPage,
            ),
            
            const SizedBox(height: 20),
            
            // Skip text
            TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'Já tenho uma conta',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlight(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F8F8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _accentPink.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                  ).createShader(bounds),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: _buildPremiumCard(
        icon: Icons.person_outline_rounded,
        title: 'Sobre Você',
        subtitle: 'Vamos começar com o básico',
        children: [
          _buildPremiumInputLabel('Nome'),
          _buildPremiumTextField(_nameController, "Como você se chama?", Icons.badge_outlined),
          const SizedBox(height: 24),
          
          _buildPremiumInputLabel('Gênero'),
          _buildPremiumDropdown<String>(
            value: _selectedGender,
            hint: 'Selecione seu gênero',
            icon: Icons.wc_outlined,
            items: ['Masculino', 'Feminino'],
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
          const SizedBox(height: 24),
          
          _buildPremiumInputLabel('Data de Nascimento'),
          _buildDateSelector(),
          
          const SizedBox(height: 36),
          _buildContinueButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return SingleChildScrollView(
      child: _buildPremiumCard(
        icon: Icons.edit_note_rounded,
        title: 'Sua Bio',
        subtitle: 'Conte um pouco sobre você',
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[50]!,
                  Colors.white,
                ],
              ),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _bioController,
              maxLines: 6,
              style: const TextStyle(fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Escreva algo interessante sobre você, seus hobbies, sonhos e o que busca em um relacionamento...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: _accentGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dica: Seja autêntico! Perfis genuínos atraem mais conexões.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 36),
          _buildContinueButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      child: _buildPremiumCard(
        icon: Icons.location_on_outlined,
        title: 'Localização',
        subtitle: 'Onde você está?',
        children: [
          _buildPremiumInputLabel('Cidade'),
          _buildPremiumTextField(_cityController, 'Ex: São Paulo', Icons.location_city_outlined),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPremiumInputLabel('Estado'),
                    _buildPremiumDropdown<String>(
                      value: _selectedState,
                      hint: 'UF',
                      icon: Icons.map_outlined,
                      items: ['SP', 'RJ', 'MG', 'PR', 'RS', 'SC', 'BA', 'PE', 'CE', 'GO', 'DF'],
                      onChanged: (v) => setState(() => _selectedState = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPremiumInputLabel('País'),
                    _buildPremiumDropdown<String>(
                      value: _selectedCountry,
                      hint: 'País',
                      icon: Icons.public_outlined,
                      items: ['Brasil'],
                      onChanged: (v) => setState(() => _selectedCountry = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 36),
          _buildContinueButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return SingleChildScrollView(
      child: _buildPremiumCard(
        icon: Icons.interests_outlined,
        title: 'Interesses',
        subtitle: 'O que você gosta?',
        children: [
          Text(
            'Selecione pelo menos 3 interesses',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [_primaryColor, _secondaryColor])
                        : null,
                    color: isSelected ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        interest,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check, color: Colors.white, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: _primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${_selectedInterests.length} selecionados',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          _buildContinueButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  Widget _buildFaithStep() {
    return SingleChildScrollView(
      child: _buildPremiumCard(
        icon: Icons.church_outlined,
        title: 'Sua Fé',
        subtitle: 'Qual sua tradição cristã?',
        children: [
          _buildPremiumFaithOption('Evangélica', Icons.auto_awesome),
          const SizedBox(height: 14),
          _buildPremiumFaithOption('Católica', Icons.brightness_7_outlined),
          const SizedBox(height: 14),
          _buildPremiumFaithOption('Ortodoxa', Icons.brightness_5_outlined),
          const SizedBox(height: 14),
          _buildPremiumFaithOption('Outras Tradições Cristãs', Icons.diversity_3_outlined),
          
          const SizedBox(height: 36),
          _buildContinueButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  Widget _buildPremiumFaithOption(String title, IconData icon) {
    bool isSelected = _selectedFaith == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFaith = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryColor.withOpacity(0.1), _secondaryColor.withOpacity(0.05)],
                )
              : null,
          color: isSelected ? null : Colors.grey[50],
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [_primaryColor, _secondaryColor])
                    : null,
                color: isSelected ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[500],
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? _primaryColor : Colors.grey[700],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(colors: [_primaryColor, _secondaryColor])
                    : null,
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchStep() {
    return SingleChildScrollView(
      child: _buildPremiumCard(
        icon: Icons.groups_outlined,
        title: 'Vida na Igreja',
        subtitle: 'Conte sobre sua comunidade',
        children: [
          _buildPremiumInputLabel('Nome da Igreja'),
          _buildPremiumTextField(_churchController, 'Ex: Igreja Batista da Lagoinha', Icons.church_outlined),
          const SizedBox(height: 24),
          
          _buildPremiumInputLabel('Como você participa?'),
          _buildPremiumDropdown<String>(
            value: _selectedMinistry,
            hint: 'Selecione',
            icon: Icons.volunteer_activism_outlined,
            items: ['Participante', 'Exerço ministério', 'Trabalho Pastoral', 'Missionário', 'Outros'],
            onChanged: (val) => setState(() => _selectedMinistry = val!),
          ),
          
          const SizedBox(height: 36),
          _buildContinueButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      child: _buildPremiumCard(
        icon: Icons.photo_camera_outlined,
        title: 'Suas Fotos',
        subtitle: 'Mostre seu melhor lado',
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Adicione fotos que mostrem sua personalidade',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final bool isMain = index == 0;
              return GestureDetector(
                onTap: () {
                  // TODO: Implementar seleção de foto
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isMain
                          ? [_primaryColor.withOpacity(0.1), _secondaryColor.withOpacity(0.05)]
                          : [Colors.grey[100]!, Colors.grey[50]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMain ? _primaryColor.withOpacity(0.3) : Colors.grey[300]!,
                      width: isMain ? 2 : 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: isMain
                                  ? LinearGradient(colors: [_primaryColor, _secondaryColor])
                                  : null,
                              color: isMain ? null : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: isMain ? Colors.white : Colors.grey[500],
                              size: 22,
                            ),
                          ),
                          if (isMain) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Principal',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 36),
          _buildFinishButton('Finalizar Cadastro', _finishOnboarding),
        ],
      ),
    );
  }

  // --- Premium Helper Widgets ---

  Widget _buildPremiumCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: _primaryColor.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryColor, _secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey[200]!,
                    Colors.grey[200]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5568),
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPremiumTextField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPremiumDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          hint: Row(
            children: [
              Icon(icon, color: _primaryColor.withOpacity(0.7), size: 22),
              const SizedBox(width: 12),
              Text(hint, style: TextStyle(color: Colors.grey[400])),
            ],
          ),
          items: items.map((e) => DropdownMenuItem<T>(
            value: e as T,
            child: Row(
              children: [
                Icon(icon, color: _primaryColor.withOpacity(0.7), size: 22),
                const SizedBox(width: 12),
                Text(e),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: _primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: _primaryColor.withOpacity(0.7), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Selecione sua data de nascimento'
                    : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                style: TextStyle(
                  color: _selectedDate == null ? Colors.grey[400] : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentGold, const Color(0xFFf12711)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _accentGold.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration_outlined, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
