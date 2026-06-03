import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/folder_model.dart';

class FolderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _foldersRef {
    return _firestore.collection('users').doc(_uid).collection('folders');
  }

  Stream<List<FolderModel>> watchFolders() {
    return _foldersRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FolderModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> createFolder(String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('O nome da pasta não pode estar vazio.');
    }

    await _foldersRef.add({
      'name': cleanName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFolder({
    required String folderId,
    required String name,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('O nome da pasta não pode estar vazio.');
    }

    await _foldersRef.doc(folderId).update({
      'name': cleanName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFolder(String folderId) async {
    final notesSnapshot = await _foldersRef
        .doc(folderId)
        .collection('notes')
        .get();

    final batch = _firestore.batch();

    for (final note in notesSnapshot.docs) {
      batch.delete(note.reference);
    }

    batch.delete(_foldersRef.doc(folderId));

    await batch.commit();
  }
}
