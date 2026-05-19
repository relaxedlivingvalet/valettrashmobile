/// Extra comeback pickup packs (paid). Free monthly comeback does not roll over.
class ComebackPack {
  const ComebackPack({
    required this.quantity,
    required this.priceDollars,
    required this.label,
  });

  final int quantity;
  final int priceDollars;
  final String label;
}

const kComebackPacks = [
  ComebackPack(quantity: 1, priceDollars: 5, label: '1 comeback'),
  ComebackPack(quantity: 3, priceDollars: 14, label: '3 comebacks'),
  ComebackPack(quantity: 5, priceDollars: 20, label: '5 comebacks'),
];

/// One free comeback per calendar month (does not roll over).
const kMonthlyFreeComebacks = 1;

const kDefaultServiceWindowStart = '18:00:00';
const kDefaultServiceWindowEnd = '22:00:00';
