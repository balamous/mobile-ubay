const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { Pool } = require('pg');
const { Client } = require('minio');
const { createServer } = require('http');
const { Server } = require('socket.io');

const app = express();
const PORT = process.env.API_PORT || 3000;

// Create HTTP server for WebSocket
const httpServer = createServer(app);

// Configure Socket.IO
const io = new Server(httpServer, {
  cors: {
    origin: ['http://localhost:8080', 'http://localhost:8081', 'http://127.0.0.1:8080', 'http://127.0.0.1:8081', 'http://localhost:3000'],
    credentials: true,
    methods: ['GET', 'POST']
  }
});

// Store connected users: userId -> socketId
const connectedUsers = new Map();

// WebSocket connection handler
io.on('connection', (socket) => {
  console.log('[WebSocket] Client connected:', socket.id);

  // User authentication and room joining
  socket.on('authenticate', (data) => {
    const { userId } = data;
    if (userId) {
      connectedUsers.set(userId, socket.id);
      socket.userId = userId;
      socket.join(`user_${userId}`);
      console.log(`[WebSocket] User ${userId} authenticated and joined room user_${userId}`);
      socket.emit('authenticated', { success: true, userId });
    }
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('[WebSocket] Client disconnected:', socket.id);
    if (socket.userId) {
      connectedUsers.delete(socket.userId);
    }
  });
});

// Helper function to notify user of transaction
function notifyUserTransaction(userId, transaction) {
  const socketId = connectedUsers.get(userId);
  if (socketId) {
    io.to(`user_${userId}`).emit('new_transaction', {
      type: 'transaction',
      data: transaction,
      timestamp: new Date().toISOString()
    });
    console.log(`[WebSocket] Transaction notification sent to user ${userId}`);
    return true;
  }
  console.log(`[WebSocket] User ${userId} not connected, notification queued`);
  return false;
}

// Helper function to notify balance update
function notifyBalanceUpdate(userId, balance) {
  const socketId = connectedUsers.get(userId);
  if (socketId) {
    io.to(`user_${userId}`).emit('balance_update', {
      type: 'balance',
      data: { balance },
      timestamp: new Date().toISOString()
    });
    console.log(`[WebSocket] Balance update sent to user ${userId}: ${balance}`);
    return true;
  }
  return false;
}

// Middleware
app.use(cors({
  origin: ['http://localhost:8080', 'http://localhost:8081', 'http://127.0.0.1:8080', 'http://127.0.0.1:8081'],
  credentials: true
}));
// Augmenter la limite pour accepter les images en base64 (50MB max)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://fintech_admin:fintech_password_2024@db:5432/fintech_db',
});

// Helper function to convert French date format to ISO format
function convertFrenchDateToISO(dateString) {
  if (!dateString || typeof dateString !== 'string') return dateString;

  // If already in ISO format (YYYY-MM-DD), return as-is
  if (/^\d{4}-\d{2}-\d{2}$/.test(dateString)) {
    return dateString;
  }

  // Parse French format: "27 avril 2026"
  const monthNames = {
    'janvier': '01', 'fevrier': '02', 'mars': '03', 'avril': '04',
    'mai': '05', 'juin': '06', 'juillet': '07', 'aout': '08',
    'septembre': '09', 'octobre': '10', 'novembre': '11', 'decembre': '12'
  };

  const parts = dateString.toLowerCase().trim().split(' ');
  if (parts.length === 3) {
    const day = parts[0].padStart(2, '0');
    const month = monthNames[parts[1]];
    const year = parts[2];

    if (month) {
      return `${year}-${month}-${day}`;
    }
  }

  // If parsing fails, return original value
  return dateString;
}

// MinIO configuration
const minioEndpoint = (process.env.MINIO_ENDPOINT || 'localhost').replace('http://', '').replace('https://', '');
const minioClient = new Client({
  endPoint: minioEndpoint,
  port: parseInt(process.env.MINIO_PORT) || 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
  secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin123',
});

// Initialize MinIO bucket
async function initializeMinIO() {
  try {
    const bucketName = process.env.MINIO_BUCKET || 'ubay-documents';
    const bucketExists = await minioClient.bucketExists(bucketName);
    
    if (!bucketExists) {
      await minioClient.makeBucket(bucketName, {
        region: 'us-east-1',
      });
      console.log(`MinIO bucket '${bucketName}' created successfully`);
    } else {
      console.log(`MinIO bucket '${bucketName}' already exists`);
    }
  } catch (error) {
    console.error('MinIO initialization error:', error);
  }
}

// Health check
app.get('/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: result.rows[0].now
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// Simple test endpoint
app.get('/api/test', (req, res) => {
  res.json({
    message: 'UBAY API is working!',
    timestamp: new Date().toISOString()
  });
});

// ========================================
// AUTHENTICATION ENDPOINTS
// ========================================

// Login endpoint
app.post('/auth/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        error: 'Numéro de téléphone et mot de passe requis'
      });
    }

    // Query user from database
    const query = 'SELECT * FROM users WHERE phone = $1';
    const result = await pool.query(query, [phone]);

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Numéro de téléphone ou mot de passe incorrect'
      });
    }

    const user = result.rows[0];

    // Simple password check (in production, use bcrypt)
    if (user.password !== password) {
      return res.status(401).json({
        success: false,
        error: 'Numéro de téléphone ou mot de passe incorrect'
      });
    }

    // Generate simple JWT token (in production, use proper JWT)
    const token = `token_${user.id}_${Date.now()}`;

    // Return user data without password
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      data: {
        user: userWithoutPassword,
        token: token
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la connexion'
    });
  }
});

// Register endpoint
app.post('/auth/register', async (req, res) => {
  try {
    const { 
      email, 
      password, 
      firstName, 
      lastName, 
      phone 
    } = req.body;

    if (!email || !password || !firstName || !lastName || !phone) {
      return res.status(400).json({
        success: false,
        error: 'Tous les champs sont requis'
      });
    }

    // Check if user already exists
    const checkQuery = 'SELECT id FROM users WHERE email = $1';
    const checkResult = await pool.query(checkQuery, [email]);

    if (checkResult.rows.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'Un utilisateur avec cet email existe déjà'
      });
    }

    // Create new user
    const insertQuery = `
      INSERT INTO users (
        email, 
        password, 
        first_name, 
        last_name, 
        phone, 
        balance, 
        savings_balance, 
        account_number, 
        is_verified, 
        kyc_level, 
        created_at
      ) VALUES (
        $1, $2, $3, $4, $5, 0, 0, $6, false, 'none', NOW()
      ) RETURNING *
    `;

    const accountNumber = `GN-${new Date().getFullYear()}-${Math.floor(Math.random() * 100000)}`;
    const values = [email, password, firstName, lastName, phone, accountNumber];

    const result = await pool.query(insertQuery, values);
    const newUser = result.rows[0];

    // Generate token
    const token = `token_${newUser.id}_${Date.now()}`;

    // Return user data without password
    const { password: _, ...userWithoutPassword } = newUser;

    res.status(201).json({
      success: true,
      data: {
        user: userWithoutPassword,
        token: token
      }
    });

  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de l\'inscription'
    });
  }
});

// Get user profile endpoint - supporte les deux chemins pour compatibilité
app.get('/users/profile', async (req, res) => {
  // Forward to the main handler
  handleGetProfile(req, res);
});

app.get('/api/profile', async (req, res) => {
  handleGetProfile(req, res);
});

async function handleGetProfile(req, res) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Token d\'authentification requis'
      });
    }

    const token = authHeader.substring(7);
    
    // Extract user ID from token (simple approach)
    const userId = token.split('_')[1];
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Token invalide'
      });
    }

    // Query user from database
    const query = 'SELECT * FROM users WHERE id = $1';
    const result = await pool.query(query, [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Utilisateur non trouvé'
      });
    }

    const user = result.rows[0];

    // Return user data without password
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      data: userWithoutPassword
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération du profil'
    });
  }
}

