import 'package:flutter/material.dart';

class CardSelector extends StatefulWidget {
  final ValueChanged<int> onSelected;
  const CardSelector({super.key, required this.onSelected});

  @override
  State<CardSelector> createState() => _CardSelectorState();
}

class _CardSelectorState extends State<CardSelector> {
  int selected = 0;
  final cards = [
    'assets/card1.png',
    'assets/card2.png',
    'assets/card3.png',
    'assets/card4.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(cards.length, (i) {
        return GestureDetector(
          onTap: () {
            setState(() => selected = i);
            widget.onSelected(i);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected == i ? Colors.green : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(cards[i], height: 70, width: 70),
          ),
        );
      }),
    );
  }
}
