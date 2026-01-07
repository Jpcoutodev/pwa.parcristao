import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'package:novo_app/main.dart'; // Para acessar a classe Profile, se necessário, ou mover Profile para um arquivo separado

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _churchController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedDate;
  String? _selectedFaith;
  String _selectedMinistry = 'Participante';
  List<String> _selectedInterests = [];
  
  // Verification status
  bool _isVerified = false;
  bool _photosChanged = false; // Track if photos were modified
  
  // Images
  // Lista mista: pode conter String (url) ou XFile (arquivo novo)
  List<dynamic> _profileImages = []; 
  List<dynamic> _originalImages = []; // To compare if photos changed
  final ImagePicker _picker = ImagePicker();

  // Colors (Mesma paleta do Onboarding)
  final Color _primaryColor = const Color(0xFF667eea);
  final Color _secondaryColor = const Color(0xFF764ba2);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase.from('profiles').select().eq('id', userId).single();
      
      setState(() {
        _nameController.text = data['name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _cityController.text = data['city'] ?? '';
        _churchController.text = data['church'] ?? '';
        // Validar Ministério (evitar crash do Dropdown)
        String serverMinistry = data['ministry'] ?? 'Participante';
        const validMinistries = ['Participante', 'Líder', 'Louvor', 'Pastoral', 'Ensino', 'Mídia', 'Outro'];
        if (validMinistries.contains(serverMinistry)) {
          _selectedMinistry = serverMinistry;
        } else {
          _selectedMinistry = 'Participante';
        }

        _selectedGender = data['gender'];
        _selectedFaith = data['faith'];
        _selectedInterests = List<String>.from(data['interests'] ?? []);
        
        if (data['age'] != null) {
           final now = DateTime.now();
           // Safely handle age as num
           final age = (data['age'] as num).toInt();
           _selectedDate = DateTime(now.year - age, 1, 1);
        }

        // Images
        if (data['image_urls'] != null) {
          _profileImages = List<dynamic>.from(data['image_urls']);
          _originalImages = List<dynamic>.from(data['image_urls']); // Store original
        }
        
        // Verification status
        _isVerified = data['is_verified'] ?? false;
        
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar perfil: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<bool> _showVerificationWarning() async {
    if (!_isVerified || _photosChanged) {
      return true; // Already lost verification or not verified
    }
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Perda de Verificação',
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
              'Seu perfil está verificado!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Alterar suas fotos removerá o selo de verificação.',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Você precisará verificar seu perfil novamente após a alteração.',
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
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      setState(() => _photosChanged = true);
    }
    return result ?? false;
  }

  Future<void> _pickImage() async {
    // Show warning if verified
    final proceed = await _showVerificationWarning();
    if (!proceed) return;
    
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1440,
        maxHeight: 1440,
        requestFullMetadata: false,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          // Adiciona os novos arquivos à lista
          _profileImages.addAll(images);
          // Limit to 6
          if (_profileImages.length > 6) {
             _profileImages = _profileImages.sublist(0, 6);
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Máximo de 6 fotos permitidas.')),
             );
          }
        });
      }
    } catch (e) {
      print('Erro ao selecionar fotos: $e');
    }
  }

  Future<void> _removeImage(int index) async {
    // Show warning if verified
    final proceed = await _showVerificationWarning();
    if (!proceed) return;
    
    setState(() {
      _profileImages.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma foto.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. Upload new photos and collect all URLs
      List<String> finalImageUrls = [];

      for (var item in _profileImages) {
        if (item is String) {
          // Já é URL, mantém
          finalImageUrls.add(item);
        } else if (item is XFile) {
          // É arquivo novo, upload
          try {
            final fileExt = item.path.split('.').last;
            final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}.$fileExt';
            
            // Usar uploadBinary para garantir compatibilidade Web/Mobile com XFile
            final bytes = await item.readAsBytes();
            await supabase.storage.from('profile-photos').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '3600', upsert: false),
            );
             
            final imageUrl = supabase.storage.from('profile-photos').getPublicUrl(fileName);
            finalImageUrls.add(imageUrl);
          } catch (uploadError) {
             print('Erro upload: $uploadError');
             // Se falhar upload de um, ignora? Ou avisa?
          }
        }
      }

      // 2. Update Profile
      final Map<String, dynamic> profileData = {
        'id': userId,
        'name': _nameController.text,
        'age': _selectedDate != null ? (DateTime.now().year - _selectedDate!.year) : 0,
        'gender': _selectedGender,
        'bio': _bioController.text,
        'city': _cityController.text,
        'church': _churchController.text,
        'ministry': _selectedMinistry,
        'faith': _selectedFaith,
        'interests': _selectedInterests,
        'image_urls': finalImageUrls,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Invalidate verification if photos were changed
      if (_photosChanged) {
        profileData['is_verified'] = false;
      }
      
      await supabase.from('profiles').upsert(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        Navigator.pop(context, true); // Retorna true para dar refresh
      }

    } catch (e) {
      print('Erro ao salvar: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao atualizar: $e')),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Salvar', 
              style: TextStyle(
                color: _primaryColor, 
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- FOTOS ---
                    const Text('Suas Fotos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    const Text('Segure e arraste para reordenar (futuro) ou adicione novas.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 15),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _profileImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _profileImages.length) {
                          // Add Button
                          if (_profileImages.length >= 6) return const SizedBox.shrink();
                          return GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Icon(Icons.add_a_photo, color: Colors.grey[400]),
                            ),
                          );
                        }

                        final item = _profileImages[index];
                        ImageProvider imageProvider;
                        
                        if (item is String) {
                          imageProvider = NetworkImage(item);
                        } else if (item is XFile) {
                           if (kIsWeb) {
                             imageProvider = NetworkImage(item.path);
                           } else {
                             imageProvider = FileImage(File(item.path));
                           }
                        } else {
                          return const SizedBox();
                        }

                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                            if (index == 0)
                              Positioned(
                                bottom: 0, right: 0, left: 0,
                                child: Container(
                                  color: _primaryColor.withOpacity(0.8),
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: const Text(
                                    'Principal', 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontSize: 10)
                                  ),
                                ),
                              )
                          ],
                        );
                      },
                    ),

                    const Divider(height: 40),

                    // --- INFO ---
                    const Text('Sobre Mim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 15),

                    _buildTextField('Nome', _nameController, icon: Icons.person),
                    const SizedBox(height: 15),
                    
                    _buildTextField('Bio', _bioController, icon: Icons.edit_note, maxLines: 3),
                    const SizedBox(height: 15),

                    _buildTextField('Cidade', _cityController, icon: Icons.location_on),
                    const SizedBox(height: 15),

                    _buildTextField('Igreja', _churchController, icon: Icons.church),
                    const SizedBox(height: 15),

                    // Dropdowns simplificados
                    DropdownButtonFormField<String>(
                      value: _selectedMinistry,
                      decoration: const InputDecoration(
                        labelText: 'Ministério',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: ['Participante', 'Líder', 'Louvor', 'Pastoral', 'Ensino', 'Mídia', 'Outro']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedMinistry = v!),
                    ),
                    
                    const SizedBox(height: 20),
                    
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obrigatório';
        return null;
      },
    );
  }
}