// Update user profile endpoint
app.put('/api/users/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const updates = req.body;
    
    console.log('Updating user profile:', userId, updates);
    
    // Build dynamic query based on provided fields
    const allowedFields = [
      'first_name', 'last_name', 'email', 'phone', 'avatar_url',
      'birth_date', 'birth_place', 'gender', 'profession', 'employer',
      'city', 'commune', 'neighborhood', 'nationality',
      'id_type', 'id_number', 'id_country', 'id_issue_date', 'id_expiry_date',
      'id_front_image', 'id_back_image', 'address', 'postal_code'
    ];
    
    const setClauses = [];
    const values = [];
    let paramIndex = 1;
    
    for (const [key, value] of Object.entries(updates)) {
      // Convert camelCase to snake_case
      const dbField = key.replace(/([A-Z])/g, '_$1').toLowerCase();

      if (allowedFields.includes(dbField)) {
        setClauses.push(`${dbField} = $${paramIndex}`);

        // Convert French date format to ISO format for date fields
        let processedValue = value;
        if ((dbField === 'id_issue_date' || dbField === 'id_expiry_date' || dbField === 'birth_date') && value && typeof value === 'string') {
          processedValue = convertFrenchDateToISO(value);
        }

        values.push(processedValue);
        paramIndex++;
      }
    }
    
    if (setClauses.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Aucun champ valide à mettre à jour'
      });
    }
    
    // Add updated_at timestamp
    setClauses.push(`updated_at = CURRENT_TIMESTAMP`);
    
    // Build and execute query
    const query = `
      UPDATE users 
      SET ${setClauses.join(', ')} 
      WHERE id = $${paramIndex} 
      RETURNING *
    `;
    values.push(userId);
    
    console.log('Update query:', query);
    console.log('Values:', values);
    
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Utilisateur non trouvé'
      });
    }
    
    const user = result.rows[0];
    const { password: _, ...userWithoutPassword } = user;
    
    res.json({
      success: true,
      message: 'Profil mis à jour avec succès',
      data: userWithoutPassword
    });
    
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la mise à jour du profil'
    });
  }
});

// Configure multer for file uploads
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// Upload document/image endpoint
app.post('/api/users/:userId/documents', upload.single('file'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { documentType } = req.body;
    const file = req.file;
    
    console.log('Uploading document for user:', userId, 'type:', documentType);
    
    if (!documentType || !file) {
      return res.status(400).json({
        success: false,
        error: 'Type de document et fichier requis'
      });
    }
    
    // Validate document type
    const allowedTypes = ['id_front', 'id_back', 'avatar', 'proof_address', 'other'];
    if (!allowedTypes.includes(documentType)) {
      return res.status(400).json({
        success: false,
        error: 'Type de document non valide'
      });
    }
    
    // Generate unique filename
    const fileName = `${userId}_${documentType}_${Date.now()}_${file.originalname}`;
    const bucketName = process.env.MINIO_BUCKET || 'ubay-documents';
    
    // Upload to MinIO
    await minioClient.putObject(bucketName, fileName, file.buffer);
    
    // Get public URL (accessible from outside)
    const minioPublicUrl = process.env.MINIO_PUBLIC_URL || `http://localhost:9000`;
    const imageUrl = `${minioPublicUrl}/${bucketName}/${fileName}`;
    
    // Map document type to database field
    const fieldMap = {
      'id_front': 'id_front_image',
      'id_back': 'id_back_image',
      'avatar': 'avatar_url'
    };
    
    const dbField = fieldMap[documentType];
    
    if (dbField) {
      // Update user record with document URL
      const query = `
        UPDATE users 
        SET ${dbField} = $1, updated_at = CURRENT_TIMESTAMP 
        WHERE id = $2 
        RETURNING id, ${dbField}
      `;
      
      const result = await pool.query(query, [imageUrl, userId]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Utilisateur non trouvé'
        });
      }
    }
    
    res.json({
      success: true,
      message: 'Document téléchargé avec succès',
      data: {
        documentType,
        fileName,
        imageUrl,
        uploadedAt: new Date().toISOString()
      }
    });
    
  } catch (error) {
    console.error('Document upload error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors du téléchargement du document'
    });
  }
});

// Get payment methods
app.get('/api/payment-methods', async (req, res) => {
  try {
    // Payment methods data (could be stored in database table)
    const paymentMethods = [
      {
        id: 'pm_001',
        name: 'Orange Money',
        logoPath: 'assets/images/orange.png',
        color: '#FF8C00',
        type: 'mobile_money',
        isActive: true
      },
      {
        id: 'pm_002',
        name: 'MTN MoMo',
        logoPath: 'assets/images/momo.jpeg',
        color: '#FFC107',
        type: 'mobile_money',
        isActive: true
      },

    ];

    res.json({
      success: true,
      data: {
        paymentMethods: paymentMethods
      }
    });

  } catch (error) {
    console.error('Get payment methods error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération des méthodes de paiement'
    });
  }
});

// Get services
app.get('/api/services', async (req, res) => {
  try {
    // Services data (could be stored in database table)
    const services = [
      {
        id: 'svc_001',
        name: 'EDG - Électricité',
        description: 'Paiement facture électricité',
        iconPath: 'electricity',
        category: 'utilities',
        isPopular: true,
        fixedAmount: 220000.00,
        color: '#1A56DB'
      },
      {
        id: 'svc_002',
        name: 'SEG - Eau',
        description: 'Paiement facture eau',
        iconPath: 'water',
        category: 'utilities',
        isPopular: false,
        fixedAmount: 15000.00,
        color: '#0891B2'
      },
      {
        id: 'svc_003',
        name: 'Orange - Crédit',
        description: 'Crédit mobile Orange',
        iconPath: 'mobile',
        category: 'telecom',
        isPopular: true,
        fixedAmount: null,
        color: '#FF8C00'
      },
      {
        id: 'svc_004',
        name: 'MTN - Crédit',
        description: 'Crédit mobile MTN',
        iconPath: 'mobile',
        category: 'telecom',
        isPopular: true,
        fixedAmount: null,
        color: '#FFB800'
      },
            {
        id: 'svc_007',
        name: 'Netflix',
        description: 'Streaming Netflix',
        iconPath: 'streaming',
        category: 'streaming',
        isPopular: true,
        fixedAmount: 35000.00,
        color: '#E50914'
      },
      {
        id: 'svc_008',
        name: 'Disney+',
        description: 'Streaming Disney',
        iconPath: 'streaming',
        category: 'streaming',
        isPopular: false,
        fixedAmount: 28000.00,
        color: '#113CCF'
      }
    ];

    res.json({
      success: true,
      data: {
        services: services
      }
    });

  } catch (error) {
    console.error('Get services error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération des services'
    });
  }
});

// Get operators
app.get('/api/operators', async (req, res) => {
  try {
    // Operators data (could be stored in database table)
    const operators = [
      {
        id: 'op_001',
        name: 'Orange',
        logoPath: 'assets/images/orange.png',
        color: '#FF8C00',
        code: 'orange',
        isActive: true
      },
      {
        id: 'op_002',
        name: 'MTN',
        logoPath: 'assets/images/momo.jpeg',
        color: '#FFB800',
        code: 'mtn',
        isActive: true
      }
    ];

    res.json({
      success: true,
      data: {
        operators: operators
      }
    });

  } catch (error) {
    console.error('Get operators error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération des opérateurs'
    });
  }
});

