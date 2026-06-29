import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pet_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../models/currency_models.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('宠物商店'),
        centerTitle: true,
      ),
      body: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, state) {
          if (state.status == ShopStatus.initial) {
            context.read<ShopCubit>().loadShopItems();
          }

          if (state.status == ShopStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ShopStatus.error) {
            return Center(child: Text('出错了：${state.errorMessage}'));
          }

          return Column(
            children: [
              _buildCategoryTabs(context, state.selectedCategory),
              Expanded(
                child: state.filteredItems.isEmpty
                    ? const Center(child: Text('该分类暂无商品'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.filteredItems.length,
                        itemBuilder: (context, index) {
                          return _buildShopCard(context, state.filteredItems[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, ShopItemCategory? selected) {
    final categories = [
      (null, '全部'),
      (ShopItemCategory.food, '食物'),
      (ShopItemCategory.toy, '玩具'),
      (ShopItemCategory.medicine, '药品'),
      (ShopItemCategory.accessory, '装饰'),
    ];

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (category, label) = categories[index];
          final isSelected = selected == category;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => context.read<ShopCubit>().selectCategory(category),
            selectedColor: Colors.amber,
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, ShopItem item) {
    final pet = context.watch<PetCubit>().state.petState;
    final canAfford = pet != null &&
        pet.growthCoins >= item.growthCoinsCost &&
        pet.humanitiesPoints >= item.humanitiesPointsCost &&
        pet.sciencePoints >= item.sciencePointsCost &&
        pet.healthPoints >= item.healthPointsCost;
    final canBuyStage = pet != null && pet.stage >= item.requiredStage;

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
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(item.iconEmoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(item),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: (canAfford && canBuyStage) ? () => _buyItem(context, item) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('购买'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(ShopItem item) {
    final prices = <Widget>[];
    if (item.growthCoinsCost > 0) {
      prices.add(_buildPriceTag('${item.growthCoinsCost}', '成长币', Colors.amber));
    }
    if (item.humanitiesPointsCost > 0) {
      prices.add(_buildPriceTag('${item.humanitiesPointsCost}', '文科', Colors.purple));
    }
    if (item.sciencePointsCost > 0) {
      prices.add(_buildPriceTag('${item.sciencePointsCost}', '理科', Colors.orange));
    }
    if (item.healthPointsCost > 0) {
      prices.add(_buildPriceTag('${item.healthPointsCost}', '健康', Colors.red));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: prices,
    );
  }

  Widget _buildPriceTag(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _buyItem(BuildContext context, ShopItem item) async {
    final petCubit = context.read<PetCubit>();
    final pet = petCubit.state.petState;
    if (pet == null) return;

    final result = await context.read<ShopCubit>().purchaseItem(item, pet);

    if (!context.mounted) return;

    switch (result) {
      case ShopPurchaseResult.success:
        petCubit.loadPetState(pet.currentGrade);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功购买 ${item.name}！'), backgroundColor: Colors.green),
        );
      case ShopPurchaseResult.insufficientFunds:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('货币不足，快去赚取积分吧~'), backgroundColor: Colors.orange),
        );
      case ShopPurchaseResult.insufficientStage:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('宠物阶段不足，继续努力成长吧~'), backgroundColor: Colors.orange),
        );
      case ShopPurchaseResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('购买失败，请重试'), backgroundColor: Colors.red),
        );
    }
  }
}
