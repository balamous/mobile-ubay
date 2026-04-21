const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const { Pool } = require('pg');
const redis = require('redis');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Joi = require('joi');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.API_PORT || 3000;

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080'],
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Redis connection
const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://redis:6379'
});

redisClient.on('error', (err) => console.log('Redis Client Error', err));
redisClient.connect();

// Health check
app.get('/health', async (req, res) => {
  try {
    const dbResult = await pool.query('SELECT NOW()');
    const redisResult = await redisClient.ping();
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: dbResult.rows[0].now,
      redis: redisResult === 'PONG' ? 'connected' : 'disconnected'
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// Validation schemas
const userSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  firstName: Joi.string().min(2).required(),
  lastName: Joi.string().min(2).required(),
  phone: Joi.string().pattern(/^[0-9]+$/).min(9).required()
});

const transactionSchema = Joi.object({
  type: Joi.string().valid('deposit', 'withdrawal', 'transfer', 'payment', 'topup', 'airtime').required(),
  amount: Joi.number().positive().required(),
  description: Joi.string().min(3).required(),
  recipient: Joi.string().optional()
});

// Routes

// Authentication
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);
    
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    // Cache user data in Redis
    await redisClient.setEx(`user:${user.id}`, 3600, JSON.stringify({
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      phone: user.phone,
      balance: user.balance
    }));
    
    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        phone: user.phone,
        balance: user.balance
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/auth/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName, phone } = req.body;
    
    const { error } = userSchema.validate({ email, password, firstName, lastName, phone });
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    // Check if user exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1 OR phone = $2',
      [email, phone]
    );
    
    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: 'User already exists' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    const accountNumber = `GN${Date.now().toString().slice(5)}`;
    
    const result = await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name, phone, account_number, balance, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
       RETURNING id, email, first_name, last_name, phone, account_number, balance`,
      [userId, email, hashedPassword, firstName, lastName, phone, accountNumber, 0]
    );
    
    const token = jwt.sign(
      { userId, email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.status(201).json({
      token,
      user: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Users
app.get('/users/profile', authenticateToken, async (req, res) => {
  try {
    const cachedUser = await redisClient.get(`user:${req.user.userId}`);
    
    if (cachedUser) {
      return res.json(JSON.parse(cachedUser));
    }
    
    const result = await pool.query(
      `SELECT id, email, first_name, last_name, phone, balance, savings_balance, 
              account_number, is_verified, kyc_level, created_at
       FROM users WHERE id = $1`,
      [req.user.userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = result.rows[0];
    await redisClient.setEx(`user:${req.user.userId}`, 3600, JSON.stringify(user));
    
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Transactions
app.get('/transactions', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20, type, status } = req.query;
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT id, type, status, amount, description, recipient, 
             reference, category, is_credit, date
      FROM transactions 
      WHERE user_id = $1
    `;
    const params = [req.user.userId];
    
    if (type) {
      query += ` AND type = $${params.length + 1}`;
      params.push(type);
    }
    
    if (status) {
      query += ` AND status = $${params.length + 1}`;
      params.push(status);
    }
    
    query += ` ORDER BY date DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);
    
    const result = await pool.query(query, params);
    
    // Get total count
    const countQuery = `
      SELECT COUNT(*) as total 
      FROM transactions 
      WHERE user_id = $1
    `;
    const countParams = [req.user.userId];
    
    if (type) {
      countQuery += ` AND type = $${countParams.length + 1}`;
      countParams.push(type);
    }
    
    if (status) {
      countQuery += ` AND status = $${countParams.length + 1}`;
      countParams.push(status);
    }
    
    const countResult = await pool.query(countQuery, countParams);
    
    res.json({
      transactions: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(countResult.rows[0].total),
        pages: Math.ceil(countResult.rows[0].total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/transactions', authenticateToken, async (req, res) => {
  try {
    const { type, amount, description, recipient, category } = req.body;
    
    const { error } = transactionSchema.validate({ type, amount, description, recipient });
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    const transactionId = uuidv4();
    const reference = `${type.toUpperCase()}${Date.now()}`;
    const isCredit = type === 'deposit';
    
    // Start transaction
    await pool.query('BEGIN');
    
    try {
      // Create transaction
      const result = await pool.query(
        `INSERT INTO transactions (id, user_id, type, status, amount, description, recipient, reference, category, is_credit, date)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
         RETURNING *`,
        [transactionId, req.user.userId, type, 'completed', amount, description, recipient, reference, category, isCredit]
      );
      
      // Update user balance
      const balanceUpdate = isCredit 
        ? `balance = balance + $1`
        : `balance = balance - $1`;
      
      await pool.query(
        `UPDATE users SET ${balanceUpdate} WHERE id = $2`,
        [amount, req.user.userId]
      );
      
      await pool.query('COMMIT');
      
      // Invalidate user cache
      await redisClient.del(`user:${req.user.userId}`);
      
      res.status(201).json(result.rows[0]);
    } catch (error) {
      await pool.query('ROLLBACK');
      throw error;
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Cards
app.get('/cards', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, card_number, card_holder, expiry_month, expiry_year, 
              card_type, status, limit, spent, is_virtual, gradient_start, gradient_end
       FROM cards 
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.user.userId]
    );
    
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Services
app.get('/services', async (req, res) => {
  try {
    const { category, popular } = req.query;
    
    let query = `
      SELECT id, name, description, icon_path, category, is_popular, fixed_amount, color
      FROM services
      WHERE 1=1
    `;
    const params = [];
    
    if (category) {
      query += ` AND category = $${params.length + 1}`;
      params.push(category);
    }
    
    if (popular === 'true') {
      query += ` AND is_popular = true`;
    }
    
    query += ` ORDER BY name`;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Operators
app.get('/operators', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, logo_path, color, country
       FROM operators
       ORDER BY name`
    );
    
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Payment Methods
app.get('/payment-methods', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, logo_path, color, type
       FROM payment_methods
       ORDER BY name`
    );
    
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`UBAY API Server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Database: ${process.env.DATABASE_URL ? 'Connected' : 'Not configured'}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  
  await pool.end();
  await redisClient.quit();
  
  server.close(() => {
    console.log('Process terminated');
  });
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully');
  
  await pool.end();
  await redisClient.quit();
  
  process.exit(0);
});
