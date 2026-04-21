const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.API_PORT || 3000;

// Middleware
app.use(cors({
  origin: ['http://localhost:8080', 'http://localhost:8081', 'http://127.0.0.1:8080', 'http://127.0.0.1:8081'],
  credentials: true
}));
app.use(express.json());

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://fintech_admin:fintech_password_2024@db:5432/fintech_db',
});

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

// Get user profile endpoint
app.get('/users/profile', async (req, res) => {
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
        user_id VARCHAR(50) NOT NULL,
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
    const cardId = `card_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const cardNumber = Math.random().toString().slice(2, 18).padStart(16, '0');
    const expiryMonth = String(Math.floor(Math.random() * 12) + 1).padStart(2, '0');
    const expiryYear = String(new Date().getFullYear() + 4);
    const cvv = Math.random().toString().slice(2, 5).padStart(3, '0');
    
    // Default gradients based on card type
    const defaultGradients = {
      visa: { start: '#667eea', end: '#764ba2' },
      mastercard: { start: '#f093fb', end: '#f5576c' }
    };

    const selectedGradient = defaultGradients[type] || defaultGradients.visa;

    // Insert card into database
    const query = `
      INSERT INTO cards (
        id, user_id, card_number, card_holder, expiry_month, expiry_year, 
        cvv, type, is_virtual, gradient_start, gradient_end, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      RETURNING *
    `;
    
    const values = [
      cardId,
      userId,
      cardNumber,
      cardHolderName,
      expiryMonth,
      expiryYear,
      cvv,
      type,
      isVirtual || false,
      gradientStart || selectedGradient.start,
      gradientEnd || selectedGradient.end
    ];

    const result = await pool.query(query, values);
    const createdCard = result.rows[0];

    console.log('Card created successfully:', createdCard);

    res.json({
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

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`UBAY Simple API running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
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
