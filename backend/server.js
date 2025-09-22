const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件配置
app.set('trust proxy', 1); // 信任第一个代理（Nginx）
app.use(helmet());
app.use(cors({
  origin: ['https://deerlulu1008.cn', 'https://www.deerlulu1008.cn'],
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 限流配置
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 100, // 每个IP最多100个请求
  message: { error: '请求过于频繁，请稍后再试' }
});
app.use('/api/', limiter);

// 数据库连接配置
const dbConfig = {
  host: process.env.DB_HOST || 'mysql',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'deeruser',
  password: process.env.DB_PASSWORD || 'deer123456',
  database: process.env.DB_NAME || 'deer_forum',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

let pool;

// 初始化数据库连接
async function initDatabase() {
  try {
    pool = mysql.createPool(dbConfig);
    console.log('数据库连接池创建成功');
    
    // 测试连接
    const connection = await pool.getConnection();
    console.log('数据库连接测试成功');
    connection.release();
  } catch (error) {
    console.error('数据库连接失败:', error);
    process.exit(1);
  }
}

// JWT 验证中间件
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: '未提供访问令牌' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'deer_jwt_secret_key_2024', (err, user) => {
    if (err) {
      return res.status(403).json({ error: '无效的访问令牌' });
    }
    req.user = user;
    next();
  });
};

