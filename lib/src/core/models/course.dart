import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore schema for learning content hierarchy:
///
/// courses/{courseId}
///   parts/{partId}
///     subparts/{subpartId}
///       lessons/{lessonId}
///
/// questionPapers/{paperId}
///   questions/{questionId}
///
/// banners/{bannerId}

class CourseModel {
  final String id;
  final String title; // e.g. "Java", "Python"
  final String iconName; // mapped to Icons in UI
  final int color; // ARGB int
  final String description;
  final int order;
  final bool catalogEnabled; // show in the home catalog (Img 2)
  final DateTime? createdAt;

  const CourseModel({
    required this.id,
    required this.title,
    this.iconName = 'code',
    this.color = 0xFF4F46E5,
    this.description = '',
    this.order = 0,
    this.catalogEnabled = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'iconName': iconName,
        'color': color,
        'description': description,
        'order': order,
        'catalogEnabled': catalogEnabled,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory CourseModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      iconName: data['iconName'] ?? 'code',
      color: (data['color'] is int)
          ? data['color'] as int
          : int.tryParse(data['color']?.toString() ?? '') ?? 0xFF4F46E5,
      description: data['description'] ?? '',
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
      catalogEnabled: data['catalogEnabled'] ?? true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class PartModel {
  final String id;
  final String title;
  final String description;
  final int order;

  const PartModel({
    required this.id,
    required this.title,
    this.description = '',
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory PartModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PartModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }
}

class SubpartModel {
  final String id;
  final String title;
  final String description;
  final int order;

  const SubpartModel({
    required this.id,
    required this.title,
    this.description = '',
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory SubpartModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SubpartModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }
}

class LessonModel {
  final String id;
  final String title;
  final String description;
  final String youtubeUrl; // YouTube unlisted URL
  final String duration; // display string e.g. "10:24"
  final int youtubePositionSec; // start playback at this offset (seconds)
  final String whiteboardImageUrl; // Firebase Storage URL (Img 1)
  final String codeSample;
  final String notes;
  final int order;

  const LessonModel({
    required this.id,
    required this.title,
    this.description = '',
    this.youtubeUrl = '',
    this.duration = '',
    this.youtubePositionSec = 0,
    this.whiteboardImageUrl = '',
    this.codeSample = '',
    this.notes = '',
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'youtubeUrl': youtubeUrl,
        'duration': duration,
        'youtubePositionSec': youtubePositionSec,
        'whiteboardImageUrl': whiteboardImageUrl,
        'codeSample': codeSample,
        'notes': notes,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory LessonModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return LessonModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      youtubeUrl: data['youtubeUrl'] ?? '',
      duration: data['duration'] ?? '',
      youtubePositionSec: (data['youtubePositionSec'] is num)
          ? (data['youtubePositionSec'] as num).toInt()
          : 0,
      whiteboardImageUrl: data['whiteboardImageUrl'] ?? '',
      codeSample: data['codeSample'] ?? '',
      notes: data['notes'] ?? '',
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toNavigationMap() => {
        'id': id,
        'title': title,
        'description': description,
        'youtubeUrl': youtubeUrl,
        'duration': duration,
        'youtubePositionSec': youtubePositionSec,
        'whiteboardImageUrl': whiteboardImageUrl,
        'codeSample': codeSample,
        'notes': notes,
      };
}

class QuestionPaperModel {
  final String id;
  final String title;
  final String type; // 'mcq' or 'coding'
  final String subject; // e.g. Java, Python
  final int timeLimitMinutes;
  final List<Map<String, dynamic>> questions;

  const QuestionPaperModel({
    required this.id,
    required this.title,
    required this.type,
    this.subject = 'General',
    this.timeLimitMinutes = 30,
    this.questions = const [],
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': type,
        'subject': subject,
        'timeLimitMinutes': timeLimitMinutes,
        'questions': questions,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory QuestionPaperModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return QuestionPaperModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'mcq',
      subject: data['subject'] ?? 'General',
      timeLimitMinutes: (data['timeLimitMinutes'] is num)
          ? (data['timeLimitMinutes'] as num).toInt()
          : 30,
      questions: (data['questions'] is List)
          ? List<Map<String, dynamic>>.from(
              (data['questions'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
            )
          : const [],
    );
  }
}

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String actionLink;
  final int color; // ARGB
  final int order;

  const BannerModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.actionLink = '',
    this.color = 0xFF4F46E5,
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'actionLink': actionLink,
        'color': color,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory BannerModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BannerModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      actionLink: data['actionLink'] ?? '',
      color: (data['color'] is int)
          ? data['color'] as int
          : int.tryParse(data['color']?.toString() ?? '') ?? 0xFF4F46E5,
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }
}

/// Maps a stored [iconName] string to a [IconData]. Kept here to avoid
/// Flutter UI imports inside pure model files being necessary elsewhere —
/// returns a [String] key used by the UI layer's icon resolver.
const List<String> kCourseIconOptions = [
  'code',
  'data_object',
  'terminal',
  'account_tree',
  'storage',
  'language',
  'functions',
  'loop',
  'category',
];

/// Popular topic shown on the home screen (Img 3). Sits in `popularTopics`.
class PopularTopicModel {
  final String id;
  final String title; // e.g. "Arrays and Strings"
  final String duration; // display string e.g. "15 mins"
  final String subject; // e.g. Java / Python / C
  final String courseId; // links to a course ('' = standalone)
  final int order;

  const PopularTopicModel({
    required this.id,
    required this.title,
    this.duration = '',
    this.subject = '',
    this.courseId = '',
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'duration': duration,
        'subject': subject,
        'courseId': courseId,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory PopularTopicModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PopularTopicModel(
      id: doc.id,
      title: data['title'] ?? '',
      duration: data['duration'] ?? '',
      subject: data['subject'] ?? '',
      courseId: data['courseId'] ?? '',
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }
}
