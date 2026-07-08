const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS and JSON body parsing
app.use(cors());
app.use(express.json());

// Set up base directory for uploads
const UPLOADS_BASE = path.join(__dirname, 'uploads');
if (!fs.existsSync(UPLOADS_BASE)) {
  fs.mkdirSync(UPLOADS_BASE);
}

// Multer Storage Configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Read loan ID from headers to create a specific subdirectory
    const loanId = req.headers['x-loan-id'] || 'UNKNOWN_LOAN';
    // Clean directory name
    const cleanLoanId = loanId.replace(/[^a-zA-Z0-9_-]/g, '_');
    const loanDir = path.join(UPLOADS_BASE, `LOAN_${cleanLoanId}`);

    if (!fs.existsSync(loanDir)) {
      fs.mkdirSync(loanDir, { recursive: true });
    }
    cb(null, loanDir);
  },
  filename: (req, file, cb) => {
    // The client sends the properly formatted name, but we fallback just in case
    cb(null, file.originalname);
  }
});

const upload = multer({ storage: storage });

// Artificial delay middleware for testing concurrent progress
app.use((req, res, next) => {
  const simulateDelay = req.query.simulateDelay === 'true' || req.headers['x-simulate-delay'] === 'true';
  if (simulateDelay) {
    // Delay for 2.5 seconds to show concurrent progress bars in the mobile app UI
    setTimeout(next, 2500);
  } else {
    next();
  }
});

// File Upload endpoint
app.post('/api/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  // Retrieve metadata from headers
  const loanId = req.headers['x-loan-id'] || 'UNKNOWN_LOAN';
  const customerId = req.headers['x-customer-id'] || 'UNKNOWN_CUSTOMER';
  const customerName = req.headers['x-customer-name'] || '';
  const loanOfficer = req.headers['x-loan-officer'] || '';
  const docType = req.headers['x-document-type'] || 'Other';

  console.log(`[Upload] File received: ${req.file.originalname} (Size: ${(req.file.size / 1024).toFixed(2)} KB)`);
  console.log(`[Metadata] Loan: ${loanId}, Customer: ${customerId} (${customerName}), Officer: ${loanOfficer}`);

  // Create/update companion metadata.json for the loan application folder
  const cleanLoanId = loanId.replace(/[^a-zA-Z0-9_-]/g, '_');
  const loanDir = path.join(UPLOADS_BASE, `LOAN_${cleanLoanId}`);
  const metadataPath = path.join(loanDir, 'metadata.json');

  let metadata = {
    loanId,
    customerId,
    customerName,
    loanOfficer,
    lastUpdated: new Date().toISOString(),
    documents: []
  };

  if (fs.existsSync(metadataPath)) {
    try {
      metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
      metadata.lastUpdated = new Date().toISOString();
    } catch (e) {
      console.error('Error reading existing metadata.json', e);
    }
  }

  // Add document to metadata list if not already present
  if (!metadata.documents.some(doc => doc.filename === req.file.originalname)) {
    metadata.documents.push({
      filename: req.file.originalname,
      documentType: docType,
      uploadedAt: new Date().toISOString(),
      sizeBytes: req.file.size
    });
  }

  // Write updated metadata.json
  fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2), 'utf8');

  res.status(200).json({
    message: 'File uploaded successfully',
    filename: req.file.originalname,
    metadataPath: metadataPath
  });
});

// GET endpoint to list all uploads (for verification/admin panel)
app.get('/api/loans', (req, res) => {
  if (!fs.existsSync(UPLOADS_BASE)) {
    return res.json([]);
  }

  const dirs = fs.readdirSync(UPLOADS_BASE).filter(file => {
    return fs.statSync(path.join(UPLOADS_BASE, file)).isDirectory();
  });

  const loans = dirs.map(dir => {
    const metadataPath = path.join(UPLOADS_BASE, dir, 'metadata.json');
    if (fs.existsSync(metadataPath)) {
      try {
        return JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
      } catch (e) {
        return { folder: dir, error: 'Metadata corrupt' };
      }
    }
    return { folder: dir, message: 'No metadata.json' };
  });

  res.json(loans);
});

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Data Center Upload Server is active.' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`==================================================`);
  console.log(`Scan-Go Data Center Server running on port ${PORT}`);
  console.log(`Upload Endpoint: http://localhost:${PORT}/api/upload`);
  console.log(`Health Check:    http://localhost:${PORT}/health`);
  console.log(`==================================================`);
});
