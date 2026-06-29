import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database_helper.dart';
import '../models/currency_models.dart';

part 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final DatabaseHelper _db;

  InventoryCubit(this._db) : super(const InventoryState());

  Future<void> loadInventory() async {
    emit(state.copyWith(status: InventoryStatus.loading));
    try {
      final items = await _db.getAllInventory();
      final details = <String, ShopItem>{};
      for (final item in items) {
        final shopItem = await _db.getShopItem(item.itemId);
        if (shopItem != null) details[item.itemId] = shopItem;
      }
      emit(state.copyWith(
        status: InventoryStatus.loaded,
        items: items,
        itemDetails: details,
      ));
    } catch (e) {
      emit(state.copyWith(status: InventoryStatus.error, errorMessage: e.toString()));
    }
  }

  /// 使用消耗品，返回属性变化量；非消耗品返回 null。
  Future<Map<String, int>?> useItem(InventoryItem item) async {
    final shopItem = state.itemDetails[item.itemId];
    if (shopItem == null) return null;
    if (!shopItem.isConsumable) return null;

    emit(state.copyWith(status: InventoryStatus.using));

    if (item.quantity <= 1) {
      await _db.deleteInventoryItem(item.itemId);
    } else {
      await _db.updateInventoryItem(item.copyWith(quantity: item.quantity - 1));
    }

    await loadInventory();

    return {
      'health': shopItem.effectHealth,
      'happiness': shopItem.effectHappiness,
      'hunger': shopItem.effectHunger,
      'knowledge': shopItem.effectKnowledge,
    };
  }

  Future<void> equipAccessory(InventoryItem item) async {
    final shopItem = state.itemDetails[item.itemId];
    if (shopItem == null || shopItem.isConsumable) return;

    // 一次只能装备一个装饰：先卸下其他
    for (final inv in state.items) {
      if (inv.isEquipped && inv.itemId != item.itemId) {
        await _db.updateInventoryItem(inv.copyWith(isEquipped: false));
      }
    }

    await _db.updateInventoryItem(item.copyWith(isEquipped: true));
    await loadInventory();
  }

  Future<void> unequipAccessory(InventoryItem item) async {
    await _db.updateInventoryItem(item.copyWith(isEquipped: false));
    await loadInventory();
  }
}
