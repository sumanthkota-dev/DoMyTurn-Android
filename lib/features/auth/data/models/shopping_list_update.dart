class ShoppingListUpdate {
  final int id;
  final List<String> boughtItems;
  final List<String> unBoughtItems;
  final int homeId;

  ShoppingListUpdate({
    required this.id,
    required this.boughtItems,
    required this.unBoughtItems,
    required this.homeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boughtItems': boughtItems,
      'unBoughtItems': unBoughtItems,
      'homeId': homeId,
    };
  }
}
