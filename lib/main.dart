import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:novo_app/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:novo_app/supabase_config.dart';
import 'package:novo_app/auth_screen.dart';
import 'package:novo_app/edit_profile_screen.dart';
import 'package:novo_app/temp_profile_detail.dart';
import 'package:novo_app/chat_screen.dart';
import 'package:novo_app/verification_screen.dart';
import 'package:novo_app/banned_screen.dart';
import 'package:novo_app/platform_utils.dart'; // Platform utilities
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart'; // Better web support

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloqueia a orientação apenas para retrato (vertical) - apenas em plataformas nativas
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ParCristaoApp());
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndProfile();
  }

  Future<void> _checkSessionAndProfile() async {
    // Wait for a moment to show the splash/loading (optional, prevents flicker)
    await Future.delayed(const Duration(milliseconds: 500));

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
      return;
    }

    try {
      final userId = session.user.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('name, image_urls, is_banned')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
         // Profile doesn't exist at all -> Onboarding
         if (mounted) {
           Navigator.of(context).pushReplacement(
             MaterialPageRoute(builder: (_) => const OnboardingScreen()),
           );
         }
         return;
      }

      final name = data['name'] as String?;
      final imageUrls = (data['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
      final isBanned = data['is_banned'] as bool? ?? false;

      // Check if user is banned - redirect to banned screen
      if (isBanned) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BannedScreen()),
          );
        }
        return;
      }

      // Check if profile is incomplete (missing name or photos)
      if (name == null || name.isEmpty || imageUrls.isEmpty) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      } else {
        // Profile complete -> Home
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      print('Error checking profile: $e');
      // On error, default to Auth to be safe
       if (mounted) {
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => const AuthScreen()),
         );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF667eea)),
            SizedBox(height: 20),
            Text('Carregando...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
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
      home: const StartupScreen(),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: child!,
          ),
        );
      },
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
  final double? latitude; // Novo: Latitude para cálculo de distância
  final double? longitude; // Novo: Longitude para cálculo de distância
  final String? matchId; // Match ID for chat/delete functionality
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isSuperLike; // Novo campo para identificar Super Like
  final bool isVerified; // Novo: Indica se o perfil é verificado
  final String? verificationStatus; // Novo: status da solicitação (pending, rejected, etc)
  final String? verificationRejectionReason; // Novo: motivo da rejeição

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
    this.latitude,
    this.longitude,
    this.matchId,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageTime,
    this.isSuperLike = false,
    this.isVerified = false,
    this.verificationStatus,
    this.verificationRejectionReason,
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
  List<Profile> profiles = [];
  bool _isLoading = true;
  Offset _position = Offset.zero;
  bool _isDragging = false;
  late AnimationController _animationController;
  int _selectedIndex = 0; // Índice da aba selecionada
  
  // Search preferences
  double _searchRadius = 500.0;
  RangeValues _ageRange = const RangeValues(18, 75);
  Set<String> _religionFilters = {'Católica', 'Evangélica', 'Ortodoxa', 'Outras denominações cristãs'};
  
  // Location tracking
  bool _hasLocation = false;
  bool _isCheckingLocation = true;
  
  // Pagination
  int _profileOffset = 0;
  bool _hasMoreProfiles = true;
  bool _isLoadingMore = false;
  
  // Notifications
  int _notificationCount = 0; // Contagem de notificações de interesse
  int _messagesNotificationCount = 0; // Contagem de mensagens não lidas
  // Cache for interest futures to prevent re-fetching on every build
  final Map<String, Future<List<Profile>>> _interestFutures = {};
  
  // Real-time subscription for matches
  RealtimeChannel? _matchesChannel;
  RealtimeChannel? _likesChannel;
  RealtimeChannel? _superLikesChannel;
  RealtimeChannel? _messagesChannel; // Subscription para mensagens
  
  // Audio player for notification sounds
  final AudioPlayer _notificationPlayer = AudioPlayer();
  bool _soundEnabled = true; // Sound notifications enabled by default
  bool _hapticEnabled = true; // Haptic feedback enabled by default
  


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchProfiles();
    _checkUserLocation();
    _fetchNotificationCount();
    _checkMissedMatches();
    _subscribeToMatches(); // Subscribe to real-time match updates
    _loadSettings(); // Load persisted settings
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _checkMissedMatches() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ _checkMissedMatches: No user logged in');
        return;
      }

      print('🔍 Checking for unseen matches for user: $userId');

      // Check for matches where I am user1 and haven't seen it (unlikely with current logic but good for safety)
      // OR I am user2 and haven't seen it (common case)
      
      final unseenMatches = await supabase
          .from('matches')
          .select('*, p1:profiles!matches_user1_id_fkey(*), p2:profiles!matches_user2_id_fkey(*)')
          .or('and(user1_id.eq.$userId,user1_seen.eq.false),and(user2_id.eq.$userId,user2_seen.eq.false)');
      
      print('📊 Found ${(unseenMatches as List).length} unseen matches');
      
      if (unseenMatches != null && unseenMatches.isNotEmpty) {
        for (var match in unseenMatches) {
          final matchId = match['id'];
          final isUser1 = match['user1_id'] == userId;
          final targetData = isUser1 ? match['p2'] : match['p1'];
          final columnToUpdate = isUser1 ? 'user1_seen' : 'user2_seen';
          
          print('💡 Processing match $matchId (I am ${isUser1 ? "user1" : "user2"})');
          
          if (targetData != null) {
            final targetProfile = _mapProfile(targetData);
            
            // CRITICAL: Mark as seen FIRST, before showing dialog
            // This prevents the notification from appearing again if user closes app during animation
            try {
              print('💾 Marking match $matchId as seen ($columnToUpdate = true)...');
              
              final updateResult = await supabase
                  .from('matches')
                  .update({columnToUpdate: true})
                  .eq('id', matchId)
                  .select(); // Use .select() to verify the update worked
              
              print('✅ Match $matchId marked as seen successfully');
              print('   Update result: $updateResult');
              
              // Verify the update by checking the value
              if (updateResult != null && (updateResult as List).isNotEmpty) {
                final updatedMatch = updateResult[0];
                final seenValue = updatedMatch[columnToUpdate];
                if (seenValue == true) {
                  print('✅ Verified: $columnToUpdate is now true');
                } else {
                  print('⚠️ WARNING: $columnToUpdate is still $seenValue after update!');
                }
              }
              
            } catch (updateError) {
              print('❌ ERROR updating match $matchId: $updateError');
              // Don't show the dialog if we couldn't mark it as seen
              // This prevents the match from being shown repeatedly
              continue;
            }
            
            if (mounted) {
              // Now show the dialog
              print('🎉 Showing match dialog for ${targetProfile.name}');
              _showReciprocalInterestDialog(targetProfile);
              
              // Break after one to avoid UI chaos. Ideally, we'd queue them.
              break; 
            }
          }
        }
      } else {
        print('✅ No unseen matches found');
      }
    } catch (e) {
      print('❌ ERROR in _checkMissedMatches: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Subscribe to real-time match updates
  /// This will show an instant notification when someone likes you back
  void _subscribeToMatches() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      print('⚠️ _subscribeToMatches: No user logged in');
      return;
    }

    print('🔔 Subscribing to real-time match updates for user: $userId');

    _matchesChannel = supabase
        .channel('matches_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user2_id',
            value: userId,
          ),
          callback: (payload) async {
            print('🎉 REAL-TIME: New match detected!');
            print('   Payload: ${payload.newRecord}');
            
            final matchData = payload.newRecord;
            final matchId = matchData['id'];
            final user1Id = matchData['user1_id'];
            
            try {
              // Fetch the profile of the person who created the match
              final profileData = await supabase
                  .from('profiles')
                  .select()
                  .eq('id', user1Id)
                  .maybeSingle();
              
              if (profileData != null && mounted) {
                final targetProfile = _mapProfile(profileData);
                
                // Mark this match as seen immediately
                print('💾 Marking new match $matchId as seen (user2_seen = true)...');
                await supabase
                    .from('matches')
                    .update({'user2_seen': true})
                    .eq('id', matchId);
                
                print('🎉 Showing real-time match dialog for ${targetProfile.name}');
                _showReciprocalInterestDialog(targetProfile);
                
                // Refresh interest cache
                _interestFutures.clear();
              }
            } catch (e) {
              print('❌ ERROR handling real-time match: $e');
            }
          },
        )
        .subscribe();

    print('✅ Real-time match subscription active');
    
    // Subscribe to likes
    _subscribeToLikes();
    
    // Subscribe to super likes
    _subscribeToSuperLikes();
    
    // Subscribe to messages
    _subscribeToMessages();
  }

  /// Subscribe to real-time likes
  void _subscribeToLikes() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    print('💖 Subscribing to real-time likes for user: $userId');

    _likesChannel = supabase
        .channel('likes_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'likes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'liked_id',
            value: userId,
          ),
          callback: (payload) async {
            print('💖 REAL-TIME: Someone liked you!');
            print('   Payload: ${payload.newRecord}');
            
            final likeData = payload.newRecord;
            final likerId = likeData['liker_id'];
            
            try {
              final profileData = await supabase
                  .from('profiles')
                  .select()
                  .eq('id', likerId)
                  .maybeSingle();
              
              if (profileData != null && mounted) {
                final likerProfile = _mapProfile(profileData);
                
                // CHECK IF THIS IS A RECIPROCAL LIKE (I already liked them)
                final myLike = await supabase
                    .from('likes')
                    .select()
                    .eq('liker_id', userId)
                    .eq('liked_id', likerId)
                    .maybeSingle();
                
                final mySuper = await supabase
                    .from('super_likes')
                    .select()
                    .eq('liker_id', userId)
                    .eq('liked_id', likerId)
                    .maybeSingle();
                
                final isReciprocal = (myLike != null || mySuper != null);
                print('DEBUG: Is reciprocal like? $isReciprocal');
                
                if (isReciprocal) {
                  // IT'S A MATCH! Create match automatically
                  print('💖 RECIPROCAL MATCH DETECTED!');
                  
                  // Check if match already exists
                  final existingMatch = await supabase
                      .from('matches')
                      .select()
                      .or('and(user1_id.eq.$userId,user2_id.eq.$likerId),and(user1_id.eq.$likerId,user2_id.eq.$userId)')
                      .limit(1)
                      .maybeSingle();
                  
                  if (existingMatch == null) {
                    // Create the match
                    await supabase.from('matches').insert({
                      'user1_id': userId,
                      'user2_id': likerId,
                      'created_at': DateTime.now().toIso8601String(),
                      'user1_seen': true, // I'm seeing it now
                      'user2_seen': false, // They haven't seen it yet
                    });
                    
                    // Clean up likes/super_likes
                    await supabase.from('likes').delete().or('and(liker_id.eq.$userId,liked_id.eq.$likerId),and(liker_id.eq.$likerId,liked_id.eq.$userId)');
                    await supabase.from('super_likes').delete().or('and(liker_id.eq.$userId,liked_id.eq.$likerId),and(liker_id.eq.$likerId,liked_id.eq.$userId)');
                    
                    print('✅ Match created successfully');
                  }
                  
                  // Show match dialog instead of snackbar
                  _showReciprocalInterestDialog(likerProfile);
                  
                  // Refresh interest cache
                  _interestFutures.clear();
                  
                } else {
                  // Not reciprocal - just show notification
                  // Play notification sound (if enabled)
                  if (_soundEnabled) {
                    try {
                      await _notificationPlayer.setUrl('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3');
                      await _notificationPlayer.play();
                    } catch (e) {
                      print('⚠️ Could not play notification sound: $e');
                    }
                  }
                  
                  // Update notification count
                  setState(() {
                    _notificationCount++;
                  });
                  
                  // Show a snackbar notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('💖 ${likerProfile.name} gostou de você!'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.pinkAccent,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Ver',
                        textColor: Colors.white,
                        onPressed: () {
                          setState(() => _selectedIndex = 1); // Go to interests tab
                        },
                      ),
                    ),
                  );
                  
                  // Refresh interest cache
                  _interestFutures.clear();
                }
              }
            } catch (e) {
              print('❌ ERROR handling real-time like: $e');
            }
          },
        )
        .subscribe();

    print('✅ Real-time likes subscription active');
  }

  /// Subscribe to real-time super likes
  void _subscribeToSuperLikes() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    print('⭐ Subscribing to real-time super likes for user: $userId');

    _superLikesChannel = supabase
        .channel('super_likes_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'super_likes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'liked_id',
            value: userId,
          ),
          callback: (payload) async {
            print('⭐ REAL-TIME: Someone super liked you!');
            print('   Payload: ${payload.newRecord}');
            
            final likeData = payload.newRecord;
            final likerId = likeData['liker_id'];
            
            try {
              final profileData = await supabase
                  .from('profiles')
                  .select()
                  .eq('id', likerId)
                  .maybeSingle();
              
              if (profileData != null && mounted) {
                final likerProfile = _mapProfile(profileData);
                
                // Play a more prominent notification sound for super likes (if enabled)
                if (_soundEnabled) {
                  try {
                    await _notificationPlayer.setUrl('https://assets.mixkit.co/active_storage/sfx/2867/2867-preview.mp3');
                    await _notificationPlayer.play();
                  } catch (e) {
                    print('⚠️ Could not play notification sound: $e');
                  }
                }
                
                // Update notification count
                setState(() {
                  _notificationCount++;
                });
                
                // Show a more prominent snackbar for super likes
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('⭐ ${likerProfile.name} deu SUPER LIKE em você!'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.deepPurple,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Ver',
                      textColor: Colors.white,
                      onPressed: () {
                        setState(() => _selectedIndex = 1); // Go to interests tab
                      },
                    ),
                  ),
                );
                
                // Refresh interest cache
                _interestFutures.clear();
              }
            } catch (e) {
              print('❌ ERROR handling real-time super like: $e');
            }
          },
        )
        .subscribe();

    print('✅ Real-time super likes subscription active');
  }

  /// Subscribe to real-time messages to update unread counter
  void _subscribeToMessages() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    print('💬 Subscribing to real-time messages for user: $userId');

    _messagesChannel = supabase
        .channel('messages_realtime_home')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            print('💬 REAL-TIME: New message received!');
            final messageData = payload.newRecord;
            final senderId = messageData['sender_id'];
            
            // Only increment counter if message is from someone else
            if (senderId != userId && mounted) {
              // Haptic feedback for new message
              if (_hapticEnabled) PlatformUtils.hapticLight();
              
              setState(() {
                _messagesNotificationCount++;
              });
              
              // Play notification sound (if enabled)
              if (_soundEnabled) {
                try {
                  await _notificationPlayer.setUrl('https://assets.mixkit.co/active_storage/sfx/2354/2354-preview.mp3');
                  await _notificationPlayer.play();
                } catch (e) {
                  print('⚠️ Could not play message notification sound: $e');
                }
              }
            }
          },
        )
        .subscribe();

    print('✅ Real-time messages subscription active');
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Count received likes that haven't been seen yet
      final likesCount = await supabase
          .from('likes')
          .count(CountOption.exact)
          .eq('liked_id', userId)
          .eq('seen', false);
      
      // Count received super likes that haven't been seen yet
      final superLikesCount = await supabase
          .from('super_likes')
          .count(CountOption.exact)
          .eq('liked_id', userId)
          .eq('seen', false);

      // Count unread messages
      final unreadMessagesCount = await supabase
          .from('messages')
          .count(CountOption.exact)
          .eq('read', false)
          .neq('sender_id', userId); // Matches logic: incoming messages not read

      final total = likesCount + superLikesCount;

      if (mounted) {
        setState(() {
          _notificationCount = total;
          _messagesNotificationCount = unreadMessagesCount;
        });
      }
    } catch (e) {
      print('Erro ao buscar notificações: $e');
    }
  }

  Future<void> _fetchProfiles({bool loadMore = false}) async {
    if (loadMore && !_hasMoreProfiles) return;
    if (loadMore && _isLoadingMore) return;
    
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _profileOffset = 0;
        _hasMoreProfiles = true;
      });
    }
    
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      final userId = currentUser?.id ?? '';

      // 1. Get My Profile (gender, location, preferences)
      final myProfileData = await supabase
          .from('profiles')
          .select('gender, latitude, longitude, search_radius, age_min, age_max, religion_filters')
          .eq('id', userId)
          .maybeSingle();
      
      if (myProfileData == null) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }
      
      String? myGender = myProfileData['gender'];
      double? myLat = myProfileData['latitude'];
      double? myLng = myProfileData['longitude'];
      
      // Load search preferences (with defaults)
      int searchRadius = myProfileData['search_radius'] ?? 500;
      int ageMin = myProfileData['age_min'] ?? 18;
      int ageMax = myProfileData['age_max'] ?? 75;
      List<String> religionFilters = myProfileData['religion_filters'] != null 
          ? List<String>.from(myProfileData['religion_filters'])
          : ['Católica', 'Evangélica', 'Ortodoxa', 'Outras denominações cristãs'];
      
      String targetGender = '';
      if (myGender == 'Masculino') {
        targetGender = 'Feminino';
      } else if (myGender == 'Feminino') {
        targetGender = 'Masculino';
      }
      
      // 2. Fetch IDs of profiles I already interacted with (Like, Pass, Super)
      final List<String> swipedIds = [userId]; // Exclude myself too
      
      final likesRes = await supabase.from('likes').select('liked_id').eq('liker_id', userId);
      final passesRes = await supabase.from('passes').select('passed_id').eq('user_id', userId);
      final superRes = await supabase.from('super_likes').select('liked_id').eq('liker_id', userId);
      
      if (likesRes != null) swipedIds.addAll((likesRes as List).map((l) => l['liked_id'] as String));
      if (passesRes != null) swipedIds.addAll((passesRes as List).map((p) => p['passed_id'] as String));
      if (superRes != null) swipedIds.addAll((superRes as List).map((s) => s['liked_id'] as String));
      
      // 3. Fetch profiles (excluding swiped)
      var query = supabase
          .from('profiles')
          .select()
          .not('id', 'in', swipedIds); // Direct exclusion in DB
      
      if (targetGender.isNotEmpty) {
        query = query.eq('gender', targetGender);
      }
          
      final response = await query
          .range(_profileOffset, _profileOffset + 19)
          .limit(20);

      if (response != null) {
        final List<dynamic> data = response;
        
        // 4. Apply filters (Age, Religion, Distance)
        List<Profile> fetchedProfiles = data.map((json) => Profile(
          id: json['id'],
          name: json['name'] ?? 'Usuário',
          age: json['age'] ?? 0,
          gender: json['gender'],
          imageUrls: List<String>.from(json['image_urls'] ?? []),
          bio: json['bio'] ?? '',
          church: json['church'] ?? '',
          ministry: json['ministry'],
          faith: json['faith'],
          city: json['city'] ?? '',
          interests: List<String>.from(json['interests'] ?? []),
          isOnline: false,
          latitude: json['latitude'],
          longitude: json['longitude'],
          isVerified: json['is_verified'] ?? false,
        )).toList();
        
        // Filter by age
        fetchedProfiles = fetchedProfiles.where((profile) {
          return profile.age >= ageMin && profile.age <= ageMax;
        }).toList();
        
        // Filter by religion
        fetchedProfiles = fetchedProfiles.where((profile) {
          if (profile.faith == null || profile.faith!.isEmpty) return true;
          return religionFilters.contains(profile.faith);
        }).toList();
        
        // Filter by distance (if user has location)
        if (myLat != null && myLng != null) {
          fetchedProfiles = fetchedProfiles.where((profile) {
            if (profile.latitude == null || profile.longitude == null) return true;
            double distance = Geolocator.distanceBetween(myLat, myLng, profile.latitude!, profile.longitude!) / 1000;
            return distance <= searchRadius;
          }).toList();
        }

        print('======= FETCH PROFILES DEBUG =======');
        print('Total fetched from DB: ${data.length}');
        print('Excluding ${swipedIds.length} IDs (self + swiped)');
        print('Final count after Local filters: ${fetchedProfiles.length}');
        print('=====================================');

        setState(() {
          if (loadMore) {
            profiles.insertAll(0, fetchedProfiles);
            _isLoadingMore = false;
          } else {
            profiles = fetchedProfiles;
            _isLoading = false;
          }
          
          _profileOffset += response.length;
          _hasMoreProfiles = response.length == 20;
        });
      }
    } catch (e) {
      print('Erro ao buscar perfis: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _matchesChannel?.unsubscribe();
    _likesChannel?.unsubscribe();
    _superLikesChannel?.unsubscribe();
    _messagesChannel?.unsubscribe();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // If leaving Settings tab (index 4) and going to feed (index 0), refresh profiles
    if (_selectedIndex == 4 && index == 0) {
      _fetchProfiles(); // Refresh to apply new filter settings
    }

    // Se clicar na aba de Interesse (index 1), marca likes como vistos no banco
    if (index == 1) {
      _interestFutures.clear(); // Force refresh of all interest tabs
      _markInterestsAsSeen();
      setState(() {
        _notificationCount = 0;
      });
    }
    
    // Se clicar na aba de Chat (index 2), atualiza a lista de conversas
    if (index == 2) {
      _refreshInterestTab('mutuos'); // Atualiza a lista de conversas
      // NÃO marcar como lidas aqui - apenas ao abrir a conversa individual
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }
  
  /// Marca todos os likes e super_likes recebidos como vistos no banco de dados
  Future<void> _markInterestsAsSeen() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Marcar likes como vistos
      await supabase
          .from('likes')
          .update({'seen': true})
          .eq('liked_id', userId)
          .eq('seen', false);
      
      // Marcar super_likes como vistos
      await supabase
          .from('super_likes')
          .update({'seen': true})
          .eq('liked_id', userId)
          .eq('seen', false);
      
      print('✅ Likes/Super Likes marcados como vistos');
    } catch (e) {
      print('❌ Erro ao marcar interesses como vistos: $e');
    }
  }

  /// Marca todas as mensagens recebidas como lidas no banco de dados
  Future<void> _markMessagesAsRead() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Marcar mensagens recebidas (não enviadas por mim) como lidas
      await supabase
          .from('messages')
          .update({'read': true})
          .neq('sender_id', userId)
          .eq('read', false);
      
      print('✅ Mensagens marcadas como lidas');
    } catch (e) {
      print('❌ Erro ao marcar mensagens como lidas: $e');
    }
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
      // Haptic feedback for swipe actions
      if (_hapticEnabled) {
        if (status == SwipeStatus.like) {
          PlatformUtils.hapticLight();
        } else if (status == SwipeStatus.dislike) {
          PlatformUtils.hapticLight();
        } else if (status == SwipeStatus.superLike) {
          PlatformUtils.hapticMedium();
        }
      }

      if (profiles.isNotEmpty) {
        final currentProfile = profiles.last;
        if (status == SwipeStatus.like) {
          _processLike(currentProfile);
        } else if (status == SwipeStatus.dislike) {
          _onDislikeFromProfile(currentProfile);
        } else if (status == SwipeStatus.superLike) {
          _onSuperLikeFromProfile(currentProfile);
        }
      }
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
    final size = MediaQuery.of(context).size;
    Offset endOffset;
    
    // Play swipe sound
    _playSwipeSound();
    
    if (status == SwipeStatus.like) {
      endOffset = Offset(size.width * 1.5, _position.dy);
    } else if (status == SwipeStatus.dislike) {
      endOffset = Offset(-size.width * 1.5, _position.dy);
    } else {
      // Super Like (Up)
      endOffset = Offset(_position.dx, -size.height * 1.5);
    }
    
    final animation = Tween<Offset>(
      begin: _position,
      end: endOffset,
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
        
        // Infinite Scroll: Carrega mais se tiver pouco card
        if (profiles.length <= 5 && _hasMoreProfiles && !_isLoadingMore) {
          print('Infinite Scroll Triggered! Remaining: ${profiles.length}');
          _fetchProfiles(loadMore: true);
        }
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

  // Helper method to process a like (can be called from Home or Interest Screen)
  Future<void> _processLike(Profile targetProfile) async {
    print('🔵 PROCESSING LIKE for: ${targetProfile.name} (${targetProfile.id})');
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) return;

      // 1. Check if the other person already liked me (Reciprocal Like)
      // Check in BOTH likes and super_likes tables
      final reciprocalLike = await supabase
          .from('likes')
          .select()
          .eq('liker_id', targetProfile.id)
          .eq('liked_id', userId)
          .limit(1)
          .maybeSingle();
      
      final reciprocalSuper = await supabase
          .from('super_likes')
          .select()
          .eq('liker_id', targetProfile.id)
          .eq('liked_id', userId)
          .limit(1)
          .maybeSingle();

      print('DEBUG: Reciprocal Like from ${targetProfile.name}? ${reciprocalLike != null}');
      print('DEBUG: Reciprocal Super from ${targetProfile.name}? ${reciprocalSuper != null}');

      // 2. Save my like (using upsert to avoid unique constraint errors)
      await supabase.from('likes').upsert({
        'liker_id': userId,
        'liked_id': targetProfile.id,
      });
      print('✅ Like saved successfully');

      // 3. If they liked me, IT\'S A MATCH!
      if (reciprocalLike != null || reciprocalSuper != null) {
        print('💖 IT\'S A MATCH!');
        
        // Check if match already exists to avoid unique violation error
        final existingMatch = await supabase
            .from('matches')
            .select()
            .or('and(user1_id.eq.$userId,user2_id.eq.${targetProfile.id}),and(user1_id.eq.${targetProfile.id},user2_id.eq.$userId)')
            .limit(1)
            .maybeSingle();
            
        if (existingMatch == null) {
          // Save match to database
          await supabase.from('matches').insert({
            'user1_id': userId,
            'user2_id': targetProfile.id,
            'created_at': DateTime.now().toIso8601String(),
            'user1_seen': true, // I am seeing it right now
            'user2_seen': false, // The other person hasn't seen it yet
          });

          // Clean up likes/super_likes (match is now the source of truth)
          await supabase.from('likes').delete().or('and(liker_id.eq.$userId,liked_id.eq.${targetProfile.id}),and(liker_id.eq.${targetProfile.id},liked_id.eq.$userId)');
          await supabase.from('super_likes').delete().or('and(liker_id.eq.$userId,liked_id.eq.${targetProfile.id}),and(liker_id.eq.${targetProfile.id},liked_id.eq.$userId)');
        }

        if (mounted) {
           _showReciprocalInterestDialog(targetProfile);
        }
        
        // Clear all interests cache so they refresh next time the user views them
        _interestFutures.clear();
      }
    } catch (e) {
      print('❌ ERROR in _processLike: $e');
    }
  }

  void _onLike() async {
    if (profiles.isEmpty) return;
    final currentProfile = profiles.last; // Swiping the TOP card
    
    // Haptic feedback for like action
    if (_hapticEnabled) PlatformUtils.hapticLight();
    
    setState(() {
      _position = const Offset(150, 0);
    });
    
    await _processLike(currentProfile);
    _animateAndRemove(SwipeStatus.like);
  }

  void _onDislike() async {
    if (profiles.isEmpty) return;
    final currentProfile = profiles.last;
    
    // Haptic feedback for dislike action (now same as like)
    if (_hapticEnabled) PlatformUtils.hapticLight();
    
    setState(() {
      _position = const Offset(-150, 0);
    });
    
    await _onDislikeFromProfile(currentProfile);
    _animateAndRemove(SwipeStatus.dislike);
  }

  Future<void> _onDislikeFromProfile(Profile profile) async {
    print('🔴 DISLIKE saved for: ${profile.name}');
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId != null) {
        await supabase.from('passes').upsert({
          'user_id': userId,
          'passed_id': profile.id,
        });
      }
    } catch (e) {
      print('❌ ERROR saving pass: $e');
    }
  }

  void _onSuperLike() async {
    if (profiles.isEmpty) return;
    final currentProfile = profiles.last;
    
    // Haptic feedback for super like (stronger)
    if (_hapticEnabled) PlatformUtils.hapticMedium();
    
    setState(() {
      _position = const Offset(0, -150);
    });
    
    await _onSuperLikeFromProfile(currentProfile);
    _animateAndRemove(SwipeStatus.superLike);
  }

  Future<void> _onSuperLikeFromProfile(Profile profile) async {
    print('⭐ SUPER LIKE saved for: ${profile.name}');
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId != null) {
        // 1. Check for reciprocity first
        final reciprocalLike = await supabase
            .from('likes')
            .select()
            .eq('liker_id', profile.id)
            .eq('liked_id', userId)
            .eq('liked_id', userId)
            .limit(1)
            .maybeSingle();
        
        final reciprocalSuper = await supabase
            .from('super_likes')
            .select()
            .eq('liker_id', profile.id)
            .eq('liked_id', userId)
            .limit(1)
            .maybeSingle();

        // 2. Save Super Like
        await supabase.from('super_likes').upsert({
          'liker_id': userId,
          'liked_id': profile.id,
        });

        // 3. Handle Match
        if (reciprocalLike != null || reciprocalSuper != null) {
             print('💖 IT\'S A MATCH (via Super Like)!');
             
             final existingMatch = await supabase
                .from('matches')
                .select()
                .or('and(user1_id.eq.$userId,user2_id.eq.${profile.id}),and(user1_id.eq.${profile.id},user2_id.eq.$userId)')
                .limit(1)
                .maybeSingle();

             if (existingMatch == null) {
               await supabase.from('matches').insert({
                 'user1_id': userId,
                 'user2_id': profile.id,
                 'created_at': DateTime.now().toIso8601String(),
                 'user1_seen': true,
                 'user2_seen': false,
               });

               // Clean up likes/super_likes (match is now the source of truth)
               await supabase.from('likes').delete().or('and(liker_id.eq.$userId,liked_id.eq.${profile.id}),and(liker_id.eq.${profile.id},liked_id.eq.$userId)');
               await supabase.from('super_likes').delete().or('and(liker_id.eq.$userId,liked_id.eq.${profile.id}),and(liker_id.eq.${profile.id},liked_id.eq.$userId)');
             }

             if (mounted) {
                _showReciprocalInterestDialog(profile);
             }
             _interestFutures.clear();
        }
      }
    } catch (e) {
      print('❌ ERROR saving super like: $e');
    }
  }

  Future<void> _onCancelLike(Profile profile) async {
    print('🟠 CANCEL LIKE for: ${profile.name}');
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId != null) {
        // 1. Delete the like I sent (from BOTH tables)
        await supabase.from('likes')
            .delete()
            .eq('liker_id', userId)
            .eq('liked_id', profile.id);
        
        await supabase.from('super_likes')
            .delete()
            .eq('liker_id', userId)
            .eq('liked_id', profile.id);
        
        // 2. Add to passes (rejected)
        await supabase.from('passes').upsert({
          'user_id': userId,
          'passed_id': profile.id,
        });
        
        // Refresh interests cache
        _interestFutures.clear();
      }
    } catch (e) {
      print('❌ ERROR canceling like: $e');
    }
  }

  Future<void> _unmatch(Profile profile) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desfazer Match'),
        content: Text('Deseja realmente desfazer o match com ${profile.name}? Vocês não poderão mais se comunicar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desfazer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    print('💔 UNMATCH for: ${profile.name}');
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        // 1. Delete all messages from the match
        final matchData = await supabase.from('matches')
            .select('id')
            .or('and(user1_id.eq.$userId,user2_id.eq.${profile.id}),and(user1_id.eq.${profile.id},user2_id.eq.$userId)')
            .maybeSingle();
        
        if (matchData != null) {
          await supabase.from('messages').delete().eq('match_id', matchData['id']);
        }
        
        // 2. Delete the match
        await supabase.from('matches').delete()
            .or('and(user1_id.eq.$userId,user2_id.eq.${profile.id}),and(user1_id.eq.${profile.id},user2_id.eq.$userId)');

        // 3. Delete likes from both users (removes from "Enviados" and "Recebidos")
        await supabase.from('likes').delete()
            .or('and(liker_id.eq.$userId,liked_id.eq.${profile.id}),and(liker_id.eq.${profile.id},liked_id.eq.$userId)');
        
        // 4. Delete super_likes from both users
        await supabase.from('super_likes').delete()
            .or('and(liker_id.eq.$userId,liked_id.eq.${profile.id}),and(liker_id.eq.${profile.id},liked_id.eq.$userId)');

        // 5. Add both users to each other's passes (so they don't see each other again)
        await supabase.from('passes').upsert({'user_id': userId, 'passed_id': profile.id});
        await supabase.from('passes').upsert({'user_id': profile.id, 'passed_id': userId});

        // 6. Clear cache
        _interestFutures.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Match com ${profile.name} desfeito.')),
          );
          setState(() {}); // Force rebuild
        }
      }
    } catch (e) {
      print('❌ ERROR unmatching: $e');
    }
  }

  // Play subtle swipe sound
  Future<void> _playSwipeSound() async {
    if (!_soundEnabled) return;
    
    try {
      // Play a very subtle swoosh sound
      // Using lower volume for swipe (0.3 = 30% volume)
      await _notificationPlayer.setVolume(0.3);
      await _notificationPlayer.setAsset('assets/sounds/swipe.wav');
      await _notificationPlayer.play();
      // Reset volume for other sounds
      await _notificationPlayer.setVolume(1.0);
    } catch (e) {
      // Fail silently - sound is not critical
    }
  }

  // Play match notification sound
  Future<void> _playMatchSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _notificationPlayer.setAsset('assets/sounds/notification.wav');
      await _notificationPlayer.play();
    } catch (e) {
      // Fail silently
    }
  }

  void _showReciprocalInterestDialog(Profile targetProfile) async {
    // Haptic feedback for match (medium impact)
    if (_hapticEnabled) PlatformUtils.hapticMedium();
    
    // Play match sound
    _playMatchSound();
    
    // Save context before async operation
    final dialogContext = context;
    
    // Fetch current user profile for the animation
    final myProfile = await _getMyProfile();
    
    if (!mounted || myProfile == null) return;
    
    // Use saved context to avoid issues with async
    if (!dialogContext.mounted) return;
    
    showGeneralDialog(
      context: dialogContext,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black.withOpacity(0.8), // Dark background focus
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: MatchAnimationOverlay(
              targetProfile: targetProfile,
              myProfile: myProfile,
              onViewProfile: () {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.push(
                  dialogContext,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailScreen(profile: targetProfile),
                  ),
                );
              },
              onContinue: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Envolvemos o Scaffold em um Container com gradiente para garantir fundo contínuo
    // sem usar extendBody, que estava causando problemas de layout.
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
      child: Scaffold(
        backgroundColor: Colors.transparent, // Fundo transparente para ver o gradiente
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
          // Removemos a cor e sombra do container para ser totalmente transparente
          color: Colors.transparent,
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, 
            selectedItemColor: Colors.white, // Ícones ativos brancos
            unselectedItemColor: Colors.white, // Ícones inativos também brancos
            showUnselectedLabels: false,
            showSelectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
            unselectedLabelStyle: const TextStyle(color: Colors.white),
            elevation: 0,
            iconSize: 32, // Ícones maiores
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.style, 0),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildNavIcon(Icons.favorite, 1),
                    if (_notificationCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _notificationCount > 99 ? '99+' : '$_notificationCount',
                            style: const TextStyle(
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
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildNavIcon(Icons.chat_bubble, 2),
                    if (_messagesNotificationCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _messagesNotificationCount > 99 ? '99+' : '$_messagesNotificationCount',
                            style: const TextStyle(
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
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person, 3),
                label: 'Perfil',
              ),
              // Nova aba Configurações
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.tune_rounded, 4),
                label: 'Config',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData iconData, int index) {
    bool isSelected = _selectedIndex == index;
    return Container(
      decoration: BoxDecoration(
        // Glow sutil para destacar
        shape: BoxShape.circle,
        boxShadow: isSelected ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: Icon(
        iconData,
        // Se não selecionado usa o contorno, se selecionado usa preenchido (se disponível, mas aqui usaremos o mesmo ícone com transparência controlada pelo BottomNav)
        // Para simplificar e garantir destaque, usamos o mesmo ícone
        shadows: const [
          Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2))
        ],
      ),
    );
  }

  Widget _buildSwipeTab() {
    return Container(
      // Removemos o gradiente daqui pois agora ele está no Scaffold global
      color: Colors.transparent,
      // Adicionamos padding inferior para que o card não invada a área da barra de navegação
      padding: const EdgeInsets.only(bottom: 3), // Padding reduzido para 3
      child: Stack(
        children: [
          _isLoading 
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)))
              : profiles.isEmpty
                  ? _buildEmptyState()
                  : _buildCardStack(),
        ],
      ),
    );
  }
  
  // ... (Matches, Messages, Profile Tabs mantidos iguais - omitidos para brevidade)

  Widget _buildMatchesTab() {
    return DefaultTabController(
      length: 4,
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
              Tab(text: 'Recíproco'),    // Match (Os dois)
              Tab(text: 'Super'),     // Super Like
              Tab(text: 'Enviados'),  // Curtidas enviadas (NOVO)
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInterestGrid(status: 'recebidos'),
            _buildInterestGrid(status: 'mutuos'),
            _buildInterestGrid(status: 'super'),
            _buildInterestGrid(status: 'enviados'),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestGrid({required String status}) {
    // Check if we already have a future for this tab, if not create one
    _interestFutures[status] ??= _fetchInterestProfiles(status);

    return FutureBuilder<List<Profile>>(
      future: _interestFutures[status],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text('Erro ao carregar: ${snapshot.error}'),
                TextButton(
                  onPressed: () => _refreshInterestTab(status),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        
        final interestProfiles = snapshot.data ?? [];
        
        if (interestProfiles.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _refreshInterestTab(status),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          status == 'recebidos' ? Icons.favorite_border :
                          status == 'mutuos' ? Icons.favorite :
                          Icons.star_border,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          status == 'recebidos' ? 'Nenhuma curtida recebida ainda' :
                          status == 'mutuos' ? 'Nenhum match ainda' :
                          'Nenhum super like recebido',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Continue deslizando para encontrar alguém especial!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
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
        
        return RefreshIndicator(
          onRefresh: () => _refreshInterestTab(status),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: interestProfiles.length,
            itemBuilder: (context, index) {
              final profile = interestProfiles[index];
              return GestureDetector(
                onTap: () async {
                  final action = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileDetailScreen(profile: profile),
                    ),
                  );
                  
                  if (action == 'like') {
                    await _processLike(profile);
                    _refreshInterestTab(status);
                  } else if (action == 'dislike') {
                    if (status == 'enviados') {
                      await _onCancelLike(profile);
                    } else {
                      await _onDislikeFromProfile(profile);
                    }
                    _refreshInterestTab(status);
                  } else if (action == 'super') {
                    await _onSuperLikeFromProfile(profile);
                    _refreshInterestTab(status);
                  }
                },
                child: _buildInterestCard(profile, status, matchId: profile.matchId),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _refreshInterestTab(String status) async {
    setState(() {
      _interestFutures[status] = _fetchInterestProfiles(status);
    });
    await _interestFutures[status];
  }
  
  Future<void> _deleteMatch(String matchId, String status) async {
    // 1. Mostrar Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final supabase = Supabase.instance.client;
      
      // Chamada RPC segura que executa como admin no banco
      await supabase.rpc('delete_match_completely', params: {'match_id_input': matchId});
      
      print('✅ Match $matchId removido via RPC.');
      
      // 2. Fechar Loading
      if (mounted) Navigator.pop(context);

      // 3. Atualizar UI
      await _refreshInterestTab(status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match desfeito com sucesso.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Fecha loading em caso de erro
      print('Erro ao excluir match (RPC): $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Widget _buildInterestCard(Profile profile, String status, {String? matchId}) {
    // Status-based colors and icons
    final Map<String, Map<String, dynamic>> statusConfig = {
      'recebidos': {'color': const Color(0xFFFF6B6B), 'icon': Icons.favorite, 'label': 'Curtiu você'},
      'mutuos': {'color': const Color(0xFF667eea), 'icon': Icons.favorite, 'label': 'Match!'},
      'super': {'color': const Color(0xFFFFD93D), 'icon': Icons.star, 'label': 'Super Like'},
      'enviados': {'color': const Color(0xFF6BCB77), 'icon': Icons.send, 'label': 'Enviado'},
    };
    final config = statusConfig[status] ?? statusConfig['recebidos']!;
    final Color statusColor = config['color'] as Color;
    final IconData statusIconKey = config['icon'] as IconData; // Renamed to avoid final conflict if I wanted to reassign
    final String statusLabelKey = config['label'] as String;
    
    // Override for Sent Super Likes
    Color finalColor = statusColor;
    IconData finalIcon = statusIconKey;
    String finalLabel = statusLabelKey;

    if (status == 'enviados' && profile.isSuperLike) {
      finalColor = const Color(0xFFFFD93D); // Gold
      finalIcon = Icons.star;
      finalLabel = 'Super Like Enviado';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: finalColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: status == 'mutuos' ? null : () async {
              final action = await Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileDetailScreen(profile: profile)));
              if (action == 'like') { await _processLike(profile); _refreshInterestTab(status); }
              else if (action == 'dislike') { await _onDislikeFromProfile(profile); _refreshInterestTab(status); }
              else if (action == 'super') { await _onSuperLikeFromProfile(profile); _refreshInterestTab(status); }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: profile.imageUrls.isNotEmpty ? profile.imageUrls.first : 'https://via.placeholder.com/300',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                  errorWidget: (ctx, url, error) => Container(color: Colors.grey[300], child: Icon(Icons.person, size: 60, color: Colors.grey[400])),
                ),
                // Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.4, 1.0],
                      colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.black.withOpacity(0.85)]),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: finalColor, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: finalColor.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(finalIcon, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(finalLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                // Profile Info
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${profile.name}, ${profile.age}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)]), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 12),
                        const SizedBox(width: 3),
                        Expanded(child: Text(profile.city, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
                      ]),
                      // Match Actions
                      if (status == 'mutuos' && matchId != null) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => ChatScreen(matchId: matchId, targetProfile: profile))),
                            icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                            label: const Text('Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667eea), foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4),
                          )),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Excluir Match'), content: Text('Deseja remover ${profile.name} dos seus matches?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                TextButton(onPressed: () { Navigator.pop(ctx); _deleteMatch(matchId, status); }, child: const Text('Excluir', style: TextStyle(color: Colors.red))),
                              ],
                            )),
                            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.9), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 18)),
                          ),
                        ]),
                      ],
                      // Cancel Sent Like
                      if (status == 'enviados') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(children: [Icon(Icons.undo, color: Colors.orange[700]), const SizedBox(width: 8), const Text('Cancelar Curtida')]),
                              content: Text('Deseja cancelar a curtida enviada para ${profile.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar')),
                                ElevatedButton(
                                  onPressed: () async { Navigator.pop(ctx); await _cancelSentLike(profile); _refreshInterestTab(status);
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Curtida para ${profile.name} cancelada'), backgroundColor: Colors.orange));
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                  child: const Text('Cancelar Curtida'),
                                ),
                              ],
                            )),
                            icon: const Icon(Icons.undo, size: 14),
                            label: const Text('Cancelar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.withOpacity(0.9), foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cancel a sent like
  Future<void> _cancelSentLike(Profile profile) async {
    print('🔄 Canceling sent like for: ${profile.name}');
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('likes').delete().eq('liker_id', userId).eq('liked_id', profile.id);
        await supabase.from('super_likes').delete().eq('liker_id', userId).eq('liked_id', profile.id);
        print('✅ Sent like canceled successfully');
        _interestFutures.clear();
      }
    } catch (e) { print('❌ ERROR canceling sent like: $e'); }
  }
  
  Future<List<Profile>> _fetchInterestProfiles(String status) async {
    print('🔍 Fetching interest profiles for status: $status');
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) return [];
      
      List<Profile> profiles = [];

      // 1. Always fetch matches and passes first to filter them out from other tabs
      final matchesData = await supabase
          .from('matches')
          .select('user1_id, user2_id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId');
      
      final List<String> matchedUserIds = [];
      for (var m in matchesData) {
        matchedUserIds.add(m['user1_id'] == userId ? m['user2_id'] : m['user1_id']);
      }

      final passesData = await supabase
          .from('passes')
          .select('passed_id')
          .eq('user_id', userId);
      
      final List<String> passedUserIds = (passesData as List)
          .map((p) => p['passed_id'] as String)
          .toList();
      
      if (status == 'recebidos') {
        final data = await supabase
            .from('likes')
            .select('liker_id, sender:profiles!likes_liker_id_fkey(*)')
            .eq('liked_id', userId);
        
        for (var item in data) {
          final profileData = item['sender'];
          if (profileData != null) {
            final profile = _mapProfile(profileData);
            // Filter out if already matched OR already passed
            if (!matchedUserIds.contains(profile.id) && !passedUserIds.contains(profile.id)) {
              profiles.add(profile);
            }
          }
        }
            
      } else if (status == 'mutuos') {
        final data = await supabase
            .from('matches')
            .select('id, user1_id, user2_id, p1:profiles!matches_user1_id_fkey(*), p2:profiles!matches_user2_id_fkey(*), messages:messages(content, created_at, sender_id, read)')
            .or('user1_id.eq.$userId,user2_id.eq.$userId')
            .order('created_at', referencedTable: 'messages', ascending: false);
        
        for (var item in data) {
          final profileData = item['user1_id'] == userId ? item['p2'] : item['p1'];
          if (profileData != null) {
            final msgs = (item['messages'] as List?) ?? [];
            int unread = 0;
            String? lastMsg;
            DateTime? lastTime;
            
            if (msgs.isNotEmpty) {
              // Messages are ordered by created_at desc (newest first)
              // Calculate unread: count messages where sender_id != me AND read is false
              for (var m in msgs) {
                 if (m['sender_id'] != userId && (m['read'] == false || m['read'] == null)) {
                   unread++;
                 }
              }
              lastMsg = msgs.first['content'] as String?;
              lastTime = DateTime.tryParse(msgs.first['created_at'].toString());
            }

            final profile = _mapProfile(
              profileData, 
              matchId: item['id']?.toString(),
              unreadCount: unread,
              lastMessage: lastMsg,
              lastMessageTime: lastTime,
            );
            profiles.add(profile);
          }
        }
        
        // Sort profiles by last message time (newest on top)
        profiles.sort((a, b) {
           final timeA = a.lastMessageTime ?? DateTime(2000);
           final timeB = b.lastMessageTime ?? DateTime(2000);
           return timeB.compareTo(timeA);
        });

      } else if (status == 'super') {
        final data = await supabase
            .from('super_likes')
            .select('liker_id, sender:profiles!super_likes_liker_id_fkey(*)')
            .eq('liked_id', userId);
        
        for (var item in data) {
          final profileData = item['sender'];
          if (profileData != null) {
            final profile = _mapProfile(profileData);
            // Filter out if matched OR passed
            if (!matchedUserIds.contains(profile.id) && !passedUserIds.contains(profile.id)) {
              profiles.add(profile);
            }
          }
        }
      } else if (status == 'enviados') {
        // Likes that I sent
        final likesData = await supabase
            .from('likes')
            .select('liked_id, receiver:profiles!likes_liked_id_fkey(*)')
            .eq('liker_id', userId);
        
        final superLikesData = await supabase
            .from('super_likes')
            .select('liked_id, receiver:profiles!super_likes_liked_id_fkey(*)')
            .eq('liker_id', userId);

        // Process standard likes
        for (var item in likesData) {
          final profileData = item['receiver'];
          if (profileData != null) {
            final profile = _mapProfile(profileData, isSuperLike: false);
            if (!matchedUserIds.contains(profile.id)) {
              profiles.add(profile);
            }
          }
        }
        
        // Process super likes
        for (var item in superLikesData) {
          final profileData = item['receiver'];
          if (profileData != null) {
            final profile = _mapProfile(profileData, isSuperLike: true);
            // Avoid duplicates if user somehow managed to like and superlike (shouldn't happen but key)
             if (!profiles.any((p) => p.id == profile.id) && !matchedUserIds.contains(profile.id)) {
              profiles.add(profile);
            }
          }
        }
      }
      
      print('✅ Loaded ${profiles.length} profiles for $status (Filtered ${matchedUserIds.length} matches, ${passedUserIds.length} passes)');
      return profiles;
    } catch (e) {
      print('❌ Error in _fetchInterestProfiles ($status): $e');
      return [];
    }
  }

  Profile _mapProfile(Map<String, dynamic> data, {String? matchId, int unreadCount = 0, String? lastMessage, DateTime? lastMessageTime, bool isSuperLike = false}) {
    return Profile(
      id: data['id'],
      name: data['name'] ?? 'Usuário',
      age: data['age'] ?? 0,
      gender: data['gender'],
      imageUrls: List<String>.from(data['image_urls'] ?? []),
      bio: data['bio'] ?? '',
      church: data['church'] ?? '',
      ministry: data['ministry'],
      faith: data['faith'],
      city: data['city'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      matchId: matchId,
      unreadCount: unreadCount,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      isSuperLike: isSuperLike,
      isVerified: data['is_verified'] ?? false,
    );
  }

  // --- Aba de Chat (Mensagens) - Premium Design ---
  Widget _buildMessagesTab() {
    return FutureBuilder<List<Profile>>(
      future: _interestFutures['mutuos'] ?? _fetchInterestProfiles('mutuos'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          );
        }

        final profiles = snapshot.data ?? [];

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFF6B8DD6),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Premium Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conversas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profiles.isEmpty
                                ? 'Encontre seu par perfeito'
                                : '${profiles.length} ${profiles.length == 1 ? 'conexão' : 'conexões'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      // Search Button with glassmorphism
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages Container
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: profiles.isEmpty
                        ? _buildEmptyMessagesState()
                        : _buildMessagesList(profiles),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Heart Icon Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.1),
                    const Color(0xFF764ba2).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Nenhuma conversa ainda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Quando você tiver um match, suas\nconversas aparecerão aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // CTA Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onItemTapped(0), // Go to swipe tab
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.style_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Começar a Explorar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildMessagesList(List<Profile> profiles) {
    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF667eea),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Minhas Conversas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${profiles.length}',
                  style: const TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Messages List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refreshInterestTab('mutuos'),
            color: const Color(0xFF667eea),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return _buildPremiumMessageCard(profile, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumMessageCard(Profile profile, int index) {
    final bool hasUnread = profile.unreadCount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasUnread ? const Color(0xFFF8F4FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasUnread 
              ? const Color(0xFF667eea).withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasUnread 
                ? const Color(0xFF667eea).withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (profile.matchId != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    matchId: profile.matchId!,
                    targetProfile: profile,
                  ),
                ),
              );
              _refreshInterestTab('mutuos');
              _fetchNotificationCount(); // Atualiza o contador de mensagens não lidas
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Avatar with Online Indicator
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: hasUnread
                            ? const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              )
                            : null,
                        color: hasUnread ? null : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: CachedNetworkImageProvider(
                            profile.imageUrls.isNotEmpty
                                ? profile.imageUrls.first
                                : 'https://via.placeholder.com/150',
                          ),
                        ),
                      ),
                    ),
                    // Online indicator
                    if (profile.isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    // Unread Badge
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x40FF6B6B),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          child: Center(
                            child: Text(
                              profile.unreadCount > 9 ? '9+' : '${profile.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Message Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            profile.name,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 17,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          if (profile.lastMessageTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: hasUnread
                                    ? const Color(0xFF667eea).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${profile.lastMessageTime!.hour}:${profile.lastMessageTime!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: hasUnread
                                      ? const Color(0xFF667eea)
                                      : Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.lastMessage ?? 'Toque para iniciar conversa ✨',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread ? const Color(0xFF4A5568) : Colors.grey[600],
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Actions Menu
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'clear') {
                                if (profile.matchId != null) {
                                  await _clearChat(profile.matchId!);
                                }
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.person_remove, color: Colors.red, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('Desfazer Match'),
                                      ],
                                    ),
                                    content: Text(
                                      'Tem certeza que deseja desfazer o match com ${profile.name}?',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(
                                          'Cancelar',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          if (profile.matchId != null) {
                                            _deleteMatch(profile.matchId!, 'mutuos');
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Desfazer',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'clear',
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.cleaning_services_rounded, size: 18, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Limpar Conversa'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.person_remove_rounded, size: 18, color: Colors.red),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Desfazer Match', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.grey[400],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearChat(String matchId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('messages').delete().eq('match_id', matchId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversa limpa com sucesso')),
        );
      }
      _refreshInterestTab('mutuos');
    } catch (e) {
      print('Erro ao limpar conversa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar conversa: $e')),
        );
      }
    }
  }

  Future<Profile?> _getMyProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      final data = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
      
      print('DEBUG: Perfil carregado: ${data?['name']}'); // DEBUG
      print('DEBUG: Imagens no banco: ${data?['image_urls']}'); // DEBUG
      
      if (data == null) return null;
      
      // Parse Imagens
      List<String> images = [];
      if (data['image_urls'] != null) {
        images = List<String>.from(data['image_urls']);
      }
      print('DEBUG: Lista de imagens processada: $images'); // DEBUG
      
      String? vStatus = 'none';
      String? vReason;

      // Buscar status da verificação
      try {
        final verificationData = await supabase
            .from('verification_requests')
            .select('status, rejection_reason')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (verificationData != null) {
          vStatus = verificationData['status'];
          vReason = verificationData['rejection_reason'];
        }
      } catch (e) {
        print('Erro ao buscar status verificação: $e');
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
        isVerified: data['is_verified'] ?? false,
        verificationStatus: vStatus,
        verificationRejectionReason: vReason,
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
                            backgroundImage: CachedNetworkImageProvider(mainImage),
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
                    
                    const SizedBox(height: 25),

                    // Área de Verificação
                    if (myProfile.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified, color: Colors.lightBlueAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Perfil Verificado',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else if (myProfile.verificationStatus == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.access_time_filled, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Verificação em análise',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else if (myProfile.verificationStatus == 'rejected')
                      GestureDetector(
                        onTap: () async {
                           final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VerificationScreen()),
                          );
                          if (result == true) {
                            setState(() => _getMyProfile()); // Recarregar
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Verificação rejeitada. Tentar novamente?',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  if (myProfile.verificationRejectionReason != null)
                                    Text(
                                      myProfile.verificationRejectionReason!,
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VerificationScreen()),
                          );
                          if (result == true) {
                            // Se enviou com sucesso, recarrega o perfil para atualizar o status
                            setState(() {}); // Força rebuild para chamar future builder se necessário, ou melhor:
                            _getMyProfile(); // Recarrega dados
                          }
                        },
                        icon: const Icon(Icons.verified, color: Colors.white, size: 22),
                        label: const Text(
                          'Verificar Perfil',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 4,
                          shadowColor: Colors.blue.withOpacity(0.5),
                        ),
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
              
              const SizedBox(height: 20),
              
              // Botão de Excluir Conta
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton.icon(
                  onPressed: () => _showDeleteAccountDialog(),
                  icon: Icon(Icons.delete_forever_rounded, color: Colors.red[700]),
                  label: Text(
                    'Excluir Minha Conta',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
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
                    ProfileCard(
                      profile: profiles.last, 
                      isTop: true,
                      onLike: (profile) {
                        _processLike(profile);
                        _animateAndRemove(SwipeStatus.like);
                      },
                      onDislike: (profile) {
                        _onDislikeFromProfile(profile);
                        _animateAndRemove(SwipeStatus.dislike);
                      },
                      onSuperLike: (profile) {
                        _onSuperLikeFromProfile(profile);
                        _animateAndRemove(SwipeStatus.superLike);
                      },
                    ),
                    
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
              _fetchProfiles(); // Buscar novos perfis
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF764ba2),
            ),
            child: const Text('Buscar Novamente'),
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
          // Botão Refresh (Recarregar perfis)
          _buildCircleButton(
            icon: Icons.refresh,
            color: Colors.amber,
            size: 50,
            iconSize: 24,
            onPressed: () {
              _fetchProfiles(); // Buscar novos perfis
            },
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Text(
            'Par Cristão',
            style: TextStyle(
              color: Color(0xFF667eea),
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed the old Padding with 'Preferências de Busca' Text
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Location Banner (if not enabled)
                  if (!_isCheckingLocation && !_hasLocation) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Localização Desativada',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ative para ver perfis mais próximos',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _enableLocationFromSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Ativar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Search Radius Slider
                  _buildSectionHeader('Raio de Busca'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Raio de busca',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_searchRadius.round()} km',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF667eea),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Slider(
                          value: _searchRadius,
                          min: 50,
                          max: 1000,
                          divisions: 95,
                          activeColor: const Color(0xFF667eea),
                          inactiveColor: Colors.grey[300],
                          onChanged: (value) {
                            setState(() => _searchRadius = value);
                          },
                          onChangeEnd: (value) {
                            _saveSearchPreferences();
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('50 km', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text('1000 km', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Age Range Slider
                  _buildSectionHeader('Faixa Etária'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Idade',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_ageRange.start.round()} - ${_ageRange.end.round()} anos',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF667eea),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RangeSlider(
                          values: _ageRange,
                          min: 18,
                          max: 75,
                          divisions: 57,
                          activeColor: const Color(0xFF667eea),
                          inactiveColor: Colors.grey[300],
                          labels: RangeLabels(
                            _ageRange.start.round().toString(),
                            _ageRange.end.round().toString(),
                          ),
                          onChanged: (values) {
                            setState(() => _ageRange = values);
                          },
                          onChangeEnd: (values) {
                            _saveSearchPreferences();
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('18 anos', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text('75 anos', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Religion Filters
                  _buildSectionHeader('Religiões'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildReligionCheckbox('Católica'),
                        _buildReligionCheckbox('Evangélica'),
                        _buildReligionCheckbox('Ortodoxa'),
                        _buildReligionCheckbox('Outras denominações cristãs'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Recalcular Localização Button
                  _buildSectionHeader('Localização'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.my_location, color: const Color(0xFF667eea), size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Viajando? Atualize sua localização',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _enableLocationFromSettings,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Recalcular Localização'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Sound Notifications Toggle
                  _buildSectionHeader('Notificações'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _soundEnabled ? Icons.volume_up : Icons.volume_off,
                          color: const Color(0xFF667eea),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alerta Sonoro',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tocar som ao receber likes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _soundEnabled,
                          activeColor: const Color(0xFF667eea),
                          onChanged: (value) {
                            setState(() => _soundEnabled = value);
                            _saveSetting('sound_enabled', value);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Haptic Feedback Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _hapticEnabled ? Icons.vibration : Icons.phonelink_erase,
                          color: const Color(0xFF667eea),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vibração',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Feedback tátil ao interagir',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _hapticEnabled,
                          activeColor: const Color(0xFF667eea),
                          onChanged: (value) {
                            setState(() => _hapticEnabled = value);
                            _saveSetting('haptic_enabled', value);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Ver Perfis Rejeitados Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: ElevatedButton.icon(
                      onPressed: _showResetRejectedDialog,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Ver Novamente Perfis Rejeitados'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReligionCheckbox(String religion) {
    final isSelected = _religionFilters.contains(religion);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _religionFilters.remove(religion);
          } else {
            _religionFilters.add(religion);
          }
        });
        _saveSearchPreferences();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF667eea) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF667eea) : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                religion,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveSearchPreferences() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) return;
      
      await supabase.from('profiles').update({
        'search_radius': _searchRadius.round(),
        'age_min': _ageRange.start.round(),
        'age_max': _ageRange.end.round(),
        'religion_filters': _religionFilters.toList(),
      }).eq('id', userId);
      
      print('Preferências salvas: Raio=${_searchRadius}km, Idade=${_ageRange.start}-${_ageRange.end}, Religiões=$_religionFilters');
    } catch (e) {
      print('Erro ao salvar preferências: $e');
    }
  }
  
  Future<void> _checkUserLocation() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        setState(() => _isCheckingLocation = false);
        return;
      }
      
      final response = await supabase
          .from('profiles')
          .select('latitude, longitude')
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        final lat = response['latitude'];
        final lng = response['longitude'];
        setState(() {
          _hasLocation = (lat != null && lng != null);
          _isCheckingLocation = false;
        });
      } else {
        setState(() => _isCheckingLocation = false);
      }
    } catch (e) {
      print('Erro ao verificar localização: $e');
      setState(() => _isCheckingLocation = false);
    }
  }
  
  Future<void> _enableLocationFromSettings() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviços de localização desativados. Ative nas configurações do dispositivo.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de localização negada.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão negada permanentemente. Ative nas configurações do dispositivo.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Save to database
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId != null) {
        await supabase.from('profiles').update({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }).eq('id', userId);
        
        setState(() => _hasLocation = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Localização ativada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao ativar localização: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao ativar localização: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showResetRejectedDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ver perfis novamente?'),
        content: const Text('Isso fará com que todos os perfis que você rejeitou voltem a aparecer no seu feed de início.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetRejectedProfiles();
            },
            child: const Text('VER NOVAMENTE', style: TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetRejectedProfiles() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) return;
      
      // Delete all entries from 'passes' table for this user
      await supabase.from('passes').delete().eq('user_id', userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Perfis rejeitados resetados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh profiles list to show them again
      _fetchProfiles();
      
    } catch (e) {
      print('Erro ao resetar perfis rejeitados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao resetar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
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
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Excluir Conta',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir sua conta?',
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
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Esta ação é irreversível!',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Todas as suas fotos serão excluídas\n'
                    '• Seu perfil será removido permanentemente\n'
                    '• Todos os matches e conversas serão perdidos\n'
                    '• Curtidas enviadas e recebidas serão apagadas\n'
                    '• Não será possível recuperar seus dados',
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Excluir Conta',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Confirmação Final'),
          ],
        ),
        content: const Text(
          'Digite "EXCLUIR" para confirmar a exclusão permanente da sua conta:',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        Navigator.pop(context);
        return;
      }

      // 1. Delete all messages from user's matches
      final matchesData = await supabase
          .from('matches')
          .select('id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId');
      
      for (var match in matchesData) {
        await supabase.from('messages').delete().eq('match_id', match['id']);
      }

      // 2. Delete all matches
      await supabase.from('matches').delete().or('user1_id.eq.$userId,user2_id.eq.$userId');

      // 3. Delete all likes (sent and received)
      await supabase.from('likes').delete().eq('liker_id', userId);
      await supabase.from('likes').delete().eq('liked_id', userId);

      // 4. Delete all super likes (sent and received)
      await supabase.from('super_likes').delete().eq('liker_id', userId);
      await supabase.from('super_likes').delete().eq('liked_id', userId);

      // 5. Delete all passes
      await supabase.from('passes').delete().eq('user_id', userId);
      await supabase.from('passes').delete().eq('passed_id', userId);

      // 6. Delete profile photos from storage
      try {
        final photos = await supabase.storage.from('profile-photos').list(path: userId);
        if (photos.isNotEmpty) {
          final filePaths = photos.map((f) => '$userId/${f.name}').toList();
          await supabase.storage.from('profile-photos').remove(filePaths);
        }
      } catch (e) {
        print('Erro ao excluir fotos (continuando): $e');
      }

      // 7. Delete profile
      await supabase.from('profiles').delete().eq('id', userId);

      // 8. Delete auth user (via RPC function with admin privileges)
      await supabase.rpc('delete_user');

      // 9. Sign out (já é redundante após delete, mas garante limpeza local)
      await supabase.auth.signOut();

      Navigator.pop(context); // Close loading

      // Navigate to auth screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sua conta foi excluída com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      print('Erro ao excluir conta: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
  final Function(Profile)? onLike;
  final Function(Profile)? onDislike;
  final Function(Profile)? onSuperLike;

  const ProfileCard({
    super.key, 
    required this.profile, 
    required this.isTop,
    this.onLike,
    this.onDislike,
    this.onSuperLike,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _currentImageIndex = 0;

  @override
  void didUpdateWidget(ProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resetar o índice da foto quando o perfil mudar
    if (oldWidget.profile.id != widget.profile.id) {
      setState(() {
        _currentImageIndex = 0;
      });
    }
    // Também garantir que o índice não exceda o número de fotos do novo perfil
    if (_currentImageIndex >= widget.profile.imageUrls.length) {
      setState(() {
        _currentImageIndex = 0;
      });
    }
  }

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
            if (widget.profile.imageUrls.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.profile.imageUrls[_currentImageIndex],
                fit: BoxFit.cover,
                errorWidget: (context, url, error) {
                  print('Erro ao carregar imagem: $error');
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(child: Icon(Icons.broken_image, size: 100, color: Colors.grey)),
                  );
                },
                placeholder: (context, url) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },

              )
            else
              Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Sem foto', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),

            // Gradiente Escuro (Shadow elegante na parte inferior)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2), // Leve em cima para slider
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.15, 0.45, 0.65, 0.85, 1.0],
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
              bottom: 90, // Posição mais baixa para dar mais espaço à foto
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
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
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
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                shadows: [
                                  Shadow(offset: const Offset(0, 1), blurRadius: 4.0, color: Colors.black.withOpacity(0.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Nome e idade com fonte reduzida
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${widget.profile.name.contains('@') ? widget.profile.name.split('@')[0] : widget.profile.name}, ${widget.profile.age}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26, // Fonte reduzida
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(offset: Offset(0, 1), blurRadius: 4.0, color: Colors.black),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.profile.isVerified) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.lightBlueAccent.withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.lightBlueAccent,
                                    size: 26,
                                    shadows: [
                                      Shadow(blurRadius: 4, color: Colors.black54),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Botão Ver Perfil Completo
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
                              // Processar a ação retornada
                              if (result == 'like' && widget.onLike != null) {
                                widget.onLike!(widget.profile);
                              } else if (result == 'dislike' && widget.onDislike != null) {
                                widget.onDislike!(widget.profile);
                              } else if (result == 'super' && widget.onSuperLike != null) {
                                widget.onSuperLike!(widget.profile);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                            ),
                            child: const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Cidade
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.profile.city,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Interesses/Gostos
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.profile.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
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

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  @override
  void initState() {
    super.initState();
    // Track Facebook Pixel CompleteRegistration event when Tutorial screen loads
    _trackPixelCompleteRegistration();
  }

  void _trackPixelCompleteRegistration() {
    if (kIsWeb) {
      try {
        PlatformUtils.trackCompleteRegistration();
      } catch (e) {
        print('Erro ao trackear Pixel: $e');
      }
    }
  }

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
                  background: Container(
                    // Adiciona margem superior para respeitar a safe area
                    margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Foto Atual
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: widget.profile.imageUrls[_currentImageIndex],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                              errorWidget: (ctx, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 80, color: Colors.grey),
                              ),
                            ),
                          ),
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

                      // Áreas de toque para navegar (esquerda e direita)
                      if (widget.profile.imageUrls.length > 1) ...[
                        // Toque na esquerda - foto anterior
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width * 0.3, // 30% da tela
                          child: GestureDetector(
                            onTap: () {
                              if (_currentImageIndex > 0) {
                                setState(() => _currentImageIndex--);
                              }
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        // Toque na direita - próxima foto
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width * 0.3, // 30% da tela
                          child: GestureDetector(
                            onTap: () {
                              if (_currentImageIndex < widget.profile.imageUrls.length - 1) {
                                setState(() => _currentImageIndex++);
                              }
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                      
                      // Indicadores de Página (Bolinhas na parte inferior)
                      if (widget.profile.imageUrls.length > 1)
                        Positioned(
                          bottom: 50,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.profile.imageUrls.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 10 : 8,
                                height: _currentImageIndex == index ? 10 : 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 1,
                                  ),
                                  boxShadow: _currentImageIndex == index
                                      ? [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Contador de fotos no canto inferior
                      if (widget.profile.imageUrls.length > 1)
                        Positioned(
                          bottom: 40,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${widget.profile.imageUrls.length}',
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
                                    if (widget.profile.isVerified) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.blue.withOpacity(0.15), Colors.lightBlueAccent.withOpacity(0.1)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.3),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                                        ),
                                        child: const Icon(Icons.verified, color: Colors.blue, size: 28),
                                      ),
                                    ],
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
                      
                      // Botão de Denúncia
                      const SizedBox(height: 30),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _showReportDialog(context),
                          icon: const Icon(Icons.flag_outlined, color: Colors.red, size: 18),
                          label: const Text(
                            'Denunciar Perfil',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            backgroundColor: Colors.red.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
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
            bottom: 30 + MediaQuery.of(context).padding.bottom,
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

  // Tipos de denúncia disponíveis
  static const Map<String, String> _reportTypes = {
    'harassment': 'Assédio',
    'fake_profile': 'Perfil falso',
    'inappropriate_content': 'Conteúdo impróprio',
    'spam': 'Spam / Propaganda',
    'underage': 'Menor de idade',
    'offensive_behavior': 'Comportamento ofensivo',
    'other': 'Outros',
  };

  void _showReportDialog(BuildContext context) {
    String? selectedType;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.flag, color: Colors.red[400], size: 28),
              const SizedBox(width: 10),
              const Text(
                'Denunciar Perfil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Por que você está denunciando ${widget.profile.name}?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                ..._reportTypes.entries.map((entry) => RadioListTile<String>(
                  title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                  value: entry.key,
                  groupValue: selectedType,
                  activeColor: const Color(0xFF667eea),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (val) => setDialogState(() => selectedType = val),
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Adicione mais detalhes (opcional)',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF667eea)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: selectedType == null
                  ? null
                  : () => _submitReport(ctx, selectedType!, descriptionController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Enviar Denúncia'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(BuildContext dialogContext, String reportType, String description) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      await supabase.from('reports').insert({
        'reporter_id': userId,
        'reported_id': widget.profile.id,
        'report_type': reportType,
        'description': description.isNotEmpty ? description : null,
      });

      Navigator.pop(dialogContext); // Fechar dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Denúncia enviada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao enviar denúncia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao enviar denúncia. Tente novamente.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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

// --- Match Animation Overlay Widget ---
class MatchAnimationOverlay extends StatefulWidget {
  final Profile targetProfile;
  final Profile myProfile;
  final VoidCallback onViewProfile;
  final VoidCallback onContinue;

  const MatchAnimationOverlay({
    super.key,
    required this.targetProfile,
    required this.myProfile,
    required this.onViewProfile,
    required this.onContinue,
  });

  @override
  State<MatchAnimationOverlay> createState() => _MatchAnimationOverlayState();
}

class _MatchAnimationOverlayState extends State<MatchAnimationOverlay> with TickerProviderStateMixin {
  late AnimationController _heartController;
  final List<Widget> _hearts = [];

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Generate floating hearts
    for (int i = 0; i < 15; i++) {
      _hearts.add(_buildFloatingHeart());
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Widget _buildFloatingHeart() {
    // Randomize position and size
    // In a real scenario, use Random()
    // For now, simpler implementation
    return Positioned(
      left: 50.0 + (DateTime.now().microsecondsSinceEpoch % 250),
      bottom: -50,
      child: AnimatedBuilder(
        animation: _heartController,
        builder: (context, child) {
          final val = _heartController.value;
          // Staggered animation based on index/random requires more complex setup
          // Simple vertical float for demo
          return Transform.translate(
             offset: Offset(0, -500 * val), // Float up
             child: Opacity(
               opacity: 1.0 - val,
               child: Icon(Icons.favorite, color: Colors.pinkAccent, size: 20 + (val * 30)),
             ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Interesse Recíproco! ❤️',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 40),
            
            // Avatars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // You (Real user image)
                _buildAvatar(widget.myProfile.imageUrls.isNotEmpty 
                    ? widget.myProfile.imageUrls.first 
                    : 'https://via.placeholder.com/150'),
               
                const SizedBox(width: 20),
                const Icon(Icons.favorite, color: Colors.white, size: 40),
                const SizedBox(width: 20),
                
                // Them
                _buildAvatar(widget.targetProfile.imageUrls.isNotEmpty 
                    ? widget.targetProfile.imageUrls.first 
                    : 'https://via.placeholder.com/150'),
              ],
            ),
             const SizedBox(height: 20),
             Text(
              'Você e ${widget.targetProfile.name} se curtiram!',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
             ),
             const SizedBox(height: 50),
             
             // Buttons
             ElevatedButton(
               onPressed: widget.onViewProfile,
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.white,
                 foregroundColor: Colors.pinkAccent,
                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
               ),
               child: const Text('VER PERFIL', style: TextStyle(fontWeight: FontWeight.bold)),
             ),
             const SizedBox(height: 15),
             TextButton(
               onPressed: widget.onContinue,
               child: const Text('Continuar Navegando', style: TextStyle(color: Colors.white)),
             ),
          ],
        ),
        // Floating hearts
        ..._hearts,
      ],
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundImage: CachedNetworkImageProvider(url),
      ),
    );
  }
}
