import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_time_lock/bloc/shop_cubit.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/models/currency_models.dart';

import '../fake_database_helper.dart';
import '../test_helper.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('ShopCubit', () {
    late FakeDatabaseHelper fakeDb;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
    });

    final testItems = [
      const ShopItem(
        id: 'food_biscuit',
        name: '小饼干',
        description: '',
        iconEmoji: '🍪',
        category: ShopItemCategory.food,
        sciencePointsCost: 10,
        effectHunger: 15,
      ),
      const ShopItem(
        id: 'acc_bow',
        name: '蝴蝶结',
        description: '',
        iconEmoji: '🎀',
        category: ShopItemCategory.accessory,
        growthCoinsCost: 50,
        isConsumable: false,
        appearanceUnlock: '🎀',
        requiredStage: 1,
      ),
      const ShopItem(
        id: 'acc_crown',
        name: '皇冠',
        description: '',
        iconEmoji: '👑',
        category: ShopItemCategory.accessory,
        growthCoinsCost: 200,
        isConsumable: false,
        appearanceUnlock: '👑',
        requiredStage: 4,
      ),
    ];

    blocTest<ShopCubit, ShopState>(
      'loadShopItems 加载并分类商品',
      build: () {
        fakeDb.seedShopItems(testItems);
        return ShopCubit(fakeDb);
      },
      act: (cubit) => cubit.loadShopItems(),
      expect: () => [
        isA<ShopState>().having((s) => s.status, 'status', ShopStatus.loading),
        isA<ShopState>()
            .having((s) => s.status, 'status', ShopStatus.loaded)
            .having((s) => s.items.length, 'itemCount', testItems.length),
      ],
    );

    blocTest<ShopCubit, ShopState>(
      'selectCategory 过滤商品',
      build: () => ShopCubit(fakeDb),
      seed: () => ShopState(status: ShopStatus.loaded, items: testItems),
      act: (cubit) => cubit.selectCategory(ShopItemCategory.food),
      expect: () => [
        isA<ShopState>().having((s) => s.filteredItems.length, 'foodCount', 1),
      ],
    );

    test('purchaseItem 余额充足时购买成功并入库', () async {
      fakeDb.seedShopItems(testItems);
      fakeDb.seedPetState(PetState(currentGrade: 5, stage: 2, growthCoins: 100, sciencePoints: 50));

      final cubit = ShopCubit(fakeDb);
      await cubit.loadShopItems();
      final pet = (await fakeDb.getPetState())!;
      final result = await cubit.purchaseItem(testItems[0], pet);

      expect(result, ShopPurchaseResult.success);
      final inventory = await fakeDb.getAllInventory();
      expect(inventory.length, 1);
      expect(inventory.first.itemId, 'food_biscuit');
      expect((await fakeDb.getPetState())!.sciencePoints, 40); // 50 - 10
      expect((await fakeDb.getPetState())!.growthCoins, 100); // 不变
    });

    test('purchaseItem 阶段不足时返回 insufficientStage', () async {
      fakeDb.seedShopItems(testItems);
      fakeDb.seedPetState(PetState(currentGrade: 5, stage: 1, growthCoins: 300));

      final cubit = ShopCubit(fakeDb);
      await cubit.loadShopItems();
      final pet = (await fakeDb.getPetState())!;
      final result = await cubit.purchaseItem(testItems[2], pet);

      expect(result, ShopPurchaseResult.insufficientStage);
      expect((await fakeDb.getAllInventory()).length, 0);
    });

    test('purchaseItem 余额不足时返回 insufficientFunds', () async {
      fakeDb.seedShopItems(testItems);
      fakeDb.seedPetState(PetState(currentGrade: 5, stage: 1, growthCoins: 10));

      final cubit = ShopCubit(fakeDb);
      await cubit.loadShopItems();
      final pet = (await fakeDb.getPetState())!;
      final result = await cubit.purchaseItem(testItems[1], pet);

      expect(result, ShopPurchaseResult.insufficientFunds);
      expect((await fakeDb.getAllInventory()).length, 0);
    });
  });
}