// Save transaction
app.post('/api/transactions', async (req, res) => {
  try {
    const { userId, type, amount, description, recipient, category, status = 'completed' } = req.body;
    
    if (!userId || !type || !amount || !description) {
      return res.status(400).json({
        success: false,
        error: 'Champs requis: userId, type, amount, description'
      });
    }

    const transactionId = `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const createdAt = new Date().toISOString();

    // Create transactions table
    const createTransactionsTable = `
      CREATE TABLE IF NOT EXISTS transactions (
        id VARCHAR(50) PRIMARY KEY,
        user_id UUID NOT NULL,
        type VARCHAR(50) NOT NULL,
        amount DECIMAL(12,2) NOT NULL,
        description TEXT NOT NULL,
        recipient VARCHAR(255),
        category VARCHAR(100),
        status VARCHAR(50) DEFAULT 'completed',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    `;

    // Create cards table
    const createCardsTable = `
      CREATE TABLE IF NOT EXISTS cards (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        card_number VARCHAR(16) NOT NULL UNIQUE,
        card_holder VARCHAR(100) NOT NULL,
        expiry_month VARCHAR(2) NOT NULL,
        expiry_year VARCHAR(4) NOT NULL,
        cvv VARCHAR(3) NOT NULL,
        type VARCHAR(20) NOT NULL DEFAULT 'visa',
        status VARCHAR(20) DEFAULT 'active',
        limit_amount DECIMAL(12,2) DEFAULT 1000000.00,
        spent_amount DECIMAL(12,2) DEFAULT 0.00,
        is_virtual BOOLEAN NOT NULL DEFAULT false,
        gradient_start VARCHAR(20) DEFAULT '#667eea',
        gradient_end VARCHAR(20) DEFAULT '#764ba2',
        is_default BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    `;

    await pool.query(createTransactionsTable);
    await pool.query(createCardsTable);

    // Create service categories table
    const createServiceCategoriesTable = `
      CREATE TABLE IF NOT EXISTS service_categories (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(100) NOT NULL UNIQUE,
        description TEXT,
        icon VARCHAR(50) NOT NULL,
        color VARCHAR(20) NOT NULL,
        is_active BOOLEAN DEFAULT true,
        sort_order INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    // Create services table
    const createServicesTable = `
      CREATE TABLE IF NOT EXISTS services (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        category_id UUID NOT NULL,
        name VARCHAR(100) NOT NULL,
        description TEXT NOT NULL,
        icon VARCHAR(50) NOT NULL,
        color VARCHAR(20) NOT NULL,
        price DECIMAL(12,2),
        is_popular BOOLEAN DEFAULT false,
        is_active BOOLEAN DEFAULT true,
        sort_order INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES service_categories(id)
      );
    `;

    // Create service subscriptions table
    const createServiceSubscriptionsTable = `
      CREATE TABLE IF NOT EXISTS service_subscriptions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL,
        service_id UUID NOT NULL,
        status VARCHAR(20) DEFAULT 'active',
        amount DECIMAL(12,2) NOT NULL,
        next_billing_date DATE,
        auto_renew BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (service_id) REFERENCES services(id)
      );
    `;

    // Create service transactions table
    const createServiceTransactionsTable = `
      CREATE TABLE IF NOT EXISTS service_transactions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL,
        service_id UUID NOT NULL,
        subscription_id UUID,
        amount DECIMAL(12,2) NOT NULL,
        status VARCHAR(20) DEFAULT 'completed',
        payment_method VARCHAR(50),
        transaction_reference VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (service_id) REFERENCES services(id),
        FOREIGN KEY (subscription_id) REFERENCES service_subscriptions(id)
      );
    `;

    await pool.query(createServiceCategoriesTable);
    await pool.query(createServicesTable);
    await pool.query(createServiceSubscriptionsTable);
    await pool.query(createServiceTransactionsTable);

    // Insert transaction into database
    const query = `
      INSERT INTO transactions (
        id, user_id, type, amount, description, recipient, category, status, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `;
    
    const values = [
      transactionId,
      userId,
      type,
      amount,
      description,
      recipient || null,
      category || null,
      status,
      createdAt
    ];

    const result = await pool.query(query, values);
    const transaction = result.rows[0];

    res.json({
      success: true,
      data: {
        transaction: {
          id: transaction.id,
          userId: transaction.user_id,
          type: transaction.type,
          amount: parseFloat(transaction.amount),
          description: transaction.description,
          recipient: transaction.recipient,
          category: transaction.category,
          status: transaction.status,
          createdAt: transaction.created_at
        }
      }
    });

  } catch (error) {
    console.error('Save transaction error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la sauvegarde de la transaction'
    });
  }
});

// Get user transactions
app.get('/api/transactions', async (req, res) => {
  try {
    const { userId, limit = 50, offset = 0 } = req.query;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'userId est requis'
      });
    }

    // Get transactions from database
    const query = `
      SELECT * FROM transactions 
      WHERE user_id = $1 
      ORDER BY created_at DESC 
      LIMIT $2 OFFSET $3
    `;
    
    const result = await pool.query(query, [userId, limit, offset]);
    const transactions = result.rows.map(tx => ({
      id: tx.id,
      userId: tx.user_id,
      type: tx.type,
      amount: parseFloat(tx.amount),
      description: tx.description,
      recipient: tx.recipient,
      category: tx.category,
      status: tx.status,
      createdAt: tx.created_at
    }));

    // Get total count
    const countQuery = 'SELECT COUNT(*) FROM transactions WHERE user_id = $1';
    const countResult = await pool.query(countQuery, [userId]);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        transactions: transactions,
        total: total,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });

  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération des transactions'
    });
  }
});

