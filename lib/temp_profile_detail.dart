import 'package:flutter/material.dart';
import 'package:novo_app/main.dart'; // To access Profile class
import 'package:novo_app/chat_screen.dart'; // Import Chat Screen

class ProfileDetailScreen extends StatefulWidget {
  final Profile profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  int _currentPhotoIndex = 0;
  late PageController _photoController;

  @override
  void initState() {
    super.initState();
    _photoController = PageController();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Foto de Capa Expansível com Carrossel
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.55,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (profile.matchId != null)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              matchId: profile.matchId!,
                              targetProfile: profile,
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Foto atual
                      Image.network(
                        profile.imageUrls[_currentPhotoIndex],
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, st) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 80, color: Colors.grey),
                        ),
                      ),
                      // Gradiente para o texto sobreposto
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                            ],
                            stops: const [0.0, 0.2, 0.8, 1.0],
                          ),
                        ),
                      ),
                      // Áreas de toque para navegar (esquerda e direita)
                      if (profile.imageUrls.length > 1) ...[
                        // Toque na esquerda - foto anterior
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: GestureDetector(
                            onTap: () {
                              if (_currentPhotoIndex > 0) {
                                setState(() => _currentPhotoIndex--);
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        // Toque na direita - próxima foto
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: GestureDetector(
                            onTap: () {
                              if (_currentPhotoIndex < profile.imageUrls.length - 1) {
                                setState(() => _currentPhotoIndex++);
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                      // Indicadores de Foto (barras no topo)
                      if (profile.imageUrls.length > 1)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 50,
                          left: 20,
                          right: 20,
                          child: Row(
                            children: List.generate(
                              profile.imageUrls.length,
                              (index) => Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: index == _currentPhotoIndex 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Contador de fotos
                      if (profile.imageUrls.length > 1)
                        Positioned(
                          bottom: 30,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentPhotoIndex + 1}/${profile.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                  // Transform para puxar um pouco pra cima da imagem
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
                              '${profile.name}, ${profile.age}',
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
                          Text(profile.city, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.church, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(profile.church, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
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
                        profile.bio,
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
                        children: profile.interests.map((interest) {
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
                      
                      // Espaço extra para os botões flutuantes + safe area
                      SizedBox(height: 120 + bottomPadding),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Botões de Ação Flutuantes (com SafeArea)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 20,
                bottom: 20 + bottomPadding,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.9),
                    Colors.white,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildActionButton(Icons.close, Colors.white, Colors.redAccent, 60, () => Navigator.pop(context, 'dislike')),
                   _buildActionButton(Icons.star, Colors.white, Colors.blueAccent, 50, () => Navigator.pop(context, 'super')),
                   _buildActionButton(Icons.favorite, Colors.white, const Color(0xFF00E676), 60, () => Navigator.pop(context, 'like')),
                   if (profile.matchId != null)
                     _buildActionButton(Icons.chat, Colors.white, const Color(0xFF667eea), 60, () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => ChatScreen(
                             matchId: profile.matchId!,
                             targetProfile: profile,
                           ),
                         ),
                       );
                     }),
                ],
              ),
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
              color: echoColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: echoColor, size: size * 0.5),
      ),
    );
  }
}
