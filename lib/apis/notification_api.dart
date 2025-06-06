import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:twitter_clone/constants/constants.dart';
import 'package:twitter_clone/core/core.dart';
import 'package:twitter_clone/core/providers.dart';
import 'package:twitter_clone/models/notification_model.dart';

final notificationAPIProvider = Provider((ref) {
  return NotificationAPI(
    db: ref.watch(appwriteDatabaseProvider),
    realtime: ref.watch(appwriteRealtimeProvider),
  );
});

abstract class INotificationAPI {
  FutureEitherVoid createNotification(Notification notification);
  Future<List<Document>> getNotifications(String uid);
  Stream<RealtimeMessage> getLatestNotifications();
}

class NotificationAPI implements INotificationAPI {
  final Databases _db;
  final Realtime _realtime;

  NotificationAPI({required Databases db, required Realtime realtime})
      : _realtime = realtime,
        _db = db;

  @override
  Future<List<Document>> getNotifications(String uid) async {
    final docs = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.notificationsCollection,
      queries: [
        Query.equal('uid', uid),
      ],
    );

    return docs.documents;
  }

  @override
  Stream<RealtimeMessage> getLatestNotifications() {
    return _realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.notificationsCollection}.documents',
    ]).stream;
  }

  @override
  FutureEitherVoid createNotification(Notification notification) async {
    try {
      await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: ID.unique(),
        data: notification.toMap(),
      );

      return right(null);
    } on AppwriteException catch (e, st) {
      return left(
        Failure(e.message ?? 'Unexpected Error Occured!', st),
      );
    } catch (e, st) {
      return left(
        Failure(e.toString(), st),
      );
    }
  }
}
