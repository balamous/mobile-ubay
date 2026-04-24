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
        cvv, card_type, is_default, is_active, balance, limit_amount, 
        created_at, updated_at, type, status, spent_amount, is_virtual, 
        gradient_start, gradient_end
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $13, $14, $15, $16, $17, $18
      )
      RETURNING *
    `;
    
    const values = [
      cardId,                                    // $1: id
      userId,                                    // $2: user_id
      cardNumber,                                // $3: card_number
      cardHolderName,                            // $4: card_holder
      parseInt(expiryMonth),                     // $5: expiry_month
      parseInt(expiryYear),                      // $6: expiry_year
      cvv,                                       // $7: cvv
      type,                                      // $8: card_type
      false,                                     // $9: is_default
      true,                                      // $10: is_active
      0.00,                                      // $11: balance
      1000000.00,                                // $12: limit_amount
      type,                                      // $13: type
      'active',                                  // $14: status
      0.00,                                      // $15: spent_amount
      isVirtual || false,                        // $16: is_virtual
      formatGradient(gradientStart || selectedGradient.start),   // $17: gradient_start
      formatGradient(gradientEnd || selectedGradient.end)        // $18: gradient_end
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
