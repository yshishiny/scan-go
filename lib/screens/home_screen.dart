import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/loan_session_state.dart';
import 'document_scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Scan-Go',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => _showSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            tooltip: 'Reset Session',
            onPressed: () => _confirmReset(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isTablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel: Metadata Form & Server Settings
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildMetadataCard(context),
                          const SizedBox(height: 16),
                          _buildConnectionCard(context),
                        ],
                      ),
                    ),
                  ),
                  // Right panel: Document Grid & Upload Progress
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDocumentGridHeader(),
                          const SizedBox(height: 12),
                          _buildDocumentGrid(context, isTablet: true),
                          const SizedBox(height: 16),
                          _buildUploadPanel(context),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildMetadataCard(context),
                    const SizedBox(height: 16),
                    _buildDocumentGridHeader(),
                    const SizedBox(height: 12),
                    _buildDocumentGrid(context, isTablet: false),
                    const SizedBox(height: 16),
                    _buildUploadPanel(context),
                  ],
                ),
              ),
      ),
    );
  }

  // Card to capture Loan Metadata
  Widget _buildMetadataCard(BuildContext context) {
    return Consumer<LoanSessionState>(
      builder: (context, state, child) {
        return Card(
          color: const Color(0xFF16161A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.folder_shared, color: Colors.blueAccent, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Loan Application Details',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                
                // Loan Officer Field
                TextFormField(
                  initialValue: state.loanOfficer,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Loan Officer Name', Icons.badge),
                  onChanged: (val) => state.updateMetadata(loanOfficer: val),
                ),
                const SizedBox(height: 14),

                // Loan ID Field
                TextFormField(
                  initialValue: state.loanId,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Loan Application ID', Icons.vpn_key),
                  onChanged: (val) => state.updateMetadata(loanId: val),
                ),
                const SizedBox(height: 14),

                // Customer ID Field
                TextFormField(
                  initialValue: state.customerId,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Customer ID', Icons.fingerprint),
                  onChanged: (val) => state.updateMetadata(customerId: val),
                ),
                const SizedBox(height: 14),

                // Customer Name Field
                TextFormField(
                  initialValue: state.customerName,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Customer Full Name', Icons.person),
                  onChanged: (val) => state.updateMetadata(customerName: val),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // InputDecoration Helper
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white30, size: 20),
      filled: true,
      fillColor: const Color(0xFF0F0F11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    );
  }

  // Settings Card (only shown in left column on tablet)
  Widget _buildConnectionCard(BuildContext context) {
    return Consumer<LoanSessionState>(
      builder: (context, state, child) {
        return Card(
          color: const Color(0xFF16161A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.router, color: Colors.greenAccent, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Connection & Transport',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildInfoRow('Endpoint', state.serverUrl),
                const SizedBox(height: 8),
                _buildInfoRow('Concurrency Limit', '${state.concurrency} concurrent sessions'),
                const SizedBox(height: 8),
                _buildInfoRow('Simulation Latency', state.simulateDelay ? 'Enabled (2.5s)' : 'Disabled'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Configure Settings'),
                  onPressed: () => _showSettingsDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white70, fontSize: 13, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildDocumentGridHeader() {
    return const Row(
      children: [
        Icon(Icons.checklist, color: Colors.blueAccent, size: 22),
        SizedBox(width: 10),
        Text(
          'Required Loan Documents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  // Document Grid (Responsive counts)
  Widget _buildDocumentGrid(BuildContext context, {required bool isTablet}) {
    return Consumer<LoanSessionState>(
      builder: (context, state, child) {
        return Column(
          children: state.documents.map((doc) {
            final hasPages = doc.scannedPageBytes.isNotEmpty;
            final isFormLocked = !state.isFormValid;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: isFormLocked ? const Color(0xFF131315) : const Color(0xFF16161A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: doc.status == 'Uploaded'
                      ? Colors.green.withOpacity(0.3)
                      : doc.status == 'Compiled'
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.white10,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isFormLocked
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill out the Loan Application Details first.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentScanScreen(documentId: doc.id),
                          ),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      _buildStatusIcon(doc.status),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.displayName,
                              style: TextStyle(
                                color: isFormLocked ? Colors.white30 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${doc.scannedPageBytes.length} page${doc.scannedPageBytes.length == 1 ? '' : 's'} scanned' +
                                  (doc.requiredPages != null
                                      ? ' (Requires exactly ${doc.requiredPages})'
                                      : ''),
                              style: TextStyle(
                                color: hasPages ? Colors.blueAccent : Colors.white30,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(doc.status),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: isFormLocked ? Colors.white10 : Colors.white30,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Visual icon reflecting file lifecycle status
  Widget _buildStatusIcon(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Uploaded':
        color = Colors.greenAccent;
        icon = Icons.check_circle;
        break;
      case 'Uploading':
        color = Colors.orangeAccent;
        icon = Icons.sync;
        break;
      case 'Compiled':
        color = Colors.blueAccent;
        icon = Icons.picture_as_pdf;
        break;
      case 'Compiling':
        color = Colors.purpleAccent;
        icon = Icons.hourglass_empty;
        break;
      case 'Failed':
        color = Colors.redAccent;
        icon = Icons.error;
        break;
      default:
        color = Colors.white24;
        icon = Icons.circle_outlined;
    }

    return Icon(icon, color: color, size: 24);
  }

  // Visual badge reflecting file lifecycle status
  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String label = status;

    switch (status) {
      case 'Uploaded':
        color = Colors.greenAccent;
        icon = Icons.cloud_done;
        break;
      case 'Uploading':
        color = Colors.orangeAccent;
        icon = Icons.cloud_upload;
        break;
      case 'Compiled':
        color = Colors.blueAccent;
        icon = Icons.check_circle_outline;
        break;
      case 'Compiling':
        color = Colors.purpleAccent;
        icon = Icons.hourglass_top;
        break;
      case 'Failed':
        color = Colors.redAccent;
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.white24;
        icon = Icons.edit_note;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Upload actions and active parallel transfer dashboard
  Widget _buildUploadPanel(BuildContext context) {
    return Consumer<LoanSessionState>(
      builder: (context, state, child) {
        final compiledDocs = state.documents.where((d) => d.status == 'Compiled' || d.status == 'Failed').toList();
        final uploadingDocs = state.documents.where((d) => d.status == 'Uploading').toList();
        final uploadedDocs = state.documents.where((d) => d.status == 'Uploaded').toList();
        final isUploading = uploadingDocs.isNotEmpty;

        final isFormLocked = !state.isFormValid;
        final hasSomethingToUpload = compiledDocs.isNotEmpty;

        return Card(
          color: const Color(0xFF16161A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isUploading ? Colors.blueAccent.withOpacity(0.3) : Colors.white10,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.swap_horizontal_circle, color: Colors.blueAccent, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Data Center Transfer Hub',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isUploading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Parallel upload active (Max: ${state.concurrency})',
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),

                // Upload statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Compiled', compiledDocs.length.toString(), Colors.blueAccent),
                    _buildStatItem('Uploading', uploadingDocs.length.toString(), Colors.orangeAccent),
                    _buildStatItem('Uploaded', uploadedDocs.length.toString(), Colors.greenAccent),
                  ],
                ),
                const SizedBox(height: 20),

                // List of active uploads with progress bars
                if (isUploading || state.documents.any((d) => d.status == 'Failed' || d.status == 'Uploaded'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Queue Status',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...state.documents
                          .where((d) => d.status == 'Uploading' || d.status == 'Uploaded' || d.status == 'Failed')
                          .map((d) => _buildUploadQueueRow(d)),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Main Transfer Action Button
                ElevatedButton.icon(
                  icon: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    isUploading
                        ? 'Uploading in Parallel...'
                        : 'Transfer to Data Center (${compiledDocs.length} files)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: hasSomethingToUpload && !isUploading && !isFormLocked
                      ? () async {
                          await state.uploadAllDocuments();
                          if (context.mounted) {
                            final failures = state.documents.where((d) => d.status == 'Failed').toList();
                            if (failures.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All documents transferred to Data Center successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${failures.length} upload(s) failed. Please retry.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  // Row showing progress for a document in the upload list
  Widget _buildUploadQueueRow(LoanDocument doc) {
    Color progressColor = Colors.blueAccent;
    if (doc.status == 'Uploaded') progressColor = Colors.green;
    if (doc.status == 'Failed') progressColor = Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  doc.displayName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, overflow: TextOverflow.ellipsis),
                ),
              ),
              Text(
                doc.status == 'Uploaded'
                    ? '100%'
                    : doc.status == 'Failed'
                        ? 'Failed'
                        : '${(doc.uploadProgress * 100).toInt()}%',
                style: TextStyle(color: progressColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: doc.status == 'Uploaded' ? 1.0 : (doc.status == 'Failed' ? 0.0 : doc.uploadProgress),
              backgroundColor: Colors.white10,
              color: progressColor,
              minHeight: 6,
            ),
          ),
          if (doc.status == 'Failed' && doc.uploadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                doc.uploadError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
              ),
            )
        ],
      ),
    );
  }

  // Show Connection/Concurrency settings
  void _showSettingsDialog(BuildContext context) {
    final state = Provider.of<LoanSessionState>(context, listen: false);
    final urlController = TextEditingController(text: state.serverUrl);
    double concurrencyVal = state.concurrency.toDouble();
    bool delayVal = state.simulateDelay;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16161A),
              title: const Text('Transport Configuration', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        labelStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Concurrency Streams:', style: TextStyle(color: Colors.white70)),
                        Text('${concurrencyVal.toInt()}',
                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Slider(
                      min: 1,
                      max: 6,
                      divisions: 5,
                      value: concurrencyVal,
                      onChanged: (val) {
                        setState(() {
                          concurrencyVal = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Simulate Network Delay', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      subtitle: const Text('Adds 2.5s delay to visualize parallel uploading', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      value: delayVal,
                      onChanged: (val) {
                        setState(() {
                          delayVal = val;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    state.updateServerSettings(
                      urlController.text.trim(),
                      concurrencyVal.toInt(),
                      delayVal,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Settings'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          title: const Text('Reset Active Session?', style: TextStyle(color: Colors.white)),
          content: const Text('This will clear all current inputs, scans, and upload history.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<LoanSessionState>(context, listen: false).resetSession();
                Navigator.pop(ctx);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