// Create card
app.post('/api/cards', async (req, res) => {
  try {
    const { userId, type, isVirtual, gradientStart, gradientEnd } = req.body;
    
    if (!userId || !type) {
      return res.status(400).json({
        success: false,
        error: 'Champs requis: userId, type'
      });
    }

    // Create cards table
    const createCardsTable = `
      CREATE TABLE IF NOT EXISTS cards (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        card_number VARCHAR(16) NOT NULL UNIQUE,
        card_holder VARCHAR(100) NOT NULL,
        expiry_month VARCHAR(2) NOT NULL,
        expiry_year VARCHAR(4) NOT NULL,
        cvv VARCHAR(3) NOT NULL,
        type VARCHAR(20) NOT NULL DEFAULT 'visa',
        status VARCHAR(20) DEFAULT 'active',
        limit_amount DECIMAL(12,2) DEFAULT 1000000.00,
        spent_amount DECIMAL(12,2) DEFAULT 0.00,
        is_virtual BOOLEAN NOT NULL DEFAULT false,
        gradient_start VARCHAR(20) DEFAULT '#667eea',
        gradient_end VARCHAR(20) DEFAULT '#764ba2',
        is_default BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    `;

    await pool.query(createCardsTable);

    // Check and add missing columns for existing tables
    try {
      // Check if type column exists
      const typeColumnCheck = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'type'
      `;
      const typeResult = await pool.query(typeColumnCheck);
      
      if (typeResult.rows.length === 0) {
        console.log('Adding missing type column to cards table...');
        await pool.query('ALTER TABLE cards ADD COLUMN type VARCHAR(20) NOT NULL DEFAULT \'visa\'');
      }

      // Check if status column exists
      const statusColumnCheck = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'status'
      `;
      const statusResult = await pool.query(statusColumnCheck);
      
      if (statusResult.rows.length === 0) {
        console.log('Adding missing status column to cards table...');
        await pool.query('ALTER TABLE cards ADD COLUMN status VARCHAR(20) DEFAULT \'active\'');
      }

      // Check if limit_amount column exists
      const limitColumnCheck = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'limit_amount'
      `;
      const limitResult = await pool.query(limitColumnCheck);
      
      if (limitResult.rows.length === 0) {
        console.log('Adding missing limit_amount column to cards table...');
        await pool.query('ALTER TABLE cards ADD COLUMN limit_amount DECIMAL(12,2) DEFAULT 1000000.00');
      }

      // Check if spent_amount column exists
      const spentColumnCheck = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'spent_amount'
      `;
      const spentResult = await pool.query(spentColumnCheck);
      
      if (spentResult.rows.length === 0) {
        console.log('Adding missing spent_amount column to cards table...');
        await pool.query('ALTER TABLE cards ADD COLUMN spent_amount DECIMAL(12,2) DEFAULT 0.00');
      }

      // Check if is_virtual column exists
      const virtualColumnCheck = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'is_virtual'
      `;
      const virtualResult = await pool.query(virtualColumnCheck);
      
      if (virtualResult.rows.length === 0) {
        console.log('Adding missing is_virtual column to cards table...');
        await pool.query('ALTER TABLE cards ADD COLUMN is_virtual BOOLEAN NOT NULL DEFAULT false');
      }

      // Check if gradient_start column exists
      const gradientStartColumnCheck = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'gradient_start'
      `;
      const gradientStartResult = await pool.query(gradientStartColumnCheck);
      
      if (gradientStartResult.rows.length === 0) {
        console.log('Adding missing gradient_start column to cards table...');
        await pool.query('ALTER TABLE cards ADD COLUMN gradient_start VARCHAR(20) DEFAULT \'#667eea\'');
      }

      // Check if gradient_end column exists
      const gradientEndColumnCheck = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'gradient_end'
      `;
      const gradientEndResult = await pool.query(gradientEndColumnCheck);
      
      if (gradientEndResult.rows.length === 0) {
        console.log('Adding missing gradient_end column to cards table...');
        await pool.query('ALTER TABLE cards ADD COLUMN gradient_end VARCHAR(20) DEFAULT \'#764ba2\'');
      }

      // Check if is_default column exists
      const defaultColumnCheck = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'is_default'
      `;
      const defaultResult = await pool.query(defaultColumnCheck);
      
      if (defaultResult.rows.length === 0) {
        console.log('Adding missing is_default column to cards table...');
        await pool.query('ALTER TABLE cards ADD COLUMN is_default BOOLEAN DEFAULT false');
      }

      console.log('Cards table migration completed successfully');
    } catch (migrationError) {
      console.log('Migration error (non-critical):', migrationError.message);
      // Continue even if migration fails
    }

    // Get user info for card holder name
    const userQuery = 'SELECT first_name, last_name FROM users WHERE id = $1';
    const userResult = await pool.query(userQuery, [userId]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Utilisateur non trouvé'
      });
    }

    const user = userResult.rows[0];
    const cardHolderName = `${user.first_name} ${user.last_name}`;

    // Generate card details
    const cardId = require('crypto').randomUUID();
    const cardNumber = Math.random().toString().slice(2, 18).padStart(16, '0');
    
    // Date d'expiration : même mois et jour que la création, mais + 3 ans
    const currentDate = new Date();
    const expiryMonth = String(currentDate.getMonth() + 1).padStart(2, '0');
    const expiryYear = String(currentDate.getFullYear() + 3);
    const cvv = Math.random().toString().slice(2, 5).padStart(3, '0');
    
    // Default gradients based on card type
    const defaultGradients = {
      visa: { start: '#667eea', end: '#764ba2' },
      mastercard: { start: '#f093fb', end: '#f5576c' }
    };

    const selectedGradient = defaultGradients[type] || defaultGradients.visa;

    // Helper function to format gradients
    const formatGradient = (color) => {
      if (!color || !color.startsWith('#')) {
        return '#' + (color || '');
      }
      return color;
    };

    // Insert card into database with all columns
    const query = `
      INSERT INTO cards (
        id, user_id, card_number, card_holder, expiry_month, expiry_year,
        cvv, type, card_type, status, is_default, limit_amount, spent_amount, is_virtual,
        gradient_start, gradient_end, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      )
      RETURNING *
    `;

    const values = [
      cardId,                                    // $1: id
      userId,                                    // $2: user_id
      cardNumber,                                // $3: card_number
      cardHolderName.toUpperCase(),                            // $4: card_holder
      parseInt(expiryMonth),                     // $5: expiry_month
      parseInt(expiryYear),                      // $6: expiry_year
      cvv,                                       // $7: cvv
      type,                                      // $8: type
      type,                                      // $9: card_type
      'active',                                  // $10: status
      false,                                     // $11: is_default
      1000000.00,                                // $12: limit_amount
      0.00,                                      // $13: spent_amount
      isVirtual || false,                        // $14: is_virtual
      formatGradient(gradientStart || selectedGradient.start),   // $15: gradient_start
      formatGradient(gradientEnd || selectedGradient.end)        // $16: gradient_end
    ];

    const result = await pool.query(query, values);
    const createdCard = result.rows[0];

    console.log('[TEST] Card created successfully:', createdCard);

    return res.status(201).json({
      success: true,
      data: {
        id: createdCard.id,
        cardNumber: createdCard.card_number,
        cardHolder: createdCard.card_holder,
        expiryMonth: createdCard.expiry_month,
        expiryYear: createdCard.expiry_year,
        cvv: createdCard.cvv,
        type: createdCard.type,
        status: createdCard.status,
        limit: parseFloat(createdCard.limit_amount),
        spent: parseFloat(createdCard.spent_amount),
        isVirtual: createdCard.is_virtual,
        gradientStart: createdCard.gradient_start,
        gradientEnd: createdCard.gradient_end,
        isDefault: createdCard.is_default,
        createdAt: createdCard.created_at
      }
    });

  } catch (error) {
    console.error('Create card error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la création de la carte'
    });
  }
});

// Get user cards
app.get('/api/cards/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'userId requis'
      });
    }

    // Create cards table
    const createCardsTable = `
      CREATE TABLE IF NOT EXISTS cards (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        card_number VARCHAR(16) NOT NULL UNIQUE,
        card_holder VARCHAR(100) NOT NULL,
        expiry_month VARCHAR(2) NOT NULL,
        expiry_year VARCHAR(4) NOT NULL,
        cvv VARCHAR(3) NOT NULL,
        type VARCHAR(20) NOT NULL DEFAULT 'visa',
        status VARCHAR(20) DEFAULT 'active',
        limit_amount DECIMAL(12,2) DEFAULT 1000000.00,
        spent_amount DECIMAL(12,2) DEFAULT 0.00,
        is_virtual BOOLEAN NOT NULL DEFAULT false,
        gradient_start VARCHAR(20) DEFAULT '#667eea',
        gradient_end VARCHAR(20) DEFAULT '#764ba2',
        is_default BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    `;

    await pool.query(createCardsTable);

    const query = `
      SELECT * FROM cards 
      WHERE user_id = $1 
      ORDER BY created_at DESC
    `;
    
    const result = await pool.query(query, [userId]);
    const cards = result.rows.map(card => ({
      id: card.id,
      cardNumber: card.card_number,
      cardHolder: card.card_holder,
      expiryMonth: card.expiry_month,
      expiryYear: card.expiry_year,
      cvv: card.cvv,
      type: card.type,
      status: card.status,
      limit: parseFloat(card.limit_amount),
      spent: parseFloat(card.spent_amount),
      isVirtual: card.is_virtual,
      gradientStart: card.gradient_start,
      gradientEnd: card.gradient_end,
      isDefault: card.is_default,
      createdAt: card.created_at
    }));

    res.json({
      success: true,
      data: {
        cards: cards
      }
    });

  } catch (error) {
    console.error('Get cards error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération des cartes'
    });
  }
});

