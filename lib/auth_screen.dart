import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:novo_app/main.dart'; // Para HomeScreen
import 'package:novo_app/onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    print('Botão clicado! Iniciando_submit...'); // Debug
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    print('Dados: Email=$email, Pass=${password.isEmpty ? "Vazio" : "***"}'); // Debug

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor, preencha todos os campos obrigatórios.');
      return;
    }

    if (!_isLogin) {
      final confirmPassword = _confirmPasswordController.text.trim();
      if (confirmPassword != password) {
         _showError('As senhas não coincidem.');
         return;
      }
      if (password.length < 6) {
        _showError('A senha deve ter pelo menos 6 caracteres.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      if (_isLogin) {
        // --- LOGIN ---
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        _checkProfileAndNavigate();
      } else {
        // --- CADASTRO ---
        print('Tentando cadastrar: $email');
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        
        print('Resposta do cadastro: User=${response.user}, Session=${response.session}');
        
        if (mounted) {
          if (response.session != null) {
            print('Sessão criada! Navegando para Onboarding...');
            // Cadastro e login automáticos (Email Confirm desligado)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          } else if (response.user != null) {
            print('Usuário criado, mas sem sessão. Verificação de email pode estar ativa?');
            // Usuário criado, mas precisa confirmar email
            _showSuccess('Conta criada com sucesso! Faça login para continuar.');
            setState(() {
              _isLogin = true; // Volta para tela de login
              _isLoading = false;
            });
          } else {
            print('Erro: Usuário e Sessão são nulos após cadastro.');
            _showError('Erro ao criar conta. Tente novamente.');
          }
        }
      }
    } on AuthException catch (e) {
      print('AuthException: ${e.message} - Code: ${e.statusCode}');
      _showError('Erro de Autenticação: ${e.message}');
    } catch (e) {
      print('Erro genérico: $e');
      _showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ops!', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sucesso!', style: TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ótimo!'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkProfileAndNavigate() async {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final profileToCheck = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (mounted) {
          if (profileToCheck != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          
          // Decorative Elements (Bubbles)
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  left: -50,
                  child: _buildGlassBubble(200, opacity: 0.1),
                ),
                Positioned(
                  bottom: -80,
                  right: -20,
                  child: _buildGlassBubble(250, opacity: 0.08),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isLogin ? 'Bem-vindo de volta!' : 'Criar Nova Conta',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? 'Entre para continuar sua jornada'
                            : 'Comece sua história de amor hoje',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _emailController,
                              label: 'E-mail',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Senha',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),
                            
                            // Campo Confirmar Senha (Só no cadastro)
                            if (!_isLogin) ...[
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirmar Senha',
                                icon: Icons.lock_reset_rounded,
                                isPassword: true,
                              ),
                            ],
                            
                            const SizedBox(height: 30),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  print('ElevatedButton onPressed chamado!');
                                  if (!_isLoading) _submit();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF667eea),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  shadowColor: const Color(0xFF667eea).withOpacity(0.5),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        _isLogin ? 'ENTRAR' : 'CADASTRAR',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      
                      // Toggle Login/Signup
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _animationController.reset();
                            _animationController.forward();
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            text: _isLogin ? 'Não tem uma conta? ' : 'Já tem uma conta? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: _isLogin ? 'Cadastre-se' : 'Entrar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
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
    );
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
            Colors.white.withOpacity(0),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
