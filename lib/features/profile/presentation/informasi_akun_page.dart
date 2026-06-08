import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../data/profile_api_service.dart';

class InformasiAkunPage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const InformasiAkunPage({super.key, this.onProfileUpdated});

  @override
  State<InformasiAkunPage> createState() => _InformasiAkunPageState();
}

class _InformasiAkunPageState extends State<InformasiAkunPage> {
  final ProfileApiService _profileApiService = ProfileApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _avatarUploaded = false;
  String? _error;
  ProfileUserDto? _user;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _profileApiService.fetchMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _usernameController.text = user.username;
        _phoneController.text = user.phone;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppNotice.humanizeMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || username.isEmpty || phone.isEmpty) {
      AppNotice.show(
        context,
        'Semua field wajib diisi.',
        type: AppNoticeType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _profileApiService.updateProfile(
        name: name,
        username: username,
        phone: phone,
        avatarUrl: _user?.avatarUrl,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      widget.onProfileUpdated?.call();

      AppNotice.show(
        context,
        'Informasi akun berhasil diperbarui.',
        type: AppNoticeType.success,
      );

      Navigator.pop(context, true); // Go back with success flag to trigger refresh
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppNotice.show(
        context,
        AppNotice.humanizeMessage(e),
        type: AppNoticeType.error,
      );
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFC6620C)),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _processAvatarPick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFC6620C)),
                title: const Text('Ambil dengan Kamera'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _processAvatarPick(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processAvatarPick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
      });

      final updatedUser = await _profileApiService.uploadAvatar(pickedFile.path);

      if (!mounted) return;
      setState(() {
        _user = updatedUser;
        _avatarUploaded = true;
        _isLoading = false;
      });

      widget.onProfileUpdated?.call();

      AppNotice.show(
        context,
        'Foto profil berhasil diperbarui.',
        type: AppNoticeType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppNotice.show(
        context,
        AppNotice.humanizeMessage(e),
        type: AppNoticeType.error,
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == '-') return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(
          color: Colors.black,
          size: 20,
          onPressed: () {
            Navigator.pop(context, _avatarUploaded);
          },
        ),
        title: const Text(
          "Informasi Akun",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                      const SizedBox(height: 10),
                      Text(_error!),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture Section
                      Center(
                        child: Stack(
                          children: [
                            _user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
                                ? CircleAvatar(
                                    radius: 50,
                                    backgroundImage: NetworkImage(_user!.avatarUrl!),
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC7985F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getInitials(_nameController.text),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC6620C),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  onPressed: _pickAndUploadAvatar,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Input Fields
                      _buildLabel('Nama Lengkap'),
                      const SizedBox(height: 6),
                      _buildInput(
                        hint: 'Masukkan nama lengkap',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 18),

                      _buildLabel('Username'),
                      const SizedBox(height: 6),
                      _buildInput(
                        hint: 'Masukkan username',
                        controller: _usernameController,
                      ),
                      const SizedBox(height: 18),

                      _buildLabel('Nomor Telepon'),
                      const SizedBox(height: 6),
                      _buildInput(
                        hint: 'Masukkan nomor telepon',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC6620C),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0xFFC6620C).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInput({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