// Update card
app.put('/api/cards/:cardId', async (req, res) => {
  try {
    const { cardId } = req.params;
    const { status, limitAmount, gradientStart, gradientEnd, isDefault } = req.body;
    
    if (!cardId) {
      return res.status(400).json({
        success: false,
        error: 'cardId requis'
      });
    }

    // Create cards table
    const createCardsTable = `
      CREATE TABLE IF NOT EXISTS cards (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        card_number VARCHAR(16) NOT NULL UNIQUE,
        card_holder VARCHAR(100) NOT NULL,
        expiry_month VARCHAR(2) NOT NULL,
        expiry_year VARCHAR(4) NOT NULL,
        cvv VARCHAR(3) NOT NULL,
        type VARCHAR(20) NOT NULL DEFAULT 'visa',
        status VARCHAR(20) DEFAULT 'active',
        limit_amount DECIMAL(12,2) DEFAULT 1000000.00,
        spent_amount DECIMAL(12,2) DEFAULT 0.00,
        is_virtual BOOLEAN NOT NULL DEFAULT false,
        gradient_start VARCHAR(20) DEFAULT '#667eea',
        gradient_end VARCHAR(20) DEFAULT '#764ba2',
        is_default BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    `;

    await pool.query(createCardsTable);

    // Check if card exists
    const checkQuery = 'SELECT * FROM cards WHERE id = $1';
    const checkResult = await pool.query(checkQuery, [cardId]);
    
    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Carte non trouvée'
      });
    }

    // Build dynamic update query
    let updateQuery = 'UPDATE cards SET updated_at = CURRENT_TIMESTAMP';
    const updateValues = [];
    let paramIndex = 1;

    if (status !== undefined) {
      updateQuery += `, status = $${paramIndex++}`;
      updateValues.push(status);
    }

    if (limitAmount !== undefined) {
      updateQuery += `, limit_amount = $${paramIndex++}`;
      updateValues.push(limitAmount);
    }

    if (gradientStart !== undefined) {
      updateQuery += `, gradient_start = $${paramIndex++}`;
      updateValues.push(gradientStart);
    }

    if (gradientEnd !== undefined) {
      updateQuery += `, gradient_end = $${paramIndex++}`;
      updateValues.push(gradientEnd);
    }

    if (isDefault !== undefined) {
      // If setting this card as default, unset other cards first
      if (isDefault) {
        const card = checkResult.rows[0];
        await pool.query('UPDATE cards SET is_default = false WHERE user_id = $1 AND id != $2', [card.user_id, cardId]);
      }
      updateQuery += `, is_default = $${paramIndex++}`;
      updateValues.push(isDefault);
    }

    updateQuery += ` WHERE id = $${paramIndex}`;
    updateValues.push(cardId);

    const result = await pool.query(updateQuery, updateValues);
    
    // Get updated card
    const getUpdatedQuery = 'SELECT * FROM cards WHERE id = $1';
    const updatedResult = await pool.query(getUpdatedQuery, [cardId]);
    const updatedCard = updatedResult.rows[0];

    console.log('Card updated successfully:', updatedCard);

    res.json({
      success: true,
      data: {
        id: updatedCard.id,
        cardNumber: updatedCard.card_number,
        cardHolder: updatedCard.card_holder,
        expiryMonth: updatedCard.expiry_month,
        expiryYear: updatedCard.expiry_year,
        cvv: updatedCard.cvv,
        type: updatedCard.type,
        status: updatedCard.status,
        limit: parseFloat(updatedCard.limit_amount),
        spent: parseFloat(updatedCard.spent_amount),
        isVirtual: updatedCard.is_virtual,
        gradientStart: updatedCard.gradient_start,
        gradientEnd: updatedCard.gradient_end,
        isDefault: updatedCard.is_default,
        createdAt: updatedCard.created_at,
        updatedAt: updatedCard.updated_at
      }
    });

  } catch (error) {
    console.error('Update card error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la mise à jour de la carte'
    });
  }
});

// Delete card (soft delete - change status to cancelled)
app.delete('/api/cards/:cardId', async (req, res) => {
  try {
    const { cardId } = req.params;
    
    if (!cardId) {
      return res.status(400).json({
        success: false,
        error: 'cardId requis'
      });
    }

    // Create cards table
    const createCardsTable = `
      CREATE TABLE IF NOT EXISTS cards (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        card_number VARCHAR(16) NOT NULL UNIQUE,
        card_holder VARCHAR(100) NOT NULL,
        expiry_month VARCHAR(2) NOT NULL,
        expiry_year VARCHAR(4) NOT NULL,
        cvv VARCHAR(3) NOT NULL,
        type VARCHAR(20) NOT NULL DEFAULT 'visa',
        status VARCHAR(20) DEFAULT 'active',
        limit_amount DECIMAL(12,2) DEFAULT 1000000.00,
        spent_amount DECIMAL(12,2) DEFAULT 0.00,
        is_virtual BOOLEAN NOT NULL DEFAULT false,
        gradient_start VARCHAR(20) DEFAULT '#667eea',
        gradient_end VARCHAR(20) DEFAULT '#764ba2',
        is_default BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    `;

    await pool.query(createCardsTable);

    // Check if card exists
    const checkQuery = 'SELECT * FROM cards WHERE id = $1';
    const checkResult = await pool.query(checkQuery, [cardId]);
    
    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Carte non trouvée'
      });
    }

    // Soft delete by changing status to cancelled
    const updateQuery = 'UPDATE cards SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2';
    await pool.query(updateQuery, ['cancelled', cardId]);

    console.log('Card deleted successfully:', cardId);

    res.json({
      success: true,
      data: {
        message: 'Carte supprimée avec succès'
      }
    });

  } catch (error) {
    console.error('Delete card error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la suppression de la carte'
    });
  }
});

