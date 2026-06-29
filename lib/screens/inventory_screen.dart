import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/inventory_cubit.dart';
import '../bloc/pet_cubit.dart';
import '../models/currency_models.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的背包'),
        centerTitle: true,
      ),
      body: BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
          if (state.status == InventoryStatus.initial) {
            context.read<InventoryCubit>().loadInventory();
          }

          if (state.status == InventoryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == InventoryStatus.error) {
            return Center(child: Text('出错了：${state.errorMessage}'));
          }

          if (state.items.isEmpty) {
            return const Center(child: Text('背包里还没有物品，去商店逛逛吧~'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              final shopItem = state.itemDetails[item.itemId];
              if (shopItem == null) return const SizedBox.shrink();
              return _buildInventoryCard(context, item, shopItem);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryCard(
    BuildContext context,
    InventoryItem item,
    ShopItem shopItem,
  ) {
    final isConsumable = shopItem.isConsumable;
    final isEquipped = item.isEquipped;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _categoryColor(shopItem.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(shopItem.iconEmoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shopItem.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isConsumable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shopItem.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (isConsumable) _buildEffectText(shopItem),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isConsumable)
              ElevatedButton(
                onPressed: () => _useItem(context, item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _categoryColor(shopItem.category),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('使用'),
              )
            else
              ElevatedButton(
                onPressed: () => _toggleEquip(context, item, isEquipped),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEquipped ? Colors.grey : Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isEquipped ? '卸下' : '装备'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectText(ShopItem item) {
    final effects = <String>[];
    if (item.effectHealth != 0) effects.add('健康 ${item.effectHealth > 0 ? '+' : ''}${item.effectHealth}');
    if (item.effectHappiness != 0) effects.add('快乐 ${item.effectHappiness > 0 ? '+' : ''}${item.effectHappiness}');
    if (item.effectHunger != 0) effects.add('饥饿 ${item.effectHunger > 0 ? '+' : ''}${item.effectHunger}');
    if (item.effectKnowledge != 0) effects.add('知识 ${item.effectKnowledge > 0 ? '+' : ''}${item.effectKnowledge}');

    return Text(
      effects.isEmpty ? '无效果' : effects.join('  '),
      style: TextStyle(
        fontSize: 12,
        color: Colors.green[700],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Color _categoryColor(ShopItemCategory category) {
    return switch (category) {
      ShopItemCategory.food => Colors.orange,
      ShopItemCategory.toy => Colors.pink,
      ShopItemCategory.medicine => Colors.red,
      ShopItemCategory.accessory => Colors.purple,
    };
  }

  Future<void> _useItem(BuildContext context, InventoryItem item) async {
    final inventoryCubit = context.read<InventoryCubit>();
    final effects = await inventoryCubit.useItem(item);

    if (!context.mounted) return;

    if (effects != null) {
      final petCubit = context.read<PetCubit>();
      final pet = petCubit.state.petState;
      if (pet != null) {
        await petCubit.interactWithPet(
          happinessDelta: effects['happiness'] ?? 0,
          hungerDelta: effects['hunger'] ?? 0,
          knowledgeDelta: effects['knowledge'] ?? 0,
          healthDelta: effects['health'] ?? 0,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('使用成功！'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _toggleEquip(
    BuildContext context,
    InventoryItem item,
    bool isEquipped,
  ) async {
    final cubit = context.read<InventoryCubit>();
    if (isEquipped) {
      await cubit.unequipAccessory(item);
    } else {
      await cubit.equipAccessory(item);
    }

    if (!context.mounted) return;

    // 刷新宠物外观
    final pet = context.read<PetCubit>().state.petState;
    if (pet != null) {
      context.read<PetCubit>().loadPetState(pet.currentGrade);
    }
  }
}
