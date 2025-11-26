class TraktList {
  final String name;
  final String? description;
  final String privacy;
  final String shareLink;
  final String type;
  final bool displayNumbers;
  final bool allowComments;
  final String sortBy;
  final String sortHow;
  final String createdAt;
  final String updatedAt;
  final int itemCount;
  final int commentCount;
  final int likes;
  final TraktListIds ids;
  final TraktListUser user;

  TraktList({
    required this.name,
    this.description,
    required this.privacy,
    required this.shareLink,
    required this.type,
    required this.displayNumbers,
    required this.allowComments,
    required this.sortBy,
    required this.sortHow,
    required this.createdAt,
    required this.updatedAt,
    required this.itemCount,
    required this.commentCount,
    required this.likes,
    required this.ids,
    required this.user,
  });

  factory TraktList.fromJson(Map<String, dynamic> json) {
    return TraktList(
      name: json['name'] as String,
      description: json['description'] as String?,
      privacy: json['privacy'] as String,
      shareLink: json['share_link'] as String,
      type: json['type'] as String,
      displayNumbers: json['display_numbers'] as bool,
      allowComments: json['allow_comments'] as bool,
      sortBy: json['sort_by'] as String,
      sortHow: json['sort_how'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      itemCount: json['item_count'] as int,
      commentCount: json['comment_count'] as int,
      likes: json['likes'] as int,
      ids: TraktListIds.fromJson(json['ids'] as Map<String, dynamic>),
      user: TraktListUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class TraktListIds {
  final int trakt;
  final String slug;

  TraktListIds({
    required this.trakt,
    required this.slug,
  });

  factory TraktListIds.fromJson(Map<String, dynamic> json) {
    return TraktListIds(
      trakt: json['trakt'] as int,
      slug: json['slug'] as String,
    );
  }
}

class TraktListUser {
  final String username;
  final bool private;
  final String? name;
  final bool vip;
  final bool vipEp;
  final TraktListUserIds ids;

  TraktListUser({
    required this.username,
    required this.private,
    this.name,
    required this.vip,
    required this.vipEp,
    required this.ids,
  });

  factory TraktListUser.fromJson(Map<String, dynamic> json) {
    return TraktListUser(
      username: json['username'] as String,
      private: json['private'] as bool,
      name: json['name'] as String?,
      vip: json['vip'] as bool,
      vipEp: json['vip_ep'] as bool,
      ids: TraktListUserIds.fromJson(json['ids'] as Map<String, dynamic>),
    );
  }
}

class TraktListUserIds {
  final String slug;

  TraktListUserIds({
    required this.slug,
  });

  factory TraktListUserIds.fromJson(Map<String, dynamic> json) {
    return TraktListUserIds(
      slug: json['slug'] as String,
    );
  }
}

class TraktTrendingList {
  final int likeCount;
  final int commentCount;
  final TraktList list;

  TraktTrendingList({
    required this.likeCount,
    required this.commentCount,
    required this.list,
  });

  factory TraktTrendingList.fromJson(Map<String, dynamic> json) {
    return TraktTrendingList(
      likeCount: json['like_count'] as int,
      commentCount: json['comment_count'] as int,
      list: TraktList.fromJson(json['list'] as Map<String, dynamic>),
    );
  }
}