// Get service categories
app.get('/api/service-categories', async (req, res) => {
  try {
    // Create service categories table
    const createServiceCategoriesTable = `
      CREATE TABLE IF NOT EXISTS service_categories (
        id VARCHAR(50) PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        description TEXT,
        icon VARCHAR(50) NOT NULL,
        color VARCHAR(20) NOT NULL,
        is_active BOOLEAN DEFAULT true,
        sort_order INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    await pool.query(createServiceCategoriesTable);

    // Check if categories exist, if not insert default data
    const countQuery = 'SELECT COUNT(*) FROM service_categories';
    const countResult = await pool.query(countQuery);
    
    if (parseInt(countResult.rows[0].count) === 0) {
      // Insert default categories
      const insertCategoriesQuery = `
        INSERT INTO service_categories (id, name, description, icon, color, sort_order) VALUES
        ('cat_telecom', 'Télécommunications', 'Services de téléphonie et communication', 'phone', '#FF6B6B', 1),
        ('cat_internet', 'Internet', 'Services de connexion internet', 'wifi', '#4ECDC4', 2),
        ('cat_streaming', 'Streaming', 'Services de streaming vidéo et musique', 'play_circle', '#45B7D1', 3),
        ('cat_electricity', 'Électricité', 'Services d''électricité', 'bolt', '#FFA07A', 4),
        ('cat_water', 'Eau', 'Services d''approvisionnement en eau', 'water_drop', '#98D8C8', 5),
        ('cat_education', 'Éducation', 'Services éducatifs', 'school', '#F7DC6F', 6),
        ('cat_health', 'Santé', 'Services de santé', 'medical', '#BB8FCE', 7)
      `;
      await pool.query(insertCategoriesQuery);
    }

    const query = `
      SELECT * FROM service_categories 
      WHERE is_active = true 
      ORDER BY sort_order ASC
    `;
    
    const result = await pool.query(query);
    const categories = result.rows.map(cat => ({
      id: cat.id,
      name: cat.name,
      description: cat.description,
      icon: cat.icon,
      color: cat.color,
      isActive: cat.is_active,
      sortOrder: cat.sort_order
    }));

    res.json({
      success: true,
      data: {
        categories: categories
      }
    });

  } catch (error) {
    console.error('Get service categories error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération des catégories de services'
    });
  }
});

// Get services by category
app.get('/api/services', async (req, res) => {
  try {
    const { categoryId } = req.query;
    
    // Create services table
    const createServicesTable = `
      CREATE TABLE IF NOT EXISTS services (
        id VARCHAR(50) PRIMARY KEY,
        category_id VARCHAR(50) NOT NULL,
        name VARCHAR(100) NOT NULL,
        description TEXT NOT NULL,
        icon VARCHAR(50) NOT NULL,
        color VARCHAR(20) NOT NULL,
        price DECIMAL(12,2),
        is_popular BOOLEAN DEFAULT false,
        is_active BOOLEAN DEFAULT true,
        sort_order INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES service_categories(id)
      );
    `;

    await pool.query(createServicesTable);

    // Check if services exist, if not insert default data
    const countQuery = 'SELECT COUNT(*) FROM services';
    const countResult = await pool.query(countQuery);
    
    if (parseInt(countResult.rows[0].count) === 0) {
      // Insert default services based on the image
      const insertServicesQuery = `
        INSERT INTO services (id, category_id, name, description, icon, color, price, is_popular, sort_order) VALUES
        -- Télécommunications
        ('svc_orange', 'cat_telecom', 'Orange', 'Recharge Orange Money', 'phone', '#FF8C00', 1000.00, true, 1),
        ('svc_mtn', 'cat_telecom', 'MTN', 'Recharge MTN Mobile Money', 'phone', '#FFC107', 1000.00, true, 2),
        ('svc_wave', 'cat_telecom', 'Wave', 'Recharge Wave', 'phone', '#7C3AED', 1000.00, false, 3),
        
        -- Internet
        ('svc_orange_internet', 'cat_internet', 'Orange Internet', 'Internet haut débit Orange', 'wifi', '#FF8C00', 25000.00, true, 1),
        ('svc_mtn_internet', 'cat_internet', 'MTN Internet', 'Internet 4G MTN', 'wifi', '#FFC107', 20000.00, false, 2),
        ('svc_wave_internet', 'cat_internet', 'Wave Internet', 'Internet fibre Wave', 'wifi', '#7C3AED', 35000.00, false, 3),
        
        -- Streaming
        ('svc_netflix', 'cat_streaming', 'Netflix', 'Abonnement Netflix Premium', 'play_circle', '#E50914', 35000.00, true, 1),
        ('svc_disney', 'cat_streaming', 'Disney+', 'Abonnement Disney+', 'play_circle', '#113CCF', 28000.00, false, 2),
        ('svc_prime', 'cat_streaming', 'Prime Video', 'Abonnement Amazon Prime', 'play_circle', '#00A8E1', 15000.00, false, 3),
        
        -- Électricité
        ('svc_edg', 'cat_electricity', 'EDG', 'Électricité de Guinée', 'bolt', '#DC143C', 5000.00, true, 1),
        
        -- Eau
        ('svc_seg', 'cat_water', 'SEG', 'Société des Eaux de Guinée', 'water_drop', '#1E90FF', 3000.00, true, 1),
        
        -- Éducation
        ('svc_university', 'cat_education', 'Université', 'Frais d''inscription universitaire', 'school', '#8B4513', 500000.00, false, 1),
        ('svc_school', 'cat_education', 'École Primaire', 'Frais de scolarité', 'school', '#FFD700', 100000.00, false, 2),
        
        -- Santé
        ('svc_hospital', 'cat_health', 'Hôpital', 'Consultation hospitalière', 'medical', '#FF69B4', 25000.00, false, 1),
        ('svc_pharmacy', 'cat_health', 'Pharmacie', 'Achat médicaments', 'medical', '#32CD32', 15000.00, false, 2)
      `;
      await pool.query(insertServicesQuery);
    }

    let query = `
      SELECT s.*, c.name as category_name FROM services s
      JOIN service_categories c ON s.category_id = c.id
      WHERE s.is_active = true
    `;
    
    const params = [];
    
    if (categoryId) {
      query += ' AND s.category_id = $1';
      params.push(categoryId);
    }
    
    query += ' ORDER BY s.sort_order ASC, s.name ASC';
    
    const result = await pool.query(query, params);
    const services = result.rows.map(service => ({
      id: service.id,
      categoryId: service.category_id,
      categoryName: service.category_name,
      name: service.name,
      description: service.description,
      icon: service.icon,
      color: service.color,
      price: parseFloat(service.price) || null,
      isPopular: service.is_popular,
      isActive: service.is_active,
      sortOrder: service.sort_order
    }));

    res.json({
      success: true,
      data: {
        services: services
      }
    });

  } catch (error) {
    console.error('Get services error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération des services'
    });
  }
});

// Subscribe to service
app.post('/api/service-subscriptions', async (req, res) => {
  try {
    const { userId, serviceId, amount, autoRenew = true } = req.body;
    
    if (!userId || !serviceId || !amount) {
      return res.status(400).json({
        success: false,
        error: 'Champs requis: userId, serviceId, amount'
      });
    }

    // Create service subscriptions table
    const createServiceSubscriptionsTable = `
      CREATE TABLE IF NOT EXISTS service_subscriptions (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        service_id VARCHAR(50) NOT NULL,
        status VARCHAR(20) DEFAULT 'active',
        amount DECIMAL(12,2) NOT NULL,
        next_billing_date DATE,
        auto_renew BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (service_id) REFERENCES services(id)
      );
    `;

    await pool.query(createServiceSubscriptionsTable);

    // Create service transactions table
    const createServiceTransactionsTable = `
      CREATE TABLE IF NOT EXISTS service_transactions (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        service_id VARCHAR(50) NOT NULL,
        subscription_id VARCHAR(50),
        amount DECIMAL(12,2) NOT NULL,
        status VARCHAR(20) DEFAULT 'completed',
        payment_method VARCHAR(50),
        transaction_reference VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (service_id) REFERENCES services(id),
        FOREIGN KEY (subscription_id) REFERENCES service_subscriptions(id)
      );
    `;

    await pool.query(createServiceTransactionsTable);

    // Check if user already has subscription to this service
    const existingQuery = 'SELECT * FROM service_subscriptions WHERE user_id = $1 AND service_id = $2 AND status = $3';
    const existingResult = await pool.query(existingQuery, [userId, serviceId, 'active']);
    
    if (existingResult.rows.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Vous êtes déjà abonné à ce service'
      });
    }

    // Generate subscription ID
    const subscriptionId = `sub_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // Calculate next billing date (30 days from now)
    const nextBillingDate = new Date();
    nextBillingDate.setDate(nextBillingDate.getDate() + 30);
    
    // Insert subscription
    const subscriptionQuery = `
      INSERT INTO service_subscriptions (
        id, user_id, service_id, status, amount, next_billing_date, auto_renew
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `;
    
    const subscriptionValues = [
      subscriptionId,
      userId,
      serviceId,
      'active',
      amount,
      nextBillingDate.toISOString().split('T')[0],
      autoRenew
    ];

    const subscriptionResult = await pool.query(subscriptionQuery, subscriptionValues);
    const createdSubscription = subscriptionResult.rows[0];

    // Create transaction for the subscription
    const transactionId = `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const transactionQuery = `
      INSERT INTO service_transactions (
        id, user_id, service_id, subscription_id, amount, status, transaction_reference
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `;
    
    const transactionValues = [
      transactionId,
      userId,
      serviceId,
      subscriptionId,
      amount,
      'completed',
      `SUB_${subscriptionId}`
    ];

    await pool.query(transactionQuery, transactionValues);

    console.log('Service subscription created successfully:', createdSubscription);

    res.json({
      success: true,
      data: {
        id: createdSubscription.id,
        userId: createdSubscription.user_id,
        serviceId: createdSubscription.service_id,
        status: createdSubscription.status,
        amount: parseFloat(createdSubscription.amount),
        nextBillingDate: createdSubscription.next_billing_date,
        autoRenew: createdSubscription.auto_renew,
        createdAt: createdSubscription.created_at
      }
    });

  } catch (error) {
    console.error('Create service subscription error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la création de l\'abonnement'
    });
  }
});

// Get user subscriptions
app.get('/api/service-subscriptions/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'userId requis'
      });
    }

    // Create service subscriptions table
    const createServiceSubscriptionsTable = `
      CREATE TABLE IF NOT EXISTS service_subscriptions (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        service_id VARCHAR(50) NOT NULL,
        status VARCHAR(20) DEFAULT 'active',
        amount DECIMAL(12,2) NOT NULL,
        next_billing_date DATE,
        auto_renew BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (service_id) REFERENCES services(id)
      );
    `;

    await pool.query(createServiceSubscriptionsTable);

    const query = `
      SELECT s.*, sub.id as subscription_id, sub.status as subscription_status, 
             sub.amount as subscription_amount, sub.next_billing_date, sub.auto_renew,
             sub.created_at as subscription_created_at
      FROM service_subscriptions sub
      JOIN services s ON sub.service_id = s.id
      WHERE sub.user_id = $1
      ORDER BY sub.created_at DESC
    `;
    
    const result = await pool.query(query, [userId]);
    const subscriptions = result.rows.map(row => ({
      id: row.subscription_id,
      serviceId: row.service_id,
      serviceName: row.name,
      serviceDescription: row.description,
      serviceIcon: row.icon,
      serviceColor: row.color,
      status: row.subscription_status,
      amount: parseFloat(row.subscription_amount),
      nextBillingDate: row.next_billing_date,
      autoRenew: row.auto_renew,
      createdAt: row.subscription_created_at
    }));

    res.json({
      success: true,
      data: {
        subscriptions: subscriptions
      }
    });

  } catch (error) {
    console.error('Get service subscriptions error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la récupération des abonnements'
    });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Migration function to add missing columns
async function runMigrations() {
  try {
    console.log('Running migrations...');
    
    // Check if id_front_image column exists
    const checkFrontImage = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'id_front_image'
    `);
    
    if (checkFrontImage.rows.length === 0) {
      console.log('Adding id_front_image column...');
      await pool.query(`
        ALTER TABLE users
        ADD COLUMN id_front_image TEXT,
        ADD COLUMN id_back_image TEXT
      `);
      console.log('Columns added successfully');
    } else {
      console.log('Columns already exist');
    }

    // Check and add id_issue_date column
    const checkIdIssueDate = await pool.query(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'id_issue_date'
    `);

    if (checkIdIssueDate.rows.length === 0) {
      console.log('Adding id_issue_date column...');
      await pool.query(`
        ALTER TABLE users
        ADD COLUMN id_issue_date DATE
      `);
      console.log('id_issue_date column added successfully');
    }

    // Check and add id_expiry_date column
    const checkIdExpiryDate = await pool.query(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'id_expiry_date'
    `);

    if (checkIdExpiryDate.rows.length === 0) {
      console.log('Adding id_expiry_date column...');
      await pool.query(`
        ALTER TABLE users
        ADD COLUMN id_expiry_date DATE
      `);
      console.log('id_expiry_date column added successfully');
    }

    // Fix transactions table - recreate with UUID if still VARCHAR
    try {
      const checkType = await pool.query(`
        SELECT data_type FROM information_schema.columns 
        WHERE table_name = 'transactions' AND column_name = 'user_id'
      `);
      
      if (checkType.rows.length > 0 && checkType.rows[0].data_type === 'character varying') {
        console.log('Recreating transactions table with UUID user_id...');
        // Drop and recreate with correct types
        await pool.query(`DROP TABLE IF EXISTS transactions`);
        await pool.query(`
          CREATE TABLE transactions (
            id VARCHAR(50) PRIMARY KEY,
            user_id UUID NOT NULL,
            type VARCHAR(50) NOT NULL,
            amount DECIMAL(12,2) NOT NULL,
            description TEXT NOT NULL,
            recipient VARCHAR(255),
            category VARCHAR(100),
            status VARCHAR(50) DEFAULT 'completed',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        `);
        console.log('Transactions table recreated successfully');
      } else {
        console.log('Transactions table already has correct UUID type');
      }
    } catch (txError) {
      console.log('Note: transactions table check:', txError.message);
    }
    
    // Fix service tables - drop and recreate with proper UUID types
    try {
      console.log('Checking service tables for UUID migration...');
      
      // Check if any service table has wrong types
      const checkServices = await pool.query(`
        SELECT data_type FROM information_schema.columns 
        WHERE table_name = 'services' AND column_name = 'id' LIMIT 1
      `);
      
      if (checkServices.rows.length > 0 && checkServices.rows[0].data_type === 'character varying') {
        console.log('Dropping all service tables with VARCHAR types...');
        await pool.query(`DROP TABLE IF EXISTS service_transactions CASCADE`);
        await pool.query(`DROP TABLE IF EXISTS service_subscriptions CASCADE`);
        await pool.query(`DROP TABLE IF EXISTS services CASCADE`);
        await pool.query(`DROP TABLE IF EXISTS service_categories CASCADE`);
        console.log('All service tables dropped - will be recreated with UUID on next save');
      } else {
        console.log('Service tables already have correct UUID types or do not exist');
      }
    } catch (svcError) {
      console.log('Note: service tables check:', svcError.message);
    }
    
    // Create user_contacts table for storing transfer contacts
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS user_contacts (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          contact_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
          phone VARCHAR(20) NOT NULL,
          name VARCHAR(255),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(user_id, phone)
        )
      `);
      console.log('Table user_contacts checked/created');
    } catch (contactError) {
      console.log('Note: user_contacts table check:', contactError.message);
    }

    console.log('Migrations completed');
  } catch (error) {
    console.error('Migration error:', error);
  }
}

httpServer.listen(PORT, async () => {
  console.log(`UBAY Simple API running on port ${PORT}`);
  console.log(`WebSocket server active on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);

  // Run migrations
  await runMigrations();
  
  // Initialize MinIO
  await initializeMinIO();
});

