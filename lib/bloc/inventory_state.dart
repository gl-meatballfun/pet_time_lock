part of 'inventory_cubit.dart';

enum InventoryStatus { initial, loading, loaded, using, error }

class InventoryState extends Equatable {
  final InventoryStatus status;
  final List<InventoryItem> items;
  final Map<String, ShopItem> itemDetails;
  final String? errorMessage;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.items = const [],
    this.itemDetails = const {},
    this.errorMessage,
  });

  InventoryState copyWith({
    InventoryStatus? status,
    List<InventoryItem>? items,
    Map<String, ShopItem>? itemDetails,
    String? errorMessage,
  }) {
    return InventoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      itemDetails: itemDetails ?? this.itemDetails,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, itemDetails, errorMessage];
}
