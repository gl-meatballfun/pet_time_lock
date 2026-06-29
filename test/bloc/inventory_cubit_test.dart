import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_time_lock/bloc/inventory_cubit.dart';
import 'package:pet_time_lock/models/currency_models.dart';

import '../fake_database_helper.dart';
import '../test_helper.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('InventoryCubit', () {
    late FakeDatabaseHelper fakeDb;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
    });

    const biscuit = ShopItem(
      id: 'food_biscuit',
      name: '小饼干',
      description: '',
      iconEmoji: '🍪',
      category: ShopItemCategory.food,
      sciencePointsCost: 10,
      effectHunger: 15,
      effectHappiness: 5,
    );

    const bow = ShopItem(
      id: 'acc_bow',
      name: '蝴蝶结',
      description: '',
      iconEmoji: '🎀',
      category: ShopItemCategory.accessory,
      growthCoinsCost: 50,
      isConsumable: false,
      appearanceUnlock: '🎀',
    );

    const hat = ShopItem(
      id: 'acc_hat',
      name: '学霸帽',
      description: '',
      iconEmoji: '🎓',
      category: ShopItemCategory.accessory,
      growthCoinsCost: 30,
      humanitiesPointsCost: 30,
      sciencePointsCost: 30,
      isConsumable: false,
      appearanceUnlock: '🎓',
    );

    blocTest<InventoryCubit, InventoryState>(
      'loadInventory 加载背包与商品详情',
      build: () {
        fakeDb.seedShopItems([biscuit, bow]);
        fakeDb.seedInventory([
          InventoryItem(itemId: 'food_biscuit', quantity: 3, acquiredAt: DateTime.now()),
          InventoryItem(itemId: 'acc_bow', acquiredAt: DateTime.now()),
        ]);
        return InventoryCubit(fakeDb);
      },
      act: (cubit) => cubit.loadInventory(),
      expect: () => [
        isA<InventoryState>().having((s) => s.status, 'status', InventoryStatus.loading),
        isA<InventoryState>()
            .having((s) => s.status, 'status', InventoryStatus.loaded)
            .having((s) => s.items.length, 'itemCount', 2)
            .having((s) => s.itemDetails.length, 'detailCount', 2),
      ],
    );

    test('useItem 消耗品数量减少并返回效果', () async {
      fakeDb.seedShopItems([biscuit]);
      fakeDb.seedInventory([
        InventoryItem(itemId: 'food_biscuit', quantity: 3, acquiredAt: DateTime.now()),
      ]);

      final cubit = InventoryCubit(fakeDb);
      await cubit.loadInventory();
      final effects = await cubit.useItem(cubit.state.items.first);

      expect(effects, isNotNull);
      expect(effects!['hunger'], 15);
      expect(effects['happiness'], 5);
      expect((await fakeDb.getAllInventory()).first.quantity, 2);
    });

    test('useItem 数量归 0 时从背包删除', () async {
      fakeDb.seedShopItems([biscuit]);
      fakeDb.seedInventory([
        InventoryItem(itemId: 'food_biscuit', quantity: 1, acquiredAt: DateTime.now()),
      ]);

      final cubit = InventoryCubit(fakeDb);
      await cubit.loadInventory();
      await cubit.useItem(cubit.state.items.first);

      expect((await fakeDb.getAllInventory()).length, 0);
    });

    test('equipAccessory 装备时先卸下其他装饰', () async {
      fakeDb.seedShopItems([bow, hat]);
      fakeDb.seedInventory([
        InventoryItem(itemId: 'acc_bow', isEquipped: true, acquiredAt: DateTime.now()),
        InventoryItem(itemId: 'acc_hat', acquiredAt: DateTime.now()),
      ]);

      final cubit = InventoryCubit(fakeDb);
      await cubit.loadInventory();
      await cubit.equipAccessory(cubit.state.items.last);

      final items = await fakeDb.getAllInventory();
      expect(items.firstWhere((i) => i.itemId == 'acc_bow').isEquipped, false);
      expect(items.firstWhere((i) => i.itemId == 'acc_hat').isEquipped, true);
    });
  });
}
