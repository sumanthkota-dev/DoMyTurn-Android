class ShoppingItem {
  final int? id;
  final String listName;
  final List<String> items;
  final List<String>? boughtItems;
  final List<String>? unBoughtItems; // ✅ NEW: From backend
  final bool bought;
  final int homeId;

  ShoppingItem({
    this.id,
    required this.listName,
    required this.items,
    this.boughtItems,
    this.unBoughtItems, // ✅ NEW
    this.bought = false,
    required this.homeId,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      listName: json['listName'] ?? '',
      items: List<String>.from(json['items'] ?? []),
      boughtItems: json['boughtItems'] != null
          ? List<String>.from(json['boughtItems'])
          : null,
      unBoughtItems: json['unBoughtItems'] != null // ✅ NEW
          ? List<String>.from(json['unBoughtItems'])
          : null,
      bought: json['bought'] ?? false,
      homeId: json['homeId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'listName': listName,
    'items': items,
    if (boughtItems != null) 'boughtItems': boughtItems,
    if (unBoughtItems != null) 'unBoughtItems': unBoughtItems, // ✅ NEW
    'bought': bought,
    'homeId': homeId,
  };
}