// 用户注册
app.post('/api/register', [
  body('username').isLength({ min: 3, max: 20 }).withMessage('用户名长度必须在3-20字符之间'),
  body('password').isLength({ min: 6 }).withMessage('密码长度至少6字符'),
  body('email').isEmail().withMessage('请输入有效的邮箱地址')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg });
    }

    const { username, password, email, nickname } = req.body;

    // 检查用户是否已存在
    const [existingUsers] = await pool.execute(
      'SELECT id FROM users WHERE username = ? OR email = ?',
      [username, email]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({ error: '用户名或邮箱已存在' });
    }

    // 加密密码
    const hashedPassword = await bcrypt.hash(password, 12);

    // 创建用户
    const [result] = await pool.execute(
      'INSERT INTO users (username, password, email, nickname, created_at) VALUES (?, ?, ?, ?, NOW())',
      [username, hashedPassword, email, nickname || username]
    );

    // 生成JWT令牌
    const token = jwt.sign(
      { userId: result.insertId, username },
      process.env.JWT_SECRET || 'deer_jwt_secret_key_2024',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: '注册成功',
      token,
      user: {
        id: result.insertId,
        username,
        nickname: nickname || username,
        email
      }
    });
  } catch (error) {
    console.error('注册错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 用户登录
app.post('/api/login', [
  body('username').notEmpty().withMessage('用户名不能为空'),
  body('password').notEmpty().withMessage('密码不能为空')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg });
    }

    const { username, password } = req.body;

    // 查找用户
    const [users] = await pool.execute(
      'SELECT id, username, password, nickname, email FROM users WHERE username = ? OR email = ?',
      [username, username]
    );

    if (users.length === 0) {
      return res.status(400).json({ error: '用户名或密码错误' });
    }

    const user = users[0];

    // 验证密码
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(400).json({ error: '用户名或密码错误' });
    }

    // 生成JWT令牌
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      process.env.JWT_SECRET || 'deer_jwt_secret_key_2024',
      { expiresIn: '7d' }
    );

    res.json({
      message: '登录成功',
      token,
      user: {
        id: user.id,
        username: user.username,
        nickname: user.nickname,
        email: user.email
      }
    });
  } catch (error) {
    console.error('登录错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 获取帖子列表
app.get('/api/posts', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const [posts] = await pool.execute(`
      SELECT p.*, u.username, u.nickname,
             (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) as comment_count
      FROM posts p 
      JOIN users u ON p.user_id = u.id 
      ORDER BY p.created_at DESC 
      LIMIT ? OFFSET ?
    `, [limit.toString(), offset.toString()]);

    const [totalResult] = await pool.execute('SELECT COUNT(*) as total FROM posts');
    const total = totalResult[0].total;

    res.json({
      posts,
      pagination: {
        current_page: page,
        per_page: limit,
        total,
        total_pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('获取帖子列表错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 发布帖子
app.post('/api/posts', authenticateToken, [
  body('title').isLength({ min: 1, max: 200 }).withMessage('标题长度必须在1-200字符之间'),
  body('content').isLength({ min: 1, max: 10000 }).withMessage('内容长度必须在1-10000字符之间')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg });
    }

    const { title, content } = req.body;
    const userId = req.user.userId;

    const [result] = await pool.execute(
      'INSERT INTO posts (user_id, title, content, created_at) VALUES (?, ?, ?, NOW())',
      [userId, title, content]
    );

    // 获取刚创建的帖子信息
    const [newPost] = await pool.execute(`
      SELECT p.*, u.username, u.nickname 
      FROM posts p 
      JOIN users u ON p.user_id = u.id 
      WHERE p.id = ?
    `, [result.insertId]);

    res.status(201).json({
      message: '发帖成功',
      post: newPost[0]
    });
  } catch (error) {
    console.error('发帖错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 删除帖子
app.delete('/api/posts/:id', authenticateToken, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.userId;

    // 检查帖子是否存在并且是否为帖子作者
    const [posts] = await pool.execute(
      'SELECT id, user_id FROM posts WHERE id = ?',
      [postId]
    );

    if (posts.length === 0) {
      return res.status(404).json({ error: '帖子不存在' });
    }

    if (posts[0].user_id !== userId) {
      return res.status(403).json({ error: '只能删除自己的帖子' });
    }

    // 删除帖子（由于外键约束，相关评论也会被删除）
    await pool.execute('DELETE FROM posts WHERE id = ?', [postId]);

    res.json({ message: '帖子删除成功' });
  } catch (error) {
    console.error('删除帖子错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 获取帖子详情和评论
app.get('/api/posts/:id', async (req, res) => {
  try {
    const postId = req.params.id;

    // 获取帖子详情
    const [posts] = await pool.execute(`
      SELECT p.*, u.username, u.nickname 
      FROM posts p 
      JOIN users u ON p.user_id = u.id 
      WHERE p.id = ?
    `, [postId]);

    if (posts.length === 0) {
      return res.status(404).json({ error: '帖子不存在' });
    }

    // 获取评论（包括回复）
    const [comments] = await pool.execute(`
      SELECT c.*, u.username, u.nickname,
             ru.username as reply_to_username, ru.nickname as reply_to_nickname
      FROM comments c 
      JOIN users u ON c.user_id = u.id 
      LEFT JOIN users ru ON c.reply_to_user_id = ru.id
      WHERE c.post_id = ? 
      ORDER BY c.created_at ASC
    `, [postId]);

    res.json({
      post: posts[0],
      comments
    });
  } catch (error) {
    console.error('获取帖子详情错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 发表评论
app.post('/api/posts/:id/comments', authenticateToken, [
  body('content').isLength({ min: 1, max: 1000 }).withMessage('评论内容长度必须在1-1000字符之间')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg });
    }

    const postId = req.params.id;
    const { content, reply_to_comment_id, reply_to_user_id } = req.body;
    const userId = req.user.userId;

    // 检查帖子是否存在
    const [posts] = await pool.execute('SELECT id FROM posts WHERE id = ?', [postId]);
    if (posts.length === 0) {
      return res.status(404).json({ error: '帖子不存在' });
    }

    const [result] = await pool.execute(
      'INSERT INTO comments (post_id, user_id, content, reply_to_comment_id, reply_to_user_id, created_at) VALUES (?, ?, ?, ?, ?, NOW())',
      [postId, userId, content, reply_to_comment_id || null, reply_to_user_id || null]
    );

    // 获取刚创建的评论信息
    const [newComment] = await pool.execute(`
      SELECT c.*, u.username, u.nickname,
             ru.username as reply_to_username, ru.nickname as reply_to_nickname
      FROM comments c 
      JOIN users u ON c.user_id = u.id 
      LEFT JOIN users ru ON c.reply_to_user_id = ru.id
      WHERE c.id = ?
    `, [result.insertId]);

    res.status(201).json({
      message: '评论成功',
      comment: newComment[0]
    });
  } catch (error) {
    console.error('评论错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 健康检查接口
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: '服务正常运行',
    timestamp: new Date().toISOString()
  });
});

// 404处理
app.use('*', (req, res) => {
  res.status(404).json({ error: '接口不存在' });
});

// 错误处理中间件
app.use((error, req, res, next) => {
  console.error('未处理的错误:', error);
  res.status(500).json({ error: '服务器内部错误' });
});

// 启动服务器
async function startServer() {
  await initDatabase();
  
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`服务器运行在端口 ${PORT}`);
    console.log(`环境: ${process.env.NODE_ENV || 'development'}`);
  });
}

startServer().catch(console.error);
