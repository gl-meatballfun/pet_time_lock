import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database_helper.dart';
import '../models/app_models.dart';
import '../models/currency_models.dart';
import '../services/reward_service.dart';

part 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  final DatabaseHelper _db;

  ShopCubit(this._db) : super(const ShopState());

  Future<void> loadShopItems() async {
    emit(state.copyWith(status: ShopStatus.loading));
    try {
      final items = await _db.getAllShopItems();
      emit(state.copyWith(status: ShopStatus.loaded, items: items));
    } catch (e) {
      emit(state.copyWith(status: ShopStatus.error, errorMessage: e.toString()));
    }
  }

  void selectCategory(ShopItemCategory? category) {
    emit(state.copyWith(selectedCategory: category));
  }

  /// 购买商品。返回结果与提示信息。
  Future<ShopPurchaseResult> purchaseItem(ShopItem item, PetState pet) async {
    if (pet.stage < item.requiredStage) {
      return ShopPurchaseResult.insufficientStage;
    }

    emit(state.copyWith(status: ShopStatus.purchasing));

    final success = await RewardService().deductCurrencyForPurchase(
      db: _db,
      pet: pet,
      item: item,
    );

    if (!success) {
      emit(state.copyWith(status: ShopStatus.loaded));
      return ShopPurchaseResult.insufficientFunds;
    }

    try {
      final existing = await _db.getInventoryItem(item.id);
      if (existing != null) {
        await _db.updateInventoryItem(
          existing.copyWith(quantity: existing.quantity + 1),
        );
      } else {
        await _db.addOrUpdateInventoryItem(
          InventoryItem(
            itemId: item.id,
            acquiredAt: DateTime.now(),
          ),
        );
      }

      emit(state.copyWith(status: ShopStatus.loaded));
      return ShopPurchaseResult.success;
    } catch (e) {
      emit(state.copyWith(status: ShopStatus.error, errorMessage: e.toString()));
      return ShopPurchaseResult.failed;
    }
  }
}

enum ShopPurchaseResult {
  success,
  insufficientFunds,
  insufficientStage,
  failed,
}
