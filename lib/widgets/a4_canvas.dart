import 'package:flutter/material.dart';
import '../models/id_card_model.dart';

class A4Canvas extends StatelessWidget {
  final List<IdCardItem> items;
  final double canvasWidthMm = 210.0; // A4宽度
  final double canvasHeightMm = 297.0; // A4高度
  final Function(IdCardItem, double, double)? onPanUpdate;
  final Function(IdCardItem, double, double)? onScaleUpdate;
  final Function(IdCardItem)? onTap;
  final IdCardItem? selectedItem;

  const A4Canvas({
    Key? key,
    required this.items,
    this.onPanUpdate,
    this.onScaleUpdate,
    this.onTap,
    this.selectedItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算缩放比例：屏幕可用宽度减去边距，映射到210mm
        final screenWidth = constraints.maxWidth - 40; 
        final scale = screenWidth / canvasWidthMm;
        final canvasPixelHeight = canvasHeightMm * scale;

        return Center(
          child: Container(
            width: screenWidth,
            height: canvasPixelHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Stack(
              children: items.map((item) {
                bool isSelected = selectedItem?.id == item.id;
                return Positioned(
                  left: item.x * scale,
                  top: item.y * scale,
                  child: GestureDetector(
                    onTap: () => onTap?.call(item),
                    onPanUpdate: (details) {
                      onPanUpdate?.call(
                        item,
                        details.delta.dx / scale,
                        details.delta.dy / scale,
                      );
                    },
                    onScaleUpdate: (details) {
                      onScaleUpdate?.call(
                        item,
                        item.width * details.scale,
                        item.height * details.scale,
                      );
                    },
                    child: Container(
                      width: item.width * scale,
                      height: item.height * scale,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Image.memory(
                            item.processedBytes,
                            fit: BoxFit.cover,
                            width: item.width * scale,
                            height: item.height * scale,
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(2),
                                child: Text(
                                  '${item.width.toStringAsFixed(1)} x ${item.height.toStringAsFixed(1)} mm',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
