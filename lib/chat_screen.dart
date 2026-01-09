import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:novo_app/main.dart'; // For Profile class
import 'package:cached_network_image/cached_network_image.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final Profile targetProfile;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.targetProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;
  RealtimeChannel? _messagesChannel;
  
  // Pagination
  final int _perPage = 20;
  bool _isMoreLoading = false;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchMessages();
    _subscribeToMessages();
    
    // Listener for infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isMoreLoading &&
          _hasMoreMessages) {
        _loadMoreMessages();
      }
    });
  }

  void _subscribeToMessages() {
    final supabase = Supabase.instance.client;
    _messagesChannel = supabase.channel('chat_${widget.matchId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'match_id',
          value: widget.matchId,
        ),
        callback: (payload) {
          print('📨 New message received via Realtime!');
          final newMsg = payload.newRecord;
          if (mounted && newMsg != null) {
            // Verificar se a mensagem já existe para evitar duplicatas
            final messageId = newMsg['id'];
            final alreadyExists = _messages.any((msg) => msg['id'] == messageId);
            
            if (!alreadyExists) {
              setState(() {
                // Inserir no início (fundo da tela) pois a lista é invertida
                _messages.insert(0, newMsg);
              });
              // Não precisa scrollar se já estivermos lá embaixo (index 0)
              // Mas se o usuário enviou, podemos garantir
            }
            
            // Mark as read if sender is not me
            if (newMsg['sender_id'] != _currentUserId) {
              supabase.from('messages')
                  .update({'read': true})
                  .eq('id', newMsg['id'])
                  .then((_) => print('✅ Message marked as read'));
            }
          }
        },
      )
      .subscribe();
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('messages')
          .select()
          .eq('match_id', widget.matchId)
          .order('created_at', ascending: false) // Newest first
          .limit(_perPage);
          
      // Mark unread messages as read
      _markMessagesAsRead();

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
          _hasMoreMessages = data.length >= _perPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao buscar mensagens: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isMoreLoading) return;
    
    setState(() => _isMoreLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('messages')
          .select()
          .eq('match_id', widget.matchId)
          .order('created_at', ascending: false)
          .range(_messages.length, _messages.length + _perPage - 1);
          
      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            _messages.addAll(List<Map<String, dynamic>>.from(data));
          }
          if (data.length < _perPage) {
            _hasMoreMessages = false;
          }
          _isMoreLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar mais mensagens: $e');
      if (mounted) {
        setState(() => _isMoreLoading = false);
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null) return;
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'read': true})
          .eq('match_id', widget.matchId)
          .neq('sender_id', _currentUserId as Object)
          .eq('read', false);
    } catch (e) {
       print('Erro ao marcar lido: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    _messageController.clear();

    try {
      final supabase = Supabase.instance.client;
      // Optimistic UI Update (optional, but Realtime is fast enough generally)
      // For now relying on Realtime to add it to the list
      
      await supabase.from('messages').insert({
        'match_id': widget.matchId,
        'sender_id': _currentUserId,
        'content': text,
      });
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Com reverse=true, 0 é o "fundo"
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: CachedNetworkImageProvider(
                widget.targetProfile.imageUrls.isNotEmpty
                    ? widget.targetProfile.imageUrls.first
                    : 'https://via.placeholder.com/150',
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.targetProfile.name,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma mensagem ainda',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Diga oi para ${widget.targetProfile.name}!',
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        reverse: true, // Começa de baixo pra cima
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        // +1 para o spinner de loading no topo
                        itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Se for o último item e tiver mais, mostra loader
                          if (index == _messages.length) {
                             return const Padding(
                               padding: EdgeInsets.symmetric(vertical: 20),
                               child: Center(child: CircularProgressIndicator()),
                             );
                          }
                          
                          final message = _messages[index];
                          final isMe = message['sender_id'] == _currentUserId;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),

          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 22),
                      onPressed: _sendMessage,
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

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
              : null,
          color: isMe ? null : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Text(
          message['content'] ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
