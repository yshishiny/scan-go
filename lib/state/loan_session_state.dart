import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class LoanDocument {
  final String id;
  final String displayName;
  final int? requiredPages; // null means arbitrary, e.g. 2 for ID
  final List<String> scannedPagePaths; // File paths for native, or object URLs for web
  final List<Uint8List> scannedPageBytes; // Raw bytes for web/native compatibility
  String? compiledPdfPath;
  Uint8List? compiledPdfBytes;
  String status; // 'Pending', 'Compiling', 'Compiled', 'Uploading', 'Uploaded', 'Failed'
  double uploadProgress; // 0.0 to 1.0
  String? uploadError;

  LoanDocument({
    required this.id,
    required this.displayName,
    this.requiredPages,
    List<String>? scannedPagePaths,
    List<Uint8List>? scannedPageBytes,
    this.compiledPdfPath,
    this.compiledPdfBytes,
    this.status = 'Pending',
    this.uploadProgress = 0.0,
    this.uploadError,
  })  : this.scannedPagePaths = scannedPagePaths ?? [],
        this.scannedPageBytes = scannedPageBytes ?? [];

  bool get isValid => requiredPages == null 
      ? scannedPageBytes.isNotEmpty 
      : scannedPageBytes.length == requiredPages;
}

class LoanSessionState with ChangeNotifier {
  // Form fields
  String _loanOfficer = '';
  String _loanId = '';
  String _customerId = '';
  String _customerName = '';

  // Server settings
  String _serverUrl = 'http://localhost:3000/api/upload';
  int _concurrency = 3;
  bool _simulateDelay = true;

  // Document checklist
  List<LoanDocument> _documents = [];

  // Getters
  String get loanOfficer => _loanOfficer;
  String get loanId => _loanId;
  String get customerId => _customerId;
  String get customerName => _customerName;
  String get serverUrl => _serverUrl;
  int get concurrency => _concurrency;
  bool get simulateDelay => _simulateDelay;
  List<LoanDocument> get documents => _documents;

  bool get isFormValid =>
      _loanOfficer.trim().isNotEmpty &&
      _loanId.trim().isNotEmpty &&
      _customerId.trim().isNotEmpty &&
      _customerName.trim().isNotEmpty;

  LoanSessionState() {
    _resetChecklist();
  }

  // Setters
  void updateMetadata({
    String? loanOfficer,
    String? loanId,
    String? customerId,
    String? customerName,
  }) {
    if (loanOfficer != null) _loanOfficer = loanOfficer;
    if (loanId != null) _loanId = loanId;
    if (customerId != null) _customerId = customerId;
    if (customerName != null) _customerName = customerName;
    notifyListeners();
  }

  void updateServerSettings(String url, int conc, bool delay) {
    _serverUrl = url;
    _concurrency = conc;
    _simulateDelay = delay;
    notifyListeners();
  }

  void _resetChecklist() {
    _documents = [
      LoanDocument(id: 'NationalID', displayName: 'National ID (Front & Back)', requiredPages: 2),
      LoanDocument(id: 'LoanContract', displayName: 'Loan Contract (Multi-page)'),
      LoanDocument(id: 'UtilityProof', displayName: 'Utility Proof (Address)'),
      LoanDocument(id: 'SalaryCertificate', displayName: 'Salary Certificate (Income)'),
      LoanDocument(id: 'BankStatement', displayName: 'Bank Statement (3 Months)'),
      LoanDocument(id: 'OtherDoc', displayName: 'Other Support Documents'),
    ];
    notifyListeners();
  }

  void resetSession() {
    _loanOfficer = '';
    _loanId = '';
    _customerId = '';
    _customerName = '';
    _resetChecklist();
  }

  // Document capture actions
  void addPageToDocument(String docId, String path, Uint8List bytes) {
    final index = _documents.indexWhere((d) => d.id == docId);
    if (index != -1) {
      final doc = _documents[index];
      // If we already satisfied the requiredPages, don't allow more (e.g. ID card 2 faces)
      if (doc.requiredPages != null && doc.scannedPageBytes.length >= doc.requiredPages!) {
        return;
      }
      doc.scannedPagePaths.add(path);
      doc.scannedPageBytes.add(bytes);
      doc.status = 'Pending'; // Needs compilation
      doc.compiledPdfPath = null;
      doc.compiledPdfBytes = null;
      notifyListeners();
    }
  }

  void removePageFromDocument(String docId, int pageIndex) {
    final index = _documents.indexWhere((d) => d.id == docId);
    if (index != -1) {
      final doc = _documents[index];
      if (pageIndex >= 0 && pageIndex < doc.scannedPageBytes.length) {
        if (doc.scannedPagePaths.length > pageIndex) {
          doc.scannedPagePaths.removeAt(pageIndex);
        }
        doc.scannedPageBytes.removeAt(pageIndex);
        doc.status = 'Pending';
        doc.compiledPdfPath = null;
        doc.compiledPdfBytes = null;
        notifyListeners();
      }
    }
  }

