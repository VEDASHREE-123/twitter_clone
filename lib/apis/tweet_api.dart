import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:twitter_clone/constants/appwrite_constants.dart';
import 'package:twitter_clone/core/core.dart';
import 'package:twitter_clone/core/providers.dart';
import 'package:twitter_clone/models/tweet_model.dart';

final tweetAPIProvider = Provider((ref) {
  return TweetAPI(
    db: ref.watch(appwriteDatabaseProvider),
    realtime: ref.watch(appwriteRealtimeProvider),
  );
});

abstract class ITweetAPI {
  FutureEither<Document> shareTweet(Tweet tweet);
  Future<List<Document>> getTweets();
  Future<List<Document>> getUserTweets(String uid);
  Stream<RealtimeMessage> getLatestTweet();
  FutureEither<Document> likeTweet(Tweet tweet);
  FutureEither<Document> updateReShareCount(Tweet tweet);
  Future<List<Document>> getRepliesToTweet(Tweet tweet);
  Future<List<Document>> getTweetsByHashTags(String hashTag);
  Future<Document> getTweetById(String id);
}

class TweetAPI implements ITweetAPI {
  final Databases _db;
  final Realtime _realtime;

  TweetAPI({
    required Databases db,
    required Realtime realtime,
  })  : _db = db,
        _realtime = realtime;

  @override
  FutureEither<Document> shareTweet(Tweet tweet) async {
    try {
      final doc = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: ID.unique(),
        data: tweet.toMap(),
      );

      return right(doc);
    } on AppwriteException catch (e, st) {
      return left(
        Failure(
          e.message ?? 'Unexpected Error Occured!',
          st,
        ),
      );
    } catch (e, st) {
      return left(
        Failure(
          e.toString(),
          st,
        ),
      );
    }
  }

  @override
  Future<List<Document>> getTweets() async {
    final docs = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.tweetsCollection,
      queries: [
        Query.orderDesc('tweetedAt'),
      ],
    );

    return docs.documents;
  }

  @override
  Stream<RealtimeMessage> getLatestTweet() {
    return _realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.tweetsCollection}.documents',
    ]).stream;
  }

  @override
  FutureEither<Document> likeTweet(Tweet tweet) async {
    try {
      final doc = await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: tweet.id,
        data: {
          'likes': tweet.likes,
        },
      );

      return right(doc);
    } on AppwriteException catch (e, st) {
      return left(
        Failure(
          e.message ?? 'Unexpected Error Occured!',
          st,
        ),
      );
    } catch (e, st) {
      return left(
        Failure(
          e.toString(),
          st,
        ),
      );
    }
  }

  @override
  FutureEither<Document> updateReShareCount(Tweet tweet) async {
    try {
      final doc = await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: tweet.id,
        data: {
          'reShareCount': tweet.reShareCount,
        },
      );

      return right(doc);
    } on AppwriteException catch (e, st) {
      return left(
        Failure(
          e.message ?? 'Unexpected Error Occured!',
          st,
        ),
      );
    } catch (e, st) {
      return left(
        Failure(
          e.toString(),
          st,
        ),
      );
    }
  }

  @override
  Future<List<Document>> getRepliesToTweet(Tweet tweet) async {
    final documents = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.tweetsCollection,
      queries: [
        Query.equal('repliedTo', tweet.id),
      ],
    );

    return documents.documents;
  }

  @override
  Future<Document> getTweetById(String id) async {
    return _db.getDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.tweetsCollection,
      documentId: id,
    );
  }

  @override
  Future<List<Document>> getUserTweets(String uid) async {
    final docs = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.tweetsCollection,
      queries: [
        Query.equal('uid', uid),
        Query.orderDesc('tweetedAt'),
      ],
    );

    return docs.documents;
  }

  @override
  Future<List<Document>> getTweetsByHashTags(String hashTag) async {
    final docs = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.tweetsCollection,
      queries: [
        Query.search('hashTags', hashTag),
        Query.orderDesc('tweetedAt'),
      ],
    );

    return docs.documents;
  }
}
