import 'package:flutter/material.dart';
import 'package:novo_app/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:novo_app/supabase_config.dart';
import 'package:novo_app/auth_screen.dart';
import 'package:novo_app/edit_profile_screen.dart'; // Import da tela de edição

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ParCristaoApp());
}

class ParCristaoApp extends StatelessWidget {
  const ParCristaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    final session = Supabase.instance.client.auth.currentSession;
    final initialScreen = session != null ? const HomeScreen() : const AuthScreen();

    return MaterialApp(
      title: 'Par Cristão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: initialScreen,
    );
  }
}

// Modelo de perfil
class Profile {
  final String id;
  final String name;
  final int age;
  final String? gender; // Novo: Gênero
  final List<String> imageUrls; // Suporte a múltiplas fotos
  final String bio;
  final String church;
  final String? ministry; // Novo: Ministério
  final String? faith; // Novo: Confissão de fé
  final String city;
  final List<String> interests;
  final bool isOnline;

  Profile({
    required this.id,
    required this.name,
    required this.age,
    this.gender,
    required this.imageUrls,
    required this.bio,
    required this.church,
    this.ministry,
    this.faith,
    required this.city,
    required this.interests,
    this.isOnline = false,
  });
}

// Dados de exemplo
final List<Profile> sampleProfiles = [
  Profile(
    id: '1',
    name: 'Sarah',
    age: 24,
    imageUrls: [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800', // Foto 1
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800', // Foto 2 (Placeholder)
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800', // Foto 3 (Placeholder)
    ],
    bio: 'Sou apaixonada por música e sirvo no louvor da minha igreja.\nBusco alguém que ame a Deus acima de tudo.',
    church: 'Igreja Batista Lagoinha',
    city: 'Belo Horizonte, MG',
    interests: ['Música', 'Viagens', 'Café', 'Louvor'],
    isOnline: true,
  ),
  Profile(
    id: '2',
    name: 'Lucas',
    age: 27,
    imageUrls: [
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
    ],
    bio: 'Engenheiro de software, amo ler e tocar violão.\nVersículo favorito: Filipenses 4:13',
    church: 'Assembleia de Deus',
    city: 'São Paulo, SP',
    interests: ['Tecnologia', 'Violão', 'Livros', 'Esportes'],
    isOnline: false,
  ),
  Profile(
    id: '3',
    name: 'Rebeca',
    age: 22,
    imageUrls: [
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800',
    ],
    bio: 'Estudante de Medicina. Amo servir crianças na escola dominical.\nSonho em fazer missões na África.',
    church: 'Igreja Presbiteriana',
    city: 'Rio de Janeiro, RJ',
    interests: ['Missões', 'Crianças', 'Medicina', 'Praia'],
    isOnline: true,
  ),
  Profile(
    id: '4',
    name: 'Davi',
    age: 29,
    imageUrls: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
    ],
    bio: 'Empresário, focado e determinado. Busco uma companheira para construir um lar firmado na rocha.',
    church: 'Comunidade da Graça',
    city: 'Curitiba, PR',
    interests: ['Empreendedorismo', 'Viagens', 'Gastronomia'],
  ),
  Profile(
    id: '5',
    name: 'Ester',
    age: 25,
    imageUrls: [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
    ],
    bio: 'Designer gráfica, criativa e sonhadora.\nAmo a natureza e animais.',
    church: 'Bola de Neve',
    city: 'Florianópolis, SC',
    interests: ['Design', 'Natureza', 'Animais', 'Arte'],
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Profile> profiles = List.from(sampleProfiles);
  Offset _position = Offset.zero;
  bool _isDragging = false;
  late AnimationController _animationController;
  int _selectedIndex = 0; // Índice da aba selecionada
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final status = _getSwipeStatus();
    
    if (status != SwipeStatus.none) {
      _animateAndRemove(status);
    } else {
      _resetPosition();
    }
  }

  SwipeStatus _getSwipeStatus() {
    final x = _position.dx;
    const threshold = 60.0; // Mais sensível (era 100.0)
    
    if (x > threshold) return SwipeStatus.like;
    if (x < -threshold) return SwipeStatus.dislike;
    return SwipeStatus.none;
  }

  void _animateAndRemove(SwipeStatus status) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = status == SwipeStatus.like ? screenWidth * 1.5 : -screenWidth * 1.5;
    
    final animation = Tween<Offset>(
      begin: _position,
      end: Offset(targetX, _position.dy),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.reset();
    animation.addListener(() {
      setState(() {
        _position = animation.value;
      });
    });

    _animationController.forward().then((_) {
      setState(() {
        if (profiles.isNotEmpty) {
          profiles.removeLast();
        }
        _position = Offset.zero;
        _isDragging = false;
      });
    });
  }

  void _resetPosition() {
    final animation = Tween<Offset>(
      begin: _position,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.reset();
    animation.addListener(() {
      setState(() {
        _position = animation.value;
      });
    });

    _animationController.forward().then((_) {
      setState(() {
        _isDragging = false;
      });
    });
  }

  void _onLike() {
    setState(() {
      _position = const Offset(150, 0);
    });
    _animateAndRemove(SwipeStatus.like);
  }

  void _onDislike() {
    setState(() {
      _position = const Offset(-150, 0);
    });
    _animateAndRemove(SwipeStatus.dislike);
  }

  void _onSuperLike() {
    setState(() {
      _position = const Offset(0, -150);
    });
    
    final animation = Tween<Offset>(
      begin: _position,
      end: const Offset(0, -800),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.reset();
    animation.addListener(() {
      setState(() {
        _position = animation.value;
      });
    });

    _animationController.forward().then((_) {
      setState(() {
        if (profiles.isNotEmpty) {
          profiles.removeLast();
        }
        _position = Offset.zero;
        _isDragging = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos IndexedStack para manter o estado das abas
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildSwipeTab(),     // 0: Cards
          _buildMatchesTab(),   // 1: Curtidas Mútuas
          _buildMessagesTab(),  // 2: Mensagens
          _buildProfileTab(),   // 3: Perfil
          _buildSettingsTab(),  // 4: Configurações (NOVO)
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Sombra bem suave
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent, // Transparente pois o Container já tem cor
          selectedItemColor: const Color(0xFF667eea), // Azul/Roxo vibrante
          unselectedItemColor: Colors.grey[400], // Cinza claro para os inativos
          showUnselectedLabels: false, // Minimalista: esconde texto dos não selecionados
          showSelectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0 ? Icons.style : Icons.style_outlined),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(_selectedIndex == 1 ? Icons.favorite : Icons.favorite_border),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5), // Borda branca para destacar
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Interesse',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2 ? Icons.chat_bubble : Icons.chat_bubble_outline),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 3 ? Icons.person : Icons.person_outline),
              label: 'Perfil',
            ),
            // Nova aba Configurações
            BottomNavigationBarItem(
              // Usando tune_rounded para um visual mais 'ajuste'
              icon: Icon(_selectedIndex == 4 ? Icons.tune_rounded : Icons.tune_outlined),
              label: 'Config',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeTab() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
      ),
      child: Stack(
        children: [
          profiles.isEmpty
              ? _buildEmptyState()
              : _buildCardStack(),
        ],
      ),
    );
  }
  
  // ... (Matches, Messages, Profile Tabs mantidos iguais - omitidos para brevidade)

  Widget _buildMatchesTab() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Interesses',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Color(0xFF667eea),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF667eea),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Recebidos'), // Interesses (Quem curtiu você)
              Tab(text: 'Mútuos'),    // Match (Os dois)
              Tab(text: 'Super'),     // Super Like
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInterestGrid(status: 'recebidos'),
            _buildInterestGrid(status: 'mutuos'),
            _buildInterestGrid(status: 'super'),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestGrid({required String status}) {
    // Filtrando ou criando dados fictícios baseados no status
    // Na prática viria do backend. Usando sampleProfiles para demo.
    final List<Profile> displayProfiles = List.from(sampleProfiles)..shuffle();
    final bool isMutuo = status == 'mutuos';
    final bool isSuper = status == 'super';

    if (displayProfiles.isEmpty) {
      return const Center(child: Text('Nenhum interesse ainda.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 colunas
        childAspectRatio: 0.75, // Altura > Largura (Retrato)
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: displayProfiles.length,
      itemBuilder: (context, index) {
        final profile = displayProfiles[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[200],
            image: DecorationImage(
              image: NetworkImage(profile.imageUrls.first),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Gradiente para texto
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              
              // Nome e Idade
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMutuo) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.favorite, color: Colors.greenAccent, size: 14)
                        ]
                      ],
                    ),
                    Text(
                      '${profile.age} anos',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Badges (Super Like, Novo)
              if (isSuper)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, color: Colors.white, size: 16),
                  ),
                ),
                
              // Efeito Blur se for "Recebidos" (Premium feature comum) - opcional, vou deixar visível por enquanto
              // Mas poderia ser blurado para instigar assinatura.
            ],
          ),
        );
      },
    );
  }

  // --- Aba de Chat (Mensagens) ---
  Widget _buildMessagesTab() {
    // Dados Fictícios de Conversas
    final conversations = [
      {'profile': sampleProfiles[0], 'msg': 'Oie! Tudo bem? Vi que também gosta de música!', 'time': '10:30', 'count': 2},
      {'profile': sampleProfiles[1], 'msg': 'A paz! Qual igreja você frequenta?', 'time': 'Ontem', 'count': 0},
      {'profile': sampleProfiles[2], 'msg': 'Vamos marcar aquele café?', 'time': 'Seg', 'count': 1},
    ];

    // matches recentes (usando os ultimos do sample)
    final recentMatches = sampleProfiles.reversed.take(5).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mensagens',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.grey)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção: Novos Matches
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Novos Matches',
                style: TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: recentMatches.length,
                itemBuilder: (context, index) {
                  final profile = recentMatches[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(profile.imageUrls.first),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          profile.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const Divider(height: 30),
            
            // Seção: Mensagens
             const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Text(
                'Conversas',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(), // Scroll controlado pelo pai
              shrinkWrap: true,
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(indent: 80, height: 1),
              itemBuilder: (context, index) {
                final chat = conversations[index];
                final profile = chat['profile'] as Profile;
                final unreadCount = chat['count'] as int;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(profile.imageUrls.first),
                      ),
                      if (index == 0) // Exemplo de 'Online'
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    profile.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    chat['msg'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat['time'] as String,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF667eea),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Abrir tela de chat individual
                    print('Abrir chat com ${profile.name}');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Profile?> _getMyProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      final data = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
      if (data == null) return null;
      
      // Parse Imagens
      List<String> images = [];
      if (data['image_urls'] != null) {
        images = List<String>.from(data['image_urls']);
      }
      
      return Profile(
        id: data['id'],
        name: data['name'] ?? '',
        age: data['age'] ?? 0,
        gender: data['gender'],
        imageUrls: images,
        bio: data['bio'] ?? '',
        church: data['church'] ?? '',
        ministry: data['ministry'],
        faith: data['faith'],
        city: data['city'] ?? '',
        interests: List<String>.from(data['interests'] ?? []),
      );
    } catch (e) {
      print('Erro ao carregar perfil: $e');
      return null;
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    // Se retornou true, atualiza
    if (result == true) {
      setState(() {
        // Força rebuild do FutureBuilder
      });
    }
  }

  Widget _buildProfileTab() {
    return FutureBuilder<Profile?>(
      future: _getMyProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Se não houver perfil (não fez onboarding ou erro), usa o mock/default ou mostra mensagem
        final myProfile = snapshot.data ?? Profile(
          id: 'me',
          name: 'Usuário',
          age: 0,
          gender: '',
          imageUrls: [],
          bio: 'Complete seu cadastro!',
          church: '',
          city: '',
          interests: [],
        );

        final mainImage = myProfile.imageUrls.isNotEmpty 
            ? myProfile.imageUrls.first 
            : 'https://placehold.co/600x400/png?text=Sem+Foto';

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header com gradiente
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Título e Botão Editar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Meu Perfil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: _navigateToEditProfile,
                                tooltip: 'Editar Perfil',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundImage: NetworkImage(mainImage),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF667eea), size: 22),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 18),
                    
                    // Nome e Idade
                    Text(
                      '${myProfile.name}, ${myProfile.age}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Localização
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.9), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          myProfile.city,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Botões de Ação
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProfileHeaderButton(
                          Icons.edit_outlined,
                          'Editar',
                          _navigateToEditProfile,
                        ),
                        const SizedBox(width: 20),
                        _buildProfileHeaderButton(
                          Icons.visibility_outlined,
                          'Visualizar',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileDetailScreen(profile: myProfile),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildProfileHeaderButton(
                          Icons.settings_outlined,
                          'Ajustes',
                          () {
                            setState(() => _selectedIndex = 4);
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Seção: Sobre Mim
              _buildProfileSection(
                icon: Icons.person_outline_rounded,
                title: 'Sobre Mim',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myProfile.bio,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    if (myProfile.gender != null) ...[
                      const SizedBox(height: 16),
                      _buildProfileInfoRow(Icons.wc_outlined, 'Gênero', myProfile.gender!),
                    ],
                  ],
                ),
              ),
              
              // Seção: Igreja e Fé
              _buildProfileSection(
                icon: Icons.church_outlined,
                title: 'Igreja e Fé',
                child: Column(
                  children: [
                    _buildProfileInfoRow(Icons.home_outlined, 'Igreja', myProfile.church),
                    if (myProfile.faith != null) ...[
                      const SizedBox(height: 14),
                      _buildProfileInfoRow(Icons.auto_awesome_outlined, 'Confissão', myProfile.faith!),
                    ],
                    if (myProfile.ministry != null) ...[
                      const SizedBox(height: 14),
                      _buildProfileInfoRow(Icons.volunteer_activism_outlined, 'Participação', myProfile.ministry!),
                    ],
                  ],
                ),
              ),
              
              // Seção: Interesses
              _buildProfileSection(
                icon: Icons.interests_outlined,
                title: 'Interesses',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: myProfile.interests.map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667eea).withOpacity(0.1),
                            const Color(0xFF764ba2).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        interest,
                        style: const TextStyle(
                          color: Color(0xFF667eea),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // Card Premium
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFf5af19), Color(0xFFf12711)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFf12711).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Par Cristão Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Descubra quem curtiu você!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFf12711), size: 20),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Estatísticas
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProfileStat('Curtidas', '24', Icons.favorite_outline),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    _buildProfileStat('Matches', '8', Icons.people_outline),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    _buildProfileStat('Fotos', '${myProfile.imageUrls.length}', Icons.photo_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Botão de Sair
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saindo...'), duration: Duration(seconds: 1)),
                    );

                    try {
                      await Supabase.instance.client.auth.signOut();
                    } catch (e) {
                      print("Erro no signOut (ignorado para forçar saída): $e");
                    }

                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text(
                    'Sair da Conta',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildProfileHeaderButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF667eea), size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF667eea), size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActionButton(IconData icon, String label, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Card do topo (arrastável) - Agora só precisamos desenhar o último card para visual full screen eficiente
        // Se quiser manter o efeito de "pilha", desenhamos o penúltimo embaixo
        if (profiles.length > 1)
           ProfileCard(profile: profiles[profiles.length - 2], isTop: false),
           
        if (profiles.isNotEmpty)
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _position,
              child: Transform.rotate(
                angle: _position.dx / 250, // Mais rotação (era 1000)
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // O Card Principal
                    ProfileCard(profile: profiles.last, isTop: true),
                    
                    // Overlay de LIKE
                    if (_position.dx > 50)
                      _buildStatusOverlay('LIKE', Colors.green, 100, true),
                    // Overlay de NOPE
                    if (_position.dx < -50)
                      _buildStatusOverlay('NOPE', Colors.red, 100, false),
                  ],
                ),
              ),
            ),
          ),
          
        // Botões de Ação SOBREPOSTOS na parte inferior
        if (profiles.isNotEmpty)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: _buildActionButtons(),
          ),
      ],
    );
  }
  
  Widget _buildStatusOverlay(String text, Color color, double top, bool isRight) {
    return Positioned(
      top: top,
      left: isRight ? 30 : null,
      right: isRight ? null : 30,
      child: Transform.rotate(
        angle: isRight ? -0.3 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Por enquanto é só!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              setState(() {
                profiles = List.from(sampleProfiles);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF764ba2),
            ),
            child: const Text('Recarregar'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botão Voltar
          _buildCircleButton(
            icon: Icons.refresh,
            color: Colors.amber,
            size: 50,
            iconSize: 24,
            onPressed: () {},
          ),
          // Botão Dislike
          _buildCircleButton(
            icon: Icons.close,
            color: const Color(0xFFFF5252), // Vermelho vibrante
            size: 65,
            iconSize: 32,
            onPressed: profiles.isEmpty ? null : _onDislike,
            hasShadow: true,
          ),
          // Botão Super Like
          _buildCircleButton(
            icon: Icons.star,
            color: Colors.blueAccent,
            size: 50,
            iconSize: 24,
            onPressed: profiles.isEmpty ? null : _onSuperLike,
          ),
          // Botão Like
          _buildCircleButton(
            icon: Icons.favorite,
            color: const Color(0xFF00E676), // Verde vibrante
            size: 65,
            iconSize: 32,
            onPressed: profiles.isEmpty ? null : _onLike,
            hasShadow: true,
          ),
           // Botão Mensagem (Substituindo o Bolt)
          _buildCircleButton(
            icon: Icons.message_rounded, // Ícone de mensagem
            color: Colors.purpleAccent,
            size: 50,
            iconSize: 22,
            onPressed: () {
              // TODO: Implementar envio de mensagem direta
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    VoidCallback? onPressed,
    bool hasShadow = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), // Leve transparência para mesclar
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            if (hasShadow)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Icon(
          icon,
          color: onPressed == null ? Colors.grey : color,
          size: iconSize,
        ),
      ),
    );
  }

  // -- NOVA ABA: CONFIGURAÇÕES --
  Widget _buildSettingsTab() {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fundo levemente cinza
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Configurações',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildSectionHeader('Conta'),
                  _buildSettingsTile(Icons.phone, 'Número de Telefone'),
                  _buildSettingsTile(Icons.email, 'Email Conectado'),
                  _buildSectionHeader('Preferências'),
                  _buildSettingsTile(Icons.location_on, 'Localização'),
                  _buildSettingsTile(Icons.notifications, 'Notificações', hasSwitch: true),
                  _buildSettingsTile(Icons.visibility, 'Mostrar-me no Par Cristão', hasSwitch: true),
                  _buildSectionHeader('Legal'),
                  _buildSettingsTile(Icons.description, 'Termos de Serviço'),
                  _buildSettingsTile(Icons.privacy_tip, 'Política de Privacidade'),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Sair da Conta'),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'Versão 1.0.0',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
  
  Widget _buildSettingsTile(IconData icon, String title, {bool hasSwitch = false}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: hasSwitch 
            ? Switch(value: true, onChanged: (v){}, activeColor: const Color(0xFF667eea))
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}

enum SwipeStatus { none, like, dislike, superLike }

class ProfileCard extends StatefulWidget {
  final Profile profile;
  final bool isTop;

  const ProfileCard({super.key, required this.profile, required this.isTop});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _currentImageIndex = 0;

  void _nextImage() {
    if (_currentImageIndex < widget.profile.imageUrls.length - 1) {
      setState(() {
        _currentImageIndex++;
      });
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10, top: 25), // Aumentado top margin
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagem de fundo
             Image.network(
                widget.profile.imageUrls[_currentImageIndex],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.person, size: 100, color: Colors.grey),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),

            // Gradiente Escuro
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3), // Um pouco mais escuro em cima tb pro slider
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
            
            // Indicadores de Foto (Sliders)
            if (widget.profile.imageUrls.length > 1)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: List.generate(widget.profile.imageUrls.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Áreas de toque para navegação (Só ativa se for o card do topo)
            if (widget.isTop)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTapUp: (details) => _previousImage(),
                    behavior: HitTestBehavior.translucent,
                    child: Container(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTapUp: (details) => _nextImage(),
                    behavior: HitTestBehavior.translucent,
                    child: Container(),
                  ),
                ),
              ],
            ),

            // Botão Help no Topo Direito (Movido para cá)
            Positioned(
              top: 20, // Espaço do topo
              right: 20, // Espaço da direita
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TutorialScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3), // Fundo mais escuro para contraste
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Informações do Perfil 
            // Usamos IgnorePointer para que os toques passem para as áreas de navegação se não clicar nos botões
            Positioned(
              bottom: 120, // Moved up to clear buttons
              left: 20,
              right: 20,
              child: IgnorePointer(
                ignoring: false, // Queremos que possa clicar no Ver Perfil
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.profile.isOnline)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ON LINE',
                              style: TextStyle(
                                color: const Color(0xFF00E676),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(offset: const Offset(0, 1), blurRadius: 4.0, color: Colors.black.withOpacity(0.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${widget.profile.name}, ${widget.profile.age}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(offset: Offset(0, 1), blurRadius: 4.0, color: Colors.black),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 24,
                                shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                              ),
                            ],
                          ),
                        ),
                         // Lado Direito: Botões de Ação (Info e Olho)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botão Olho (Ver Perfil Completo)
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileDetailScreen(profile: widget.profile),
                                ),
                              );
                              
                              if (result != null) {
                                print('Ação retornada do detalhe: $result');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.profile.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        const Icon(Icons.church, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.profile.church,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.profile.city,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      widget.profile.bio.split('\n').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header com Botão Fechar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Guia do App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Card de Gestos
                      _buildInfoCard(
                        title: 'Comandos de Deslize',
                        children: [
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                               _buildGuideItem(Icons.swipe_left, 'Pular', Colors.redAccent),
                               Container(width: 1, height: 50, color: Colors.white24),
                               _buildGuideItem(Icons.swipe_right, 'Curtir', Colors.greenAccent),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Card de Botões
                      _buildInfoCard(
                        title: 'Ações Principais',
                        children: [
                          _buildGuideRow(Icons.star, 'Super Like', 'Destaca seu perfil para a pessoa.', iconColor: Colors.blueAccent),
                          const Divider(color: Colors.white12, height: 20),
                          _buildGuideRow(Icons.favorite, 'Like', 'Demonstra interesse em conhecer.', iconColor: const Color(0xFF00E676)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Card de Navegação
                      _buildInfoCard(
                        title: 'Navegação e Detalhes',
                        children: [
                          _buildGuideRow(Icons.touch_app, 'Fotos', 'Toque nos lados da foto para ver mais.'),
                          const Divider(color: Colors.white12, height: 20),
                          _buildGuideRow(Icons.visibility, 'Perfil Completo', 'Veja a bio, igreja e mais detalhes.'),
                          const Divider(color: Colors.white12, height: 20),
                          _buildGuideRow(Icons.message_rounded, 'Mensagem', 'Envie uma mensagem direta.'),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              
              // Botão para ir para a Home
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      ),
                      borderRadius: BorderRadius.circular(30),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ).createShader(bounds),
                              child: const Text(
                                'Começar a Explorar',
                                style: TextStyle(
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
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildGuideItem(IconData icon, String title, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  Widget _buildGuideRow(IconData icon, String title, String subtitle, {Color iconColor = Colors.white}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileDetailScreen extends StatefulWidget {
  final Profile profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Foto de Capa Expansível (Carrossel)
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.55,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Carrossel de Imagens
                      PageView.builder(
                        itemCount: widget.profile.imageUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.profile.imageUrls[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      
                      // Gradiente de Proteção (Topo e Base)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                            stops: const [0.0, 0.2, 0.7, 1.0],
                          ),
                        ),
                      ),
                      
                      // Indicadores de Página (Pontinhos)
                      Positioned(
                        bottom: 40, // Acima da borda branca arredondada
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.profile.imageUrls.map((url) {
                            int index = widget.profile.imageUrls.indexOf(url);
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conteúdo do Perfil
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Cabeçalho (Nome, Idade, Verificado)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${widget.profile.name}, ${widget.profile.age}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.verified, color: Colors.blue, size: 20),
                                    ),
                                  ],
                                ),
                                if (widget.profile.gender != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.profile.gender!,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Localização e Igreja - Cards compactos
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoChip(Icons.location_on_outlined, widget.profile.city),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Seção: Sobre Mim
                      _buildDetailSection(
                        icon: Icons.person_outline_rounded,
                        title: 'Sobre mim',
                        child: Text(
                          widget.profile.bio,
                          style: TextStyle(color: Colors.grey[700], fontSize: 15, height: 1.6),
                        ),
                      ),
                      
                      // Seção: Igreja e Fé
                      _buildDetailSection(
                        icon: Icons.church_outlined,
                        title: 'Igreja e Fé',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailInfoRow(Icons.home_outlined, 'Igreja', widget.profile.church),
                            if (widget.profile.faith != null) ...[
                              const SizedBox(height: 12),
                              _buildDetailInfoRow(Icons.auto_awesome_outlined, 'Confissão', widget.profile.faith!),
                            ],
                            if (widget.profile.ministry != null) ...[
                              const SizedBox(height: 12),
                              _buildDetailInfoRow(Icons.volunteer_activism_outlined, 'Participação', widget.profile.ministry!),
                            ],
                          ],
                        ),
                      ),
                      
                      // Seção: Interesses
                      _buildDetailSection(
                        icon: Icons.interests_outlined,
                        title: 'Interesses',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: widget.profile.interests.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF667eea).withOpacity(0.1),
                                    const Color(0xFF764ba2).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF667eea).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Botões de Ação FLUTUANTES (Fixos na tela)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                 _buildActionButton(Icons.close, Colors.white, Colors.redAccent, 60, () => Navigator.pop(context, 'dislike')),
                 _buildActionButton(Icons.star, Colors.white, Colors.blueAccent, 50, () => Navigator.pop(context, 'super')),
                 _buildActionButton(Icons.favorite, Colors.white, const Color(0xFF00E676), 60, () => Navigator.pop(context, 'like')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color iconColor, Color echoColor, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: echoColor, size: size * 0.5),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF667eea)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF667eea), size: 18),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
