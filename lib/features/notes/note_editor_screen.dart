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

class _ChecklistDraftItem {
  final TextEditingController controller;
  bool isDone;

  _ChecklistDraftItem({
    required this.controller,
    required this.isDone,
  });
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NoteService _noteService = NoteService();
  final PdfExportService _pdfExportService = PdfExportService();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final List<_ChecklistDraftItem> _checklistItems = [];

  bool _saving = false;
  bool _isCompleted = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _isCompleted = widget.note?.isCompleted ?? false;

    for (final item in widget.note?.checklist ?? const <ChecklistItemModel>[]) {
      _checklistItems.add(
        _ChecklistDraftItem(
          controller: TextEditingController(text: item.text),
          isDone: item.isDone,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();

    for (final item in _checklistItems) {
      item.controller.dispose();
    }

    super.dispose();
  }

  List<ChecklistItemModel> _buildChecklistPayload() {
    return _checklistItems
        .map(
          (item) => ChecklistItemModel(
            text: item.controller.text.trim(),
            isDone: item.isDone,
          ),
        )
        .where((item) => item.text.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final checklist = _buildChecklistPayload();

      if (_isEditing) {
        await _noteService.updateNote(
          folderId: widget.folder.id,
          noteId: widget.note!.id,
          title: _titleController.text,
          content: _contentController.text,
          isCompleted: _isCompleted,
          checklist: checklist,
        );
      } else {
        await _noteService.createNote(
          folderId: widget.folder.id,
          title: _titleController.text,
          content: _contentController.text,
          isCompleted: _isCompleted,
          checklist: checklist,
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
      checklist: _buildChecklistPayload(),
    );
  }

  void _addChecklistItem() {
    setState(() {
      _checklistItems.add(
        _ChecklistDraftItem(
          controller: TextEditingController(),
          isDone: false,
        ),
      );
    });
  }

  void _removeChecklistItem(int index) {
    final item = _checklistItems.removeAt(index);
    item.controller.dispose();
    setState(() {});
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Titulo da nota',
                  hintStyle: TextStyle(color: AppColors.muted),
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: Colors.white24),
              SwitchListTile(
                value: _isCompleted,
                activeColor: AppColors.secondary,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Marcar nota como concluida',
                  style: TextStyle(color: AppColors.textLight),
                ),
                subtitle: const Text(
                  'Notas concluidas saem da lista principal de ativas.',
                  style: TextStyle(color: AppColors.muted),
                ),
                onChanged: (value) => setState(() => _isCompleted = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                minLines: 8,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Comece a escrever...',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.secondary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Checklist',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addChecklistItem,
                    icon: const Icon(Icons.add, color: AppColors.secondary),
                    label: const Text(
                      'Adicionar item',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              if (_checklistItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    'Adicione itens para transformar a nota em checklist.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ...List.generate(_checklistItems.length, (index) {
                final item = _checklistItems[index];

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: item.isDone,
                        activeColor: AppColors.secondary,
                        onChanged: (value) {
                          setState(() => item.isDone = value ?? false);
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: item.controller,
                          style: const TextStyle(color: AppColors.textLight),
                          decoration: InputDecoration(
                            hintText: 'Item da checklist',
                            hintStyle: const TextStyle(color: AppColors.muted),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeChecklistItem(index),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
