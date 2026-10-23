import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/id_card_model.dart';
import '../utils/image_processor.dart';
import '../widgets/a4_canvas.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<IdCardItem> _items = [];
  IdCardItem? _selectedItem;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndCropImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // 裁剪
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 85.6, ratioY: 54.0),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '裁剪身份证', toolbarColor: Colors.blue),
      ],
    );

    if (croppedFile != null) {
      Uint8List bytes = await croppedFile.readAsBytes();
      // 初始处理
      Uint8List processedBytes = await ImageProcessor.processImage(bytes, 0, 1.0, 0);
      
      setState(() {
        _items.add(IdCardItem(originalBytes: bytes, processedBytes: processedBytes));
      });
    }
  }

  void _updatePosition(IdCardItem item, double dxMm, double dyMm) {
    setState(() {
      item.x += dxMm;
      item.y += dyMm;
    });
  }

  void _updateScale(IdCardItem item, double newWidthMm, double newHeightMm) {
    setState(() {
      item.width = newWidthMm.clamp(20.0, 180.0);
      item.height = newHeightMm.clamp(10.0, 120.0);
    });
  }

  Future<void> _applyFilters() async {
    if (_selectedItem == null) return;
    
    // 简单的滤镜调节弹窗
    double tempBrightness = _selectedItem!.brightness;
    double tempContrast = _selectedItem!.contrast;
    double tempSharpness = _selectedItem!.sharpness;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('图像调整'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSlider('亮度', tempBrightness, -100, 100, (v) => setDialogState(() => tempBrightness = v)),
                _buildSlider('对比度', tempContrast, 0.5, 2.0, (v) => setDialogState(() => tempContrast = v)),
                _buildSlider('锐化', tempSharpness, 0.0, 2.0, (v) => setDialogState(() => tempSharpness = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // 后台处理
                Uint8List processed = await ImageProcessor.processImage(
                  _selectedItem!.originalBytes, tempBrightness, tempContrast, tempSharpness
                );
                setState(() {
                  _selectedItem!.brightness = tempBrightness;
                  _selectedItem!.contrast = tempContrast;
                  _selectedItem!.sharpness = tempSharpness;
                  _selectedItem!.processedBytes = processed;
                });
              },
              child: const Text('应用'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text('$label: ${value.toStringAsFixed(2)}'),
        Slider(min: min, max: max, value: value, onChanged: onChanged),
      ],
    );
  }

  // 导出 PDF
  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // 210 x 297 mm
        build: (pw.Context context) {
          return pw.Stack(
            children: _items.map((item) {
              return pw.Positioned(
                left: item.x * PdfPageFormat.mm,
                top: item.y * PdfPageFormat.mm,
                width: item.width * PdfPageFormat.mm,
                height: item.height * PdfPageFormat.mm,
                child: pw.Image(
                  pw.MemoryImage(item.processedBytes),
                  fit: pw.BoxFit.fill,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('身份证合并PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _items.isEmpty ? null : () async {
              final pdf = await _generatePdf();
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdf.save(),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: A4Canvas(
            items: _items,
            selectedItem: _selectedItem,
            onPanUpdate: _updatePosition,
            onScaleUpdate: _updateScale,
            onTap: (item) => setState(() => _selectedItem = item),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.add_photo_alternate), onPressed: _pickAndCropImage, tooltip: '添加图片'),
            IconButton(
              icon: const Icon(Icons.tune), 
              onPressed: _selectedItem == null ? null : _applyFilters, 
              tooltip: '调整图像'
            ),
            if (_selectedItem != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() {
                  _items.remove(_selectedItem);
                  _selectedItem = null;
                }),
              ),
          ],
        ),
      ),
    );
  }
}
