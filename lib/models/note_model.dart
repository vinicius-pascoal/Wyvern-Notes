import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistItemModel {
  final String text;
  final bool isDone;

  const ChecklistItemModel({
    required this.text,
    required this.isDone,
  });

  factory ChecklistItemModel.fromMap(Map<String, dynamic> data) {
    return ChecklistItemModel(
      text: data['text'] ?? '',
      isDone: data['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isDone': isDone,
    };
  }
}

class NoteModel {
  final String id;
  final String title;
  final String content;
  final bool isFavorite;
  final bool isCompleted;
  final List<ChecklistItemModel> checklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.isFavorite,
    required this.isCompleted,
    required this.checklist,
    required this.createdAt,
    required this.updatedAt,
  });

  int get completedChecklistCount =>
      checklist.where((item) => item.isDone).length;

  factory NoteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawChecklist = data['checklist'];

    return NoteModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
      isCompleted: data['isCompleted'] ?? false,
      checklist: rawChecklist is List
          ? rawChecklist
              .whereType<Map>()
              .map(
                (item) => ChecklistItemModel.fromMap(
                  item.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                ),
              )
              .toList()
          : const [],
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.now();
  }
}