// ========================================
// TRANSFER ENDPOINT - Transfer between users
// ========================================
app.post('/api/transfer', async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { senderId, recipientPhone, amount, description } = req.body;
    
    if (!senderId || !recipientPhone || !amount) {
      return res.status(400).json({
        success: false,
        error: 'senderId, recipientPhone et amount sont requis'
      });
    }
    
    const transferAmount = parseFloat(amount);
    if (isNaN(transferAmount) || transferAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Le montant doit être un nombre positif'
      });
    }
    
    // Start transaction
    await client.query('BEGIN');
    
    // 1. Get sender and check balance
    const senderQuery = 'SELECT * FROM users WHERE id = $1';
    const senderResult = await client.query(senderQuery, [senderId]);
    
    if (senderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Expéditeur non trouvé'
      });
    }
    
    const sender = senderResult.rows[0];
    const senderBalance = parseFloat(sender.balance);
    
    if (senderBalance < transferAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        error: 'Solde insuffisant'
      });
    }
    
    // 2. Find recipient by phone
    const recipientQuery = 'SELECT * FROM users WHERE phone = $1';
    const recipientResult = await client.query(recipientQuery, [recipientPhone]);
    
    if (recipientResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Destinataire non trouvé avec ce numéro de téléphone'
      });
    }
    
    const recipient = recipientResult.rows[0];
    
    // 3. Debit sender
    const newSenderBalance = senderBalance - transferAmount;
    await client.query(
      'UPDATE users SET balance = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newSenderBalance, senderId]
    );
    
    // 4. Credit recipient
    const recipientBalance = parseFloat(recipient.balance);
    const newRecipientBalance = recipientBalance + transferAmount;
    await client.query(
      'UPDATE users SET balance = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newRecipientBalance, recipient.id]
    );
    
    // 5. Create transaction for sender (transfer_out)
    const senderTxId = `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    await client.query(
      `INSERT INTO transactions (id, user_id, type, amount, description, recipient, category, status, created_at)
       VALUES ($1, $2, 'transfer', $3, $4, $5, 'transfer', 'completed', CURRENT_TIMESTAMP)`,
      [senderTxId, senderId, transferAmount, description || 'Transfert envoyé', recipientPhone]
    );
    
    // 6. Create transaction for recipient (transfer_in)
    const recipientTxId = `tx_${Date.now() + 1}_${Math.random().toString(36).substr(2, 9)}`;
    await client.query(
      `INSERT INTO transactions (id, user_id, type, amount, description, recipient, category, status, created_at)
       VALUES ($1, $2, 'deposit', $3, $4, $5, 'receive', 'completed', CURRENT_TIMESTAMP)`,
      [recipientTxId, recipient.id, transferAmount, `Reçu de ${sender.first_name} ${sender.last_name}`, sender.phone]
    );
    
    // Commit transaction
    await client.query('COMMIT');

    // WebSocket notifications
    try {
      const senderName = `${senderResult.rows[0].first_name} ${senderResult.rows[0].last_name}`;
      const recipientFullName = `${recipient.first_name} ${recipient.last_name}`;

      // Notify sender of their transaction
      notifyUserTransaction(senderId, {
        id: senderTxId,
        type: 'transfer_sent',
        amount: -transferAmount,
        description: `Transfert à ${recipientFullName}`,
        recipient: recipientPhone,
        recipientName: recipientFullName,
        newBalance: newSenderBalance,
        createdAt: new Date().toISOString()
      });

      // Notify recipient of incoming transfer
      notifyUserTransaction(recipient.id, {
        id: recipientTxId,
        type: 'transfer_received',
        amount: transferAmount,
        description: `Reçu de ${senderName}`,
        sender: senderResult.rows[0].phone,
        senderName: senderName,
        newBalance: newRecipientBalance,
        createdAt: new Date().toISOString()
      });

      // Send balance updates
      notifyBalanceUpdate(senderId, newSenderBalance);
      notifyBalanceUpdate(recipientUser.id, newRecipientBalance);

      console.log('[Transfer] WebSocket notifications sent');
    } catch (wsError) {
      console.error('[Transfer] WebSocket notification error (non-critical):', wsError);
    }

    // Add to user_contacts
    try {
      await pool.query(
        `INSERT INTO user_contacts (user_id, contact_user_id, phone, name)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (user_id, phone) DO UPDATE SET
           contact_user_id = COALESCE(EXCLUDED.contact_user_id, user_contacts.contact_user_id),
           name = COALESCE(EXCLUDED.name, user_contacts.name)`,
        [
          senderId,
          recipient.id,
          recipientPhone,
          `${recipient.first_name} ${recipient.last_name}`
        ]
      );
      console.log('[Transfer] Contact saved/updated');
    } catch (contactError) {
      console.log('[Transfer] Contact save error (non-critical):', contactError.message);
    }

    res.json({
      success: true,
      message: 'Transfert effectué avec succès',
      data: {
        senderNewBalance: newSenderBalance,
        recipientNewBalance: newRecipientBalance,
        amount: transferAmount,
        senderTxId: senderTxId,
        recipientTxId: recipientTxId
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Transfer error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du transfert'
    });
  } finally {
    client.release();
  }
});

// ========================================
// GET RECENT BENEFICIARIES - Users who received transfers
// ========================================
app.get('/api/beneficiaries/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'userId est requis'
      });
    }
    
    // Get unique recipients from transfer transactions
    const query = `
      SELECT DISTINCT
        t.recipient as phone,
        MAX(t.created_at) as last_transfer_date,
        COUNT(*) as transfer_count
      FROM transactions t
      WHERE t.user_id = $1
        AND t.type = 'transfer'
        AND t.recipient IS NOT NULL
      GROUP BY t.recipient
      ORDER BY MAX(t.created_at) DESC
      LIMIT 10
    `;
    
    const result = await pool.query(query, [userId]);
    
    // Also get user details for each beneficiary
    const beneficiaries = [];
    for (const row of result.rows) {
      // Check if recipient has an account
      const userQuery = 'SELECT id, first_name, last_name, phone, photo_url FROM users WHERE phone = $1';
      const userResult = await pool.query(userQuery, [row.phone]);
      
      const userName = userResult.rows.length > 0
        ? `${userResult.rows[0].first_name} ${userResult.rows[0].last_name}`
        : row.phone;

      beneficiaries.push({
        phone: row.phone,
        name: userName,
        lastTransferDate: row.last_transfer_date,
        transferCount: parseInt(row.transfer_count),
        hasAccount: userResult.rows.length > 0,
        user: userResult.rows.length > 0 ? {
          id: userResult.rows[0].id,
          firstName: userResult.rows[0].first_name,
          lastName: userResult.rows[0].last_name,
          phone: userResult.rows[0].phone,
          photoUrl: userResult.rows[0].photo_url
        } : null
      });
    }
    
    res.json({
      success: true,
      data: {
        beneficiaries: beneficiaries
      }
    });
    
  } catch (error) {
    console.error('Get beneficiaries error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des bénéficiaires'
    });
  }
});

// ========================================
// GET USER CONTACTS - Contacts for transfers
// ========================================
app.get('/api/contacts/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const query = `
      SELECT 
        uc.id,
        uc.phone,
        uc.name,
        uc.contact_user_id,
        uc.created_at,
        u.first_name,
        u.last_name,
        u.photo_url,
        u.phone as user_phone
      FROM user_contacts uc
      LEFT JOIN users u ON uc.contact_user_id = u.id
      WHERE uc.user_id = $1
      ORDER BY uc.created_at DESC
    `;

    const result = await pool.query(query, [userId]);

    const contacts = result.rows.map(row => ({
      id: row.id,
      phone: row.phone,
      name: row.name || `${row.first_name || ''} ${row.last_name || ''}`.trim() || row.phone,
      contactUserId: row.contact_user_id,
      hasAccount: !!row.contact_user_id,
      photoUrl: row.photo_url,
      createdAt: row.created_at
    }));

    res.json({
      success: true,
      data: { contacts }
    });

  } catch (error) {
    console.error('Get contacts error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des contacts'
    });
  }
});

// ========================================
// DEPOSIT ENDPOINT - Credit user balance
// ========================================
app.post('/api/deposit', async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { userId, amount, description, paymentMethod } = req.body;
    
    if (!userId || !amount) {
      return res.status(400).json({
        success: false,
        error: 'userId et amount sont requis'
      });
    }
    
    const depositAmount = parseFloat(amount);
    if (isNaN(depositAmount) || depositAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Le montant doit être un nombre positif'
      });
    }
    
    // Start transaction
    await client.query('BEGIN');
    
    // 1. Get user
    const userQuery = 'SELECT * FROM users WHERE id = $1';
    const userResult = await client.query(userQuery, [userId]);
    
    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Utilisateur non trouvé'
      });
    }
    
    const user = userResult.rows[0];
    const currentBalance = parseFloat(user.balance);
    
    // 2. Credit user balance
    const newBalance = currentBalance + depositAmount;
    await client.query(
      'UPDATE users SET balance = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newBalance, userId]
    );
    
    // 3. Create transaction record
    const txId = `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    await client.query(
      `INSERT INTO transactions (id, user_id, type, amount, description, recipient, category, status, created_at)
       VALUES ($1, $2, 'deposit', $3, $4, $5, 'deposit', 'completed', CURRENT_TIMESTAMP)`,
      [txId, userId, depositAmount, description || 'Dépôt', paymentMethod || 'Carte']
    );
    
    // Commit transaction
    await client.query('COMMIT');
    
    res.json({
      success: true,
      message: 'Dépôt effectué avec succès',
      data: {
        newBalance: newBalance,
        amount: depositAmount,
        transactionId: txId
      }
    });
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Deposit error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du dépôt'
    });
  } finally {
    client.release();
  }
});

