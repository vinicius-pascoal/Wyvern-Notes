import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuario nao autenticado.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _notesRef(String folderId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('folders')
        .doc(folderId)
        .collection('notes');
  }

  Stream<List<NoteModel>> watchNotes(String folderId) {
    return _notesRef(folderId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> createNote({
    required String folderId,
    required String title,
    required String content,
    required bool isCompleted,
    required List<ChecklistItemModel> checklist,
  }) async {
    await _notesRef(folderId).add({
      'title': title.trim().isEmpty ? 'Sem titulo' : title.trim(),
      'content': content.trim(),
      'isFavorite': false,
      'isCompleted': isCompleted,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateFolderDate(folderId);
  }

  Future<void> updateNote({
    required String folderId,
    required String noteId,
    required String title,
    required String content,
    required bool isCompleted,
    required List<ChecklistItemModel> checklist,
  }) async {
    await _notesRef(folderId).doc(noteId).update({
      'title': title.trim().isEmpty ? 'Sem titulo' : title.trim(),
      'content': content.trim(),
      'isCompleted': isCompleted,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateFolderDate(folderId);
  }

  Future<void> deleteNote({
    required String folderId,
    required String noteId,
  }) async {
    await _notesRef(folderId).doc(noteId).delete();

    await _updateFolderDate(folderId);
  }

  Future<void> toggleFavorite({
    required String folderId,
    required String noteId,
    required bool isFavorite,
  }) async {
    await _notesRef(folderId).doc(noteId).update({
      'isFavorite': isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateFolderDate(folderId);
  }

  Future<void> toggleCompleted({
    required String folderId,
    required String noteId,
    required bool isCompleted,
  }) async {
    await _notesRef(folderId).doc(noteId).update({
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateFolderDate(folderId);
  }

  Future<void> _updateFolderDate(String folderId) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('folders')
        .doc(folderId)
        .update({'updatedAt': FieldValue.serverTimestamp()});
  }
}
