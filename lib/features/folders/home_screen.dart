import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/folder_model.dart';
import '../../services/auth_service.dart';
import '../../services/folder_service.dart';
import '../notes/notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FolderService _folderService = FolderService();
  final AuthService _authService = AuthService();

  Future<void> _showFolderDialog({FolderModel? folder}) async {
    final controller = TextEditingController(text: folder?.name ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(folder == null ? 'Nova pasta' : 'Editar pasta'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome da pasta'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (folder == null) {
                    await _folderService.createFolder(controller.text);
                  } else {
                    await _folderService.updateFolder(
                      folderId: folder.id,
                      name: controller.text,
                    );
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Erro: $error')));
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(FolderModel folder) async {
    await _folderService.deleteFolder(folder.id);
  }

  Future<void> _logout() async {
    await _authService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AppAssets.logo, height: 34),
            const SizedBox(width: 10),
            const Text('Wyvern Notes'),
          ],
        ),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFolderDialog(),
        child: const Icon(Icons.create_new_folder_outlined),
      ),
      body: StreamBuilder<List<FolderModel>>(
        stream: _folderService.watchFolders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          }

          final folders = snapshot.data ?? [];

          if (folders.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma pasta criada ainda.',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final folder = folders[index];

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.background,
                    child: Icon(
                      Icons.folder_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text(
                    folder.name,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Atualizada em ${DateFormatter.format(folder.updatedAt)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotesScreen(folder: folder),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showFolderDialog(folder: folder);
                      }

                      if (value == 'delete') {
                        await _deleteFolder(folder);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
