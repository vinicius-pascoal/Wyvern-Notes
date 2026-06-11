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

  Future<void> _toggleCompleted(NoteModel note) async {
    await _noteService.toggleCompleted(
      folderId: widget.folder.id,
      noteId: note.id,
      isCompleted: !note.isCompleted,
    );
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<NoteModel>.from(notes)
        : notes.where((note) {
            return note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query) ||
                note.checklist.any(
                  (item) => item.text.toLowerCase().contains(query),
                );
          }).toList();

    filtered.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }

  String _buildPreview(NoteModel note) {
    if (note.content.isNotEmpty) {
      return note.content.length > 80
          ? '${note.content.substring(0, 80)}...'
          : note.content;
    }

    if (note.checklist.isNotEmpty) {
      return '${note.completedChecklistCount}/${note.checklist.length} itens concluidos';
    }

    return 'Sem conteudo';
  }

  Widget _buildNoteTile(NoteModel note) {
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
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  decoration: note.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
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
          '${_buildPreview(note)}\nAtualizada em ${DateFormatter.format(note.updatedAt)}',
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
              tooltip: note.isCompleted
                  ? 'Reabrir nota'
                  : 'Marcar nota como concluida',
              icon: Icon(
                note.isCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: note.isCompleted
                    ? Colors.green
                    : Colors.black45,
              ),
              onPressed: () => _toggleCompleted(note),
            ),
            IconButton(
              tooltip: note.isFavorite
                  ? 'Remover dos favoritos'
                  : 'Favoritar nota',
              icon: Icon(
                note.isFavorite ? Icons.star : Icons.star_outline,
                color: note.isFavorite ? Colors.amber : Colors.black45,
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
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ),
    );
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
                hintText: 'Buscar por titulo, conteudo ou checklist',
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
                  return _buildEmptyState('Nenhuma anotacao nesta pasta.');
                }

                final filteredNotes = _filterNotes(notes);
                final activeNotes = filteredNotes
                    .where((note) => !note.isCompleted)
                    .toList();
                final completedNotes = filteredNotes
                    .where((note) => note.isCompleted)
                    .toList();

                if (activeNotes.isEmpty && completedNotes.isEmpty) {
                  return _buildEmptyState(
                    'Nenhuma nota encontrada para a busca.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Notas ativas',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (activeNotes.isEmpty)
                      _buildEmptyState('Nenhuma nota ativa encontrada.')
                    else
                      ...activeNotes.map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildNoteTile(note),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: completedNotes.isNotEmpty,
                        tilePadding: EdgeInsets.zero,
                        collapsedIconColor: AppColors.muted,
                        iconColor: AppColors.textLight,
                        title: Text(
                          'Concluidas (${completedNotes.length})',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: completedNotes.isEmpty
                            ? [
                                _buildEmptyState(
                                  'Nenhuma nota concluida por enquanto.',
                                ),
                              ]
                            : completedNotes
                                .map(
                                  (note) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildNoteTile(note),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
