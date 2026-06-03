import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/folder_model.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatelessWidget {
  final FolderModel folder;

  NotesScreen({super.key, required this.folder});

  final NoteService _noteService = NoteService();

  Future<void> _deleteNote({
    required String folderId,
    required String noteId,
  }) async {
    await _noteService.deleteNote(folderId: folderId, noteId: noteId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(folder.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => NoteEditorScreen(folder: folder)),
          );
        },
        child: const Icon(Icons.note_add_outlined),
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: _noteService.watchNotes(folder.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma anotação nesta pasta.',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = notes[index];

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
                  title: Text(
                    note.title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${note.content.length > 80 ? '${note.content.substring(0, 80)}...' : note.content}\nAtualizada em ${DateFormatter.format(note.updatedAt)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            NoteEditorScreen(folder: folder, note: note),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    onPressed: () async {
                      await _deleteNote(folderId: folder.id, noteId: note.id);
                    },
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
