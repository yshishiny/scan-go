import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../state/loan_session_state.dart';

class DocumentScanScreen extends StatefulWidget {
  final String documentId;

  const DocumentScanScreen({Key? key, required this.documentId}) : super(key: key);

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureImage(BuildContext context, ImageSource source, {int? targetIndex}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90, // Capture with high initial quality before resizing/compressing
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final state = Provider.of<LoanSessionState>(context, listen: false);

        if (widget.documentId == 'NationalID' && targetIndex != null) {
          // Special logic for ID card: replace specific index (Front/Back)
          final doc = state.documents.firstWhere((d) => d.id == widget.documentId);
          if (targetIndex < doc.scannedPageBytes.length) {
            state.removePageFromDocument(widget.documentId, targetIndex);
            // Insert at the position
            // To keep things simple, we can rebuild the list:
            // Remove it and then we need to insert it.
            // Let's implement insert or just let state handle replacement.
            // Since we want to make it easy, let's write a replace method or use insert logic.
          }
          state.addPageToDocument(widget.documentId, image.path, bytes);
        } else {
          // Standard appending
          state.addPageToDocument(widget.documentId, image.path, bytes);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: ${e.toString()}')),
      );
    }
  }

  void _showSourcePicker(BuildContext context, {int? targetIndex}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text('Take Photo (Camera)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureImage(context, ImageSource.camera, targetIndex: targetIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureImage(context, ImageSource.gallery, targetIndex: targetIndex);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanSessionState>(
      builder: (context, state, child) {
        final doc = state.documents.firstWhere((d) => d.id == widget.documentId);
        final isIdCard = widget.documentId == 'NationalID';

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F11),
          appBar: AppBar(
            backgroundColor: const Color(0xFF16161A),
            elevation: 0,
            title: Text(doc.displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (doc.status == 'Compiling')
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                    ),
                  ),
                )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instruction banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIdCard ? Icons.contact_mail : Icons.description,
                        color: Colors.blueAccent,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIdCard ? 'National ID Requirements' : 'Document Guidelines',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isIdCard
                                  ? 'Enforces exactly 2 sides: Front Face and Back Face. Both will compile into one PDF.'
                                  : 'Capture all pages of the document in sequence. Make sure text is flat and well lit.',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Capture Area
                Expanded(
                  child: isIdCard 
                      ? _buildIdCardGrid(context, doc, state)
                      : _buildMultiPageGrid(context, doc, state),
                ),

                const SizedBox(height: 16),

                // Compilation State and Action Button
                if (doc.uploadError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      doc.uploadError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ElevatedButton(
                  onPressed: doc.isValid && doc.status != 'Compiling'
                      ? () async {
                          await state.compileDocument(widget.documentId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${doc.displayName} compiled successfully to PDF!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white30,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: doc.status == 'Compiling'
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Text('Compressing & Compiling...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Text(
                          doc.status == 'Compiled' ? 'Re-compile PDF' : 'Compile to PDF',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Enforces ID Card Front & Back constraints
  Widget _buildIdCardGrid(BuildContext context, LoanDocument doc, LoanSessionState state) {
    final hasFront = doc.scannedPageBytes.isNotEmpty;
    final hasBack = doc.scannedPageBytes.length > 1;

    return Row(
      children: [
        // Front Face Card
        Expanded(
          child: _buildIdSlot(
            context: context,
            title: 'Front Face',
            hasImage: hasFront,
            imageBytes: hasFront ? doc.scannedPageBytes[0] : null,
            onTap: () {
              if (hasFront) {
                state.removePageFromDocument(widget.documentId, 0);
              } else {
                _showSourcePicker(context);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        // Back Face Card
        Expanded(
          child: _buildIdSlot(
            context: context,
            title: 'Back Face',
            hasImage: hasBack,
            imageBytes: hasBack ? doc.scannedPageBytes[1] : null,
            onTap: () {
              if (!hasFront) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please scan the Front Face first.')),
                );
                return;
              }
              if (hasBack) {
                state.removePageFromDocument(widget.documentId, 1);
              } else {
                _showSourcePicker(context);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIdSlot({
    required BuildContext context,
    required String title,
    required bool hasImage,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16161A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? Colors.blueAccent.withOpacity(0.5) : Colors.white10,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              if (hasImage && imageBytes != null)
                Positioned.fill(
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo, size: 40, color: Colors.white30),
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Tap to Scan', style: TextStyle(color: Colors.white30, fontSize: 12)),
                    ],
                  ),
                ),
              if (hasImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Multi-page grid for contracts and other documents
  Widget _buildMultiPageGrid(BuildContext context, LoanDocument doc, LoanSessionState state) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: doc.scannedPageBytes.length + 1,
      itemBuilder: (ctx, index) {
        if (index == doc.scannedPageBytes.length) {
          // "+" Button to add page
          return GestureDetector(
            onTap: () => _showSourcePicker(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16161A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 36, color: Colors.blueAccent),
                  SizedBox(height: 8),
                  Text('Add Page', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        // Display page thumbnail
        final imageBytes = doc.scannedPageBytes[index];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16161A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Page ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => state.removePageFromDocument(widget.documentId, index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
