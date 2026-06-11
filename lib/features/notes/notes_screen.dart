import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/folder_model.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  final FolderModel folder;

  const NotesScreen({super.key, required this.folder});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteNote({
    required String folderId,
    required String noteId,
  }) async {
    await _noteService.deleteNote(folderId: folderId, noteId: noteId);
  }

  Future<void> _toggleFavorite(NoteModel note) async {
    await _noteService.toggleFavorite(
      folderId: widget.folder.id,
      noteId: note.id,
      isFavorite: !note.isFavorite,
    );
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<NoteModel>.from(notes)
        : notes.where((note) {
            return note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query);
          }).toList();

    filtered.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }

  String _buildPreview(String content) {
    if (content.isEmpty) {
      return 'Sem conteudo';
    }

    return content.length > 80 ? '${content.substring(0, 80)}...' : content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.folder.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(folder: widget.folder),
            ),
          );
        },
        child: const Icon(Icons.note_add_outlined),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Buscar por titulo ou conteudo',
                hintStyle: const TextStyle(color: Colors.black45),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NoteModel>>(
              stream: _noteService.watchNotes(widget.folder.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  );
                }

                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma anotacao nesta pasta.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }

                final filteredNotes = _filterNotes(notes);

                if (filteredNotes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma nota encontrada para a busca.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];

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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (note.isFavorite)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${_buildPreview(note.content)}\nAtualizada em ${DateFormatter.format(note.updatedAt)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NoteEditorScreen(
                                folder: widget.folder,
                                note: note,
                              ),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                note.isFavorite
                                    ? Icons.star
                                    : Icons.star_outline,
                                color: note.isFavorite
                                    ? Colors.amber
                                    : Colors.black45,
                              ),
                              onPressed: () => _toggleFavorite(note),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                              ),
                              onPressed: () async {
                                await _deleteNote(
                                  folderId: widget.folder.id,
                                  noteId: note.id,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
