import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/folder_model.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';
import '../../services/pdf_export_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final FolderModel folder;
  final NoteModel? note;

  const NoteEditorScreen({super.key, required this.folder, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NoteService _noteService = NoteService();
  final PdfExportService _pdfExportService = PdfExportService();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.title ?? '');

    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await _noteService.updateNote(
          folderId: widget.folder.id,
          noteId: widget.note!.id,
          title: _titleController.text,
          content: _contentController.text,
        );
      } else {
        await _noteService.createNote(
          folderId: widget.folder.id,
          title: _titleController.text,
          content: _contentController.text,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    await _pdfExportService.exportNote(
      folderName: widget.folder.name,
      title: _titleController.text,
      content: _contentController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar nota' : 'Nova nota'),
        actions: [
          IconButton(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Título da nota',
                  hintStyle: TextStyle(color: AppColors.muted),
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Comece a escrever...',
                    hintStyle: TextStyle(color: AppColors.muted),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
