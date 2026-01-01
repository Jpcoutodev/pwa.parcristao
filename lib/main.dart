import 'package:flutter/material.dart';

void main() {
  runApp(const ParCristaoApp());
}

class ParCristaoApp extends StatelessWidget {
  const ParCristaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Par Cristão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const HomeScreen(),
    );
  }
}

// Modelo de perfil
class Profile {
  final String id;
  final String name;
  final int age;
  final List<String> imageUrls; // Suporte a múltiplas fotos
  final String bio;
  final String church;
  final String city;
  final List<String> interests;

  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.imageUrls,
    required this.bio,
    required this.church,
    required this.city,
    required this.interests,
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

  Widget _buildProfileTab() {
    // Perfil fictício do usuário logado para visualização
    final myProfile = Profile(
      id: 'me',
      name: 'João',
      age: 28,
      imageUrls: ['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=687&q=80', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=687&q=80'],
      bio: 'Apaixonado por música e servindo na adoração.\nBusco alguém com os mesmos propósitos.',
      church: 'Lagoinha',
      city: 'Belo Horizonte, MG',
      interests: ['Música', 'Café', 'Viagens', 'Teologia'],
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Foto de Perfil
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(myProfile.imageUrls.first),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt, color: Color(0xFF667eea), size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              
              Text(
                '${myProfile.name}, ${myProfile.age}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                myProfile.city,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              
              const SizedBox(height: 30),
              
              // Botões de Ação
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProfileActionButton(
                      Icons.edit,
                      'Editar Perfil',
                      Colors.grey[200]!,
                      Colors.black87,
                      () {
                        // Ação de editar
                        print('Editar perfil');
                      },
                    ),
                    _buildProfileActionButton(
                      Icons.visibility,
                      'Visualizar',
                      const Color(0xFF667eea).withOpacity(0.1),
                      const Color(0xFF667eea),
                      () {
                        // Navegar para ver como os outros veem
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileDetailScreen(profile: myProfile),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Card Premium
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDA4453), Color(0xFF89216B)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF89216B).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.star, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Par Cristão Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Descubra quem curtiu você e tenha likes ilimitados.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
               const SizedBox(height: 100), // Espaço final
            ],
          ),
        ),
      ),
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
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10, top: 10),
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

            // Informações do Perfil 
            // Usamos IgnorePointer para que os toques passem para as áreas de navegação se não clicar nos botões
            Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: IgnorePointer(
                ignoring: false, // Queremos que possa clicar no Ver Perfil
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          // Botão Info (Tutorial)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TutorialScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 15),

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
                                // Futuramente conectar com callback de swipe
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
                  
                  const SizedBox(height: 10),
                  
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                    
                    const SizedBox(height: 12),
                    
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
                      onPressed: () => Navigator.pop(context),
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
                      
                      const Text(
                        'Par Cristão',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                    ],
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
                  padding: const EdgeInsets.all(20),
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
                      const SizedBox(height: 20),
                      
                      // Cabeçalho (Nome, Idade, Verificado)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.profile.name}, ${widget.profile.age}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(Icons.verified, color: Colors.blue, size: 24),
                        ],
                      ),
                      
                      const SizedBox(height: 5),
                      
                      // Cidade e Igreja
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(widget.profile.city, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.church, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(widget.profile.church, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                        ],
                      ),
                      
                      const Divider(height: 40),
                      
                      // Sobre Mim
                      const Text(
                        'Sobre mim',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.profile.bio,
                        style: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.5),
                      ),
                      
                      const Divider(height: 40),
                      
                      // Interesses
                      const Text(
                        'Interesses',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: widget.profile.interests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              interest,
                              style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
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
}
