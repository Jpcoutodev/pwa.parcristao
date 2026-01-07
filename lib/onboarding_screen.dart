import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // IMPORTANTE para verificar se é Web
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:novo_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:novo_app/auth_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  // Photos
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  
  // Location
  double? _latitude;
  double? _longitude;
  bool _useManualLocation = false;
  bool _isLoadingLocation = false;

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70, 
        maxWidth: 1440,
        maxHeight: 1440,
        requestFullMetadata: false,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          if (_selectedImages.length > 6) {
             _selectedImages = _selectedImages.sublist(0, 6);
             _showError('Máximo de 6 fotos permitidas.');
          }
        });
      }
    } catch (e) {
      _showError('Erro ao selecionar fotos: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, 
        maxWidth: 1440,
        maxHeight: 1440,
        requestFullMetadata: false,
      );
      
      if (image != null) {
        setState(() {
          if (_selectedImages.length < 6) {
             _selectedImages.add(image);
          } else {
             _showError('Máximo de 6 fotos permitidas.');
          }
        });
      }
    } catch (e) {
      _showError('Erro ao tirar foto: $e');
    }
  }

  void _showImageSourceActionSheet() {
    if (kIsWeb) {
      _pickImagesFromGallery();
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Tirar Foto', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('Escolher da Galeria', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImagesFromGallery();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

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
    if (_validateCurrentStep()) {
      if (_currentPage < 7) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _finishOnboarding();
      }
    }
  }

  bool _validateCurrentStep() {
    switch (_currentPage) {
      case 0: // Welcome
        return true;
      case 1: // Basic Info
        if (_nameController.text.trim().isEmpty) {
          _showError('Por favor, informe seu nome.');
          return false;
        }
        if (_selectedGender == null) {
          _showError('Por favor, selecione seu gênero.');
          return false;
        }
        if (_selectedDate == null) {
          _showError('Por favor, informe sua data de nascimento.');
          return false;
        }
        final age = DateTime.now().year - _selectedDate!.year;
        // Ajustar se ainda não fez aniversário este ano
        final today = DateTime.now();
        final birthday = DateTime(_selectedDate!.year + age, _selectedDate!.month, _selectedDate!.day);
        final actualAge = today.isBefore(birthday) ? age - 1 : age;
        
        if (actualAge < 18) {
          _showUnderageDialog();
          return false;
        }
        return true;
      case 2: // Bio
        if (_bioController.text.trim().isEmpty) {
          _showError('Escreva um pouco sobre você.');
          return false;
        }
        return true;
      case 3: // Location
        if (_cityController.text.trim().isEmpty) {
          _showError('Informe sua cidade.');
          return false;
        }
        return true;
      case 4: // Interests
        if (_selectedInterests.length < 3) {
          _showError('Selecione pelo menos 3 interesses.');
          return false;
        }
        return true;
      case 5: // Faith
        if (_selectedFaith == null) {
          _showError('Selecione sua tradição de fé.');
          return false;
        }
        return true;
      case 6: // Church
        if (_churchController.text.trim().isEmpty) {
           _showError('Informe o nome da sua igreja ou "Nenhuma".');
           return false;
        }
        return true;
      case 7: // Photos
        if (_selectedImages.isEmpty) {
          _showError('Adicione pelo menos uma foto.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showUnderageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.block, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Acesso Restrito',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Você precisa ter 18 anos ou mais.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'App de Relacionamento',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Por se tratar de um aplicativo de relacionamento, o Par Cristão é destinado exclusivamente a maiores de 18 anos.\n\nNão é possível continuar com o cadastro.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Fazer logout
              await Supabase.instance.client.auth.signOut();
              // Redirecionar para tela de login
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Entendi',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      final supabase = Supabase.instance.client;
      
      // 1. Usar ID do usuário autenticado (login/cadastro prévio)
      final session = supabase.auth.currentSession;
      final userId = session?.user.id;
      
      if (userId == null) {
         // Se cair aqui, é porque algo deu errado no fluxo de Auth
         // Mandar de volta para Login
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(builder: (context) => const AuthScreen()),
         );
         return;
      }

      // 2. Upload de Fotos
      List<String> uploadedImageUrls = [];
      for (var i = 0; i < _selectedImages.length; i++) {
         try {
           final imageFile = _selectedImages[i];
           // Use name to safely get extension on Web (avoid blob: paths)
           final fileExt = imageFile.name.split('.').last; 
           final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.$fileExt';
           
           print('Iniciando upload da imagem $i: $fileName');
           
           // Use uploadBinary for Web/Mobile compatibility
           final bytes = await imageFile.readAsBytes();
           
           await supabase.storage.from('profile-photos').uploadBinary(
             fileName,
             bytes,
             fileOptions: const FileOptions(
               cacheControl: '3600', 
               upsert: false,
             ),
           );
           
           // Pega URL pública
           final imageUrl = supabase.storage.from('profile-photos').getPublicUrl(fileName);
           print('Upload sucesso. URL gerada: $imageUrl');
           
           uploadedImageUrls.add(imageUrl);

         } catch (e) {
            print("ERRO CRÍTICO no upload da imagem $i: $e");
            // Se der erro no upload, ignora essa imagem e segue
         }
      }
      
      print('URLs finais para salvar: $uploadedImageUrls');

      // 3. Salvar Perfil
      await supabase.from('profiles').upsert({
        'id': userId,
        'name': _nameController.text,
        'age': _selectedDate != null ? (DateTime.now().year - _selectedDate!.year) : 0,
        'gender': _selectedGender,
        'bio': _bioController.text,
        'city': _cityController.text,
        'interests': _selectedInterests,
        'faith': _selectedFaith,
        'church': _churchController.text,
        'ministry': _selectedMinistry,
        'image_urls': uploadedImageUrls, // Salva URLs das fotos
        'latitude': _latitude, // Salva coordenadas GPS (se permitido)
        'longitude': _longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Fechar loading
      if (mounted) Navigator.pop(context);

      // Navegar para TutorialScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorialScreen()),
        );
      }
    } catch (e) {
      // Fechar loading
      if (mounted) Navigator.pop(context);
      
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar perfil: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
    if (_latitude != null) {
      // Show success screen after GPS is obtained
      return SingleChildScrollView(
        child: _buildPremiumCard(
          icon: Icons.check_circle_outlined,
          title: 'Localização Confirmada!',
          subtitle: 'GPS ativado com sucesso',
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Sua localização foi detectada!',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agora você poderá ver pessoas próximas de você.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green[700], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
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
                        items: [
                          'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 
                          'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 
                          'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
                        ],
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
    
    // Initial GPS permission screen
    return SingleChildScrollView(
      child: _buildPremiumCard(
        icon: Icons.location_on_rounded,
        title: 'Ative sua Localização',
        subtitle: 'Para encontrar pessoas perto de você',
        children: [
          // Main explanation card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor.withOpacity(0.08), _secondaryColor.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.gps_fixed, color: _primaryColor, size: 35),
                ),
                const SizedBox(height: 20),
                Text(
                  'Por que precisamos do GPS?',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'O GPS é necessário para localizar pessoas próximas de você e mostrar perfis compatíveis na sua região.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Privacy assurance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.green, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua privacidade é protegida',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sua localização é usada APENAS para encontrar pessoas próximas.',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // GPS Button
          _isLoadingLocation
              ? Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Obtendo sua localização...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                )
              : Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                    ),
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
                      onTap: _requestLocationPermission,
                      borderRadius: BorderRadius.circular(16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gps_fixed, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Ativar GPS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          
          const SizedBox(height: 16),
          
          // Hint text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey[400], size: 16),
              const SizedBox(width: 6),
              Text(
                'Certifique-se de que o GPS está ligado',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _requestLocationPermission() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Serviços de localização desativados. Por favor, ative nas configurações.');
        setState(() {
          _isLoadingLocation = false;
          _useManualLocation = true;
        });
        return;
      }
      
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permissão de localização negada. Você pode digitar manualmente.');
          setState(() {
            _isLoadingLocation = false;
            _useManualLocation = true;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showError('Permissão de localização negada permanentemente. Use a opção manual.');
        setState(() {
          _isLoadingLocation = false;
          _useManualLocation = true;
        });
        return;
      }
      
      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Reverse Geocoding
      String city = '';
      String state = '';
      String country = 'Brasil';
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          
          // Cidade: locality ou subAdministrativeArea
          city = place.subAdministrativeArea?.isNotEmpty == true 
              ? place.subAdministrativeArea! 
              : (place.locality ?? '');
              
          // Estado: administrativeArea (geralmente é a sigla, ex: SP)
          state = place.administrativeArea ?? '';
          
          // Tratamento para garantir sigla (caso venha nome completo, o que é raro no geocoding android/ios p/ BR)
          // Mas vamos confiar que se estiver na lista de siglas, usamos.
          
          country = place.country ?? 'Brasil';
        }
      } catch (e) {
        print('Erro no geocoding: $e');
        // Não falha o fluxo, apenas não preenche
      }
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
        
        // Auto-fill fields
        if (city.isNotEmpty) _cityController.text = city;
        if (country == 'Brazil' || country == 'Brasil') _selectedCountry = 'Brasil';
        
        // Tenta selecionar o estado se for uma sigla válida da nossa lista
        final validStates = [
          'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 
          'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 
          'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
        ];
        
        if (validStates.contains(state)) {
          _selectedState = state;
        } else {
            // Tenta mapear nomes comuns se necessário, ou deixa o padrão
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Localização detectada com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Erro ao obter localização: $e');
      _showError('Erro ao obter localização. Tente digitar manualmente.');
      setState(() {
        _isLoadingLocation = false;
        _useManualLocation = true;
      });
    }
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
                  'Adicione fotos que mostrem sua personalidade (Min. 1)',
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
            itemCount: _selectedImages.length + 1, // +1 for the add button
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                // Add button
                if (_selectedImages.length >= 6) return const SizedBox.shrink();
                
                return GestureDetector(
                  onTap: _showImageSourceActionSheet,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: Colors.grey[400], size: 30),
                        const SizedBox(height: 4),
                        Text('Adicionar', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }

              final image = _selectedImages[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        // CORREÇÃO: Usar NetworkImage para Web (blob url) e FileImage para Mobile
                        image: kIsWeb 
                            ? NetworkImage(image.path) 
                            : FileImage(File(image.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                       bottom: 0,
                       left: 0,
                       right: 0,
                       child: Container(
                         padding: const EdgeInsets.symmetric(vertical: 4),
                         decoration: BoxDecoration(
                           color: _primaryColor.withOpacity(0.8),
                           borderRadius: const BorderRadius.only(
                             bottomLeft: Radius.circular(16),
                             bottomRight: Radius.circular(16),
                           ),
                         ),
                         child: const Text(
                           'Principal',
                           textAlign: TextAlign.center,
                           style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                         ),
                       ),
                    ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 36),
          _buildFinishButton('Finalizar Cadastro', () {
             // Validate and Finish
             if (_validateCurrentStep()) {
               _finishOnboarding();
             }
          }),
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
    // Generate lists
    final days = List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));
    final months = List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
    final currentYear = DateTime.now().year;
    final years = List.generate(100, (index) => (currentYear - 18 - index).toString());

    // Current selection breakdown
    String? day = _selectedDate?.day.toString().padLeft(2, '0');
    String? month = _selectedDate?.month.toString().padLeft(2, '0');
    String? year = _selectedDate?.year.toString();

    // Reset if year is out of range for some reason
    if (year != null && !years.contains(year)) year = null;

    return Row(
      children: [
        // DAY
        Expanded(
          flex: 2,
          child: _buildSimpleDateDropdown(
            value: day,
            hint: 'Dia',
            items: days,
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                final newDay = int.parse(val);
                final newMonth = month != null ? int.parse(month!) : 1;
                final newYear = year != null ? int.parse(year!) : (currentYear - 18);
                
                // Validate valid days in month
                final maxDays = DateTime(newYear, newMonth + 1, 0).day;
                final validDay = newDay > maxDays ? maxDays : newDay;

                _selectedDate = DateTime(newYear, newMonth, validDay);
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        
        // MONTH
        Expanded(
          flex: 2,
          child: _buildSimpleDateDropdown(
            value: month,
            hint: 'Mês',
            items: months,
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                final newMonth = int.parse(val);
                final newDay = day != null ? int.parse(day!) : 1;
                final newYear = year != null ? int.parse(year!) : (currentYear - 18);

                final maxDays = DateTime(newYear, newMonth + 1, 0).day;
                final validDay = newDay > maxDays ? maxDays : newDay;

                _selectedDate = DateTime(newYear, newMonth, validDay);
              });
            },
          ),
        ),
         const SizedBox(width: 8),
         
        // YEAR
        Expanded(
          flex: 3,
          child: _buildSimpleDateDropdown(
            value: year,
            hint: 'Ano',
            items: years,
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                final newYear = int.parse(val);
                final newMonth = month != null ? int.parse(month!) : 1;
                final newDay = day != null ? int.parse(day!) : 1;

                final maxDays = DateTime(newYear, newMonth + 1, 0).day;
                final validDay = newDay > maxDays ? maxDays : newDay;

                _selectedDate = DateTime(newYear, newMonth, validDay);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDateDropdown({
    required String? value, 
    required String hint, 
    required List<String> items, 
    required Function(String?) onChanged
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Center(child: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13))), 
          icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Center(child: Text(e, style: const TextStyle(fontSize: 14))),
          )).toList(),
          onChanged: onChanged,
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