  // Background compression helper runs in isolate to avoid freezing main thread
  static Uint8List _compressImage(Uint8List rawBytes) {
    final image = img.decodeImage(rawBytes);
    if (image == null) return rawBytes;

    img.Image resized = image;
    // Compress dimensions to max 1280px maintaining aspect ratio
    if (image.width > 1280 || image.height > 1280) {
      if (image.width > image.height) {
        resized = img.copyResize(image, width: 1280);
      } else {
        resized = img.copyResize(image, height: 1280);
      }
    }
    // Encode to JPEG at 65% quality
    return Uint8List.fromList(img.encodeJpg(resized, quality: 65));
  }

  // Compile Document to PDF
  Future<void> compileDocument(String docId) async {
    final index = _documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final doc = _documents[index];
    if (!doc.isValid) return;

    doc.status = 'Compiling';
    notifyListeners();

    try {
      final List<Uint8List> compressedImages = [];

      // Compress all pages in isolates
      for (final rawBytes in doc.scannedPageBytes) {
        // compute runs functions in a separate isolate
        final compressed = await compute(_compressImage, rawBytes);
        compressedImages.add(compressed);
      }

      // Generate PDF
      final pdf = pw.Document();
      for (final imgBytes in compressedImages) {
        final pdfImage = pw.MemoryImage(imgBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(10),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();
      doc.compiledPdfBytes = pdfBytes;

      // Save locally if on native platforms
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final cleanLoanId = _loanId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final cleanCustId = _customerId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final filename = 'LOAN_${cleanLoanId}_${cleanCustId}_${doc.id}_$timestamp.pdf';
        
        final file = File(p.join(tempDir.path, filename));
        await file.writeAsBytes(pdfBytes);
        doc.compiledPdfPath = file.path;
      }

      doc.status = 'Compiled';
      doc.uploadError = null;
    } catch (e) {
      doc.status = 'Failed';
      doc.uploadError = 'Compilation failed: ${e.toString()}';
    }
    notifyListeners();
  }

  // Upload a single compiled document
  Future<void> uploadDocument(LoanDocument doc) async {
    if (doc.status != 'Compiled' && doc.status != 'Failed') return;
    if (doc.compiledPdfBytes == null) {
      doc.status = 'Failed';
      doc.uploadError = 'No compiled PDF data found';
      notifyListeners();
      return;
    }

    doc.status = 'Uploading';
    doc.uploadProgress = 0.05;
    doc.uploadError = null;
    notifyListeners();

    try {
      final dio = Dio();
      
      // Determine professional filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final cleanLoanId = _loanId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final cleanCustId = _customerId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filename = 'LOAN_${cleanLoanId}_${cleanCustId}_${doc.id}_$timestamp.pdf';

      // Create multipart file from bytes (works on Web & Native)
      final multipartFile = MultipartFile.fromBytes(
        doc.compiledPdfBytes!,
        filename: filename,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      // Execute upload
      final response = await dio.post(
        _serverUrl,
        data: formData,
        options: Options(
          headers: {
            'x-loan-id': _loanId,
            'x-customer-id': _customerId,
            'x-customer-name': _customerName,
            'x-loan-officer': _loanOfficer,
            'x-document-type': doc.displayName,
            'x-simulate-delay': _simulateDelay ? 'true' : 'false',
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            doc.uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      if (response.statusCode == 200) {
        doc.status = 'Uploaded';
        doc.uploadProgress = 1.0;
      } else {
        doc.status = 'Failed';
        doc.uploadError = 'Server returned code ${response.statusCode}';
      }
    } catch (e) {
      doc.status = 'Failed';
      doc.uploadError = 'Upload failed: ${e.toString()}';
    }
    notifyListeners();
  }

  // Upload all compiled documents in parallel using standard concurrent queue
  Future<void> uploadAllDocuments() async {
    final uploadQueue = _documents
        .where((doc) => doc.status == 'Compiled' || doc.status == 'Failed')
        .toList();

    if (uploadQueue.isEmpty) return;

    int activeIndex = 0;
    
    // Concurrency worker definition
    Future<void> worker() async {
      while (activeIndex < uploadQueue.length) {
        // Read and increment index in a single synchronous block (guaranteed atomic in Dart)
        final docToUpload = uploadQueue[activeIndex];
        activeIndex++;
        
        await uploadDocument(docToUpload);
      }
    }

    final workerCount = min(_concurrency, uploadQueue.length);
    final List<Future<void>> workers = List.generate(workerCount, (_) => worker());
    
    await Future.wait(workers);
  }
}
