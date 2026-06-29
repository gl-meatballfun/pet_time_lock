part of 'shop_cubit.dart';

enum ShopStatus { initial, loading, loaded, purchasing, error }

class ShopState extends Equatable {
  final ShopStatus status;
  final List<ShopItem> items;
  final ShopItemCategory? selectedCategory;
  final String? errorMessage;

  const ShopState({
    this.status = ShopStatus.initial,
    this.items = const [],
    this.selectedCategory,
    this.errorMessage,
  });

  ShopState copyWith({
    ShopStatus? status,
    List<ShopItem>? items,
    ShopItemCategory? selectedCategory,
    String? errorMessage,
  }) {
    return ShopState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
    );
  }

  List<ShopItem> get filteredItems {
    if (selectedCategory == null) return items;
    return items.where((item) => item.category == selectedCategory).toList();
  }

  @override
  List<Object?> get props => [status, items, selectedCategory, errorMessage];
}
