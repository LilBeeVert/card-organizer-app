class PlayingCard {
  int? id;
  String cardName;
  String suit;
  String? imageUrl;
  int folderId;

  PlayingCard({
    this.id,
    required this.cardName,
    required this.suit,
    this.imageUrl,
    required this.folderId,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'card_name': cardName,
      'suit': suit,
      'image_url': imageUrl,
      'folder_id': folderId,
    };
  }

  // Construct from a database map
  factory PlayingCard.fromMap(Map<String, dynamic> map) {
    return PlayingCard(
      id: map['id'] as int?,
      cardName: map['card_name'] as String,
      suit: map['suit'] as String,
      imageUrl: map['image_url'] as String?,
      folderId: map['folder_id'] as int,
    );
  }
}
