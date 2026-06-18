import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/shop_data.dart';
import '../../models/shop_item.dart';
import '../../services/game_state.dart';
import '../../theme/app_theme.dart';
import 'sheet.dart';

class ShopPanel extends StatefulWidget {
  const ShopPanel({super.key});

  @override
  State<ShopPanel> createState() => _ShopPanelState();
}

class _ShopPanelState extends State<ShopPanel> {
  ShopCategory _cat = ShopCategory.outfit;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final items = kShopItems.where((i) => i.category == _cat).toList();

    return Sheet(
      title: 'Reward Shop',
      icon: '🛍️',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text('${game.coins} coins',
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ShopCategory.values
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${c.icon} ${c.label}'),
                          selected: _cat == c,
                          onSelected: (_) => setState(() => _cat = c),
                          selectedColor: AppColors.gold,
                          backgroundColor: AppColors.navy2,
                          labelStyle: TextStyle(
                            color: _cat == c ? AppColors.navy : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.82,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _ShopCard(item: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.item});
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final owned = game.isOwned(item);
    final equipped = game.profile.equipped[item.category.name] == item.id;
    final afford = game.canAfford(item);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.navy2.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: equipped ? AppColors.teal : Colors.white12, width: equipped ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text(item.icon, style: const TextStyle(fontSize: 40))),
          const SizedBox(height: 6),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text(item.description,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (owned && !item.consumable)
                  ? () => game.equipItem(item)
                  : (afford ? () => _buy(context, game) : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: (owned && !item.consumable)
                    ? (equipped ? AppColors.teal : AppColors.navy)
                    : (afford ? AppColors.gold : Colors.white12),
                foregroundColor: (owned && !item.consumable) ? Colors.white : AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                (owned && !item.consumable)
                    ? (equipped ? 'Equipped' : 'Equip')
                    : '${item.price} 🪙',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _buy(BuildContext context, GameState game) {
    final ok = game.buyItem(item);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins!'), duration: Duration(seconds: 1)),
      );
    }
  }
}