// ========================================
// AIRTIME/WITHDRAWAL ENDPOINT - Debit user balance
// ========================================
app.post('/api/debit', async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { userId, amount, description, category, recipient } = req.body;
    
    if (!userId || !amount) {
      return res.status(400).json({
        success: false,
        error: 'userId et amount sont requis'
      });
    }
    
    const debitAmount = parseFloat(amount);
    if (isNaN(debitAmount) || debitAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Le montant doit être un nombre positif'
      });
    }
    
    // Start transaction
    await client.query('BEGIN');
    
    // 1. Get user and check balance
    const userQuery = 'SELECT * FROM users WHERE id = $1';
    const userResult = await client.query(userQuery, [userId]);
    
    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Utilisateur non trouvé'
      });
    }
    
    const user = userResult.rows[0];
    const currentBalance = parseFloat(user.balance);
    
    // Check sufficient balance
    if (currentBalance < debitAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        error: 'Solde insuffisant'
      });
    }
    
    // 2. Debit user balance
    const newBalance = currentBalance - debitAmount;
    await client.query(
      'UPDATE users SET balance = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newBalance, userId]
    );
    
    // 3. Create transaction record
    const txId = `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const txType = category === 'airtime' ? 'airtime' : 'withdrawal';
    await client.query(
      `INSERT INTO transactions (id, user_id, type, amount, description, recipient, category, status, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'completed', CURRENT_TIMESTAMP)`,
      [txId, userId, txType, debitAmount, description || 'Débit', recipient || '', category || 'debit']
    );
    
    // Commit transaction
    await client.query('COMMIT');
    
    res.json({
      success: true,
      message: 'Débit effectué avec succès',
      data: {
        newBalance: newBalance,
        amount: debitAmount,
        transactionId: txId
      }
    });
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Debit error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du débit'
    });
  } finally {
    client.release();
  }
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully');
  await pool.end();
  process.exit(0);
});
