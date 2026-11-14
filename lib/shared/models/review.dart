import 'album.dart';

enum ReviewSource { user, critic }

class Review {
  final String id;
  final String albumId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final double rating;
  final String? content;
  final Track? favoriteTrack;
  final Track? leastFavoriteTrack;
  final DateTime createdAt;
  final ReviewSource source;
  final String? publicationName;

  const Review({
    required this.id,
    required this.albumId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    this.content,
    this.favoriteTrack,
    this.leastFavoriteTrack,
    required this.createdAt,
    this.source = ReviewSource.user,
    this.publicationName,
  });

  bool get isCritic => source == ReviewSource.critic;

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? '',
      albumId: map['albumId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userAvatarUrl: map['userAvatarUrl'],
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      content: map['content'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      source: map['source'] == 'critic' ? ReviewSource.critic : ReviewSource.user,
      publicationName: map['publicationName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'albumId': albumId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'content': content,
      'favoriteTrackId': favoriteTrack?.id,
      'favoriteTrackTitle': favoriteTrack?.title,
      'leastFavoriteTrackId': leastFavoriteTrack?.id,
      'leastFavoriteTrackTitle': leastFavoriteTrack?.title,
      'createdAt': createdAt.toIso8601String(),
      'source': source.name,
      'publicationName': publicationName,
    };
  }
}

class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final List<String> friendIds;
  final int reviewCount;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.friendIds = const [],
    this.reviewCount = 0,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'],
      friendIds: List<String>.from(map['friendIds'] ?? []),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'friendIds': friendIds,
      'reviewCount': reviewCount,
    };
  }
}
