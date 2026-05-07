import 'package:hive/hive.dart';

part 'sale_model.g.dart';

@HiveType(typeId: 0)
class Sale extends HiveObject {
  @HiveField(0)
  final String menuName;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final int pricePerItem;

  @HiveField(3)
  final DateTime dateTime;

  Sale({
    required this.menuName,
    required this.quantity,
    required this.pricePerItem,
    required this.dateTime,
  });

  // Helper untuk hitung total harga otomatis
  int get totalPrice => quantity * pricePerItem;
}