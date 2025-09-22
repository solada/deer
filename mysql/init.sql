-- 创建数据库（如果不存在）
CREATE DATABASE IF NOT EXISTS deer_forum CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE deer_forum;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    password VARCHAR(255) NOT NULL COMMENT '密码（加密后）',
    email VARCHAR(100) NOT NULL UNIQUE COMMENT '邮箱',
    nickname VARCHAR(50) NOT NULL COMMENT '昵称',
    avatar_url VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 帖子表
CREATE TABLE IF NOT EXISTS posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT '发帖用户ID',
    title VARCHAR(200) NOT NULL COMMENT '帖子标题',
    content TEXT NOT NULL COMMENT '帖子内容',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    like_count INT DEFAULT 0 COMMENT '点赞次数',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_title (title),
    FULLTEXT idx_content (content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子表';

-- 评论表
CREATE TABLE IF NOT EXISTS comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL COMMENT '帖子ID',
    user_id INT NOT NULL COMMENT '评论用户ID',
    content TEXT NOT NULL COMMENT '评论内容',
    reply_to_comment_id INT DEFAULT NULL COMMENT '回复的评论ID（如果是回复评论）',
    reply_to_user_id INT DEFAULT NULL COMMENT '回复的用户ID（如果是回复评论）',
    like_count INT DEFAULT 0 COMMENT '点赞次数',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reply_to_comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    FOREIGN KEY (reply_to_user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_post_id (post_id),
    INDEX idx_user_id (user_id),
    INDEX idx_reply_to_comment_id (reply_to_comment_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论表';

-- 点赞表（用于记录用户对帖子或评论的点赞）
CREATE TABLE IF NOT EXISTS likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT '点赞用户ID',
    target_type ENUM('post', 'comment') NOT NULL COMMENT '点赞目标类型',
    target_id INT NOT NULL COMMENT '点赞目标ID（帖子ID或评论ID）',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '点赞时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_target (user_id, target_type, target_id),
    INDEX idx_target (target_type, target_id),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='点赞表';

-- 插入示例数据
INSERT INTO users (username, password, email, nickname) VALUES 
('admin', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj2B8J9UgzTO', 'admin@deerlulu1008.cn', '管理员'),
('testuser', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj2B8J9UgzTO', 'test@deerlulu1008.cn', '测试用户');
-- 注意：以上密码为 'password123' 的加密结果

INSERT INTO posts (user_id, title, content) VALUES 
(1, '欢迎来到鹿鹿论坛', '这是第一个帖子，欢迎大家在这里分享和交流！'),
(2, '测试发帖功能', '这是一个测试帖子，用来验证发帖功能是否正常工作。');

INSERT INTO comments (post_id, user_id, content) VALUES 
(1, 2, '谢谢管理员！论坛看起来很不错。'),
(1, 1, '欢迎大家多多交流！'),
(2, 1, '测试功能运行正常。');

-- 为性能优化添加一些额外的索引
ALTER TABLE posts ADD INDEX idx_user_created (user_id, created_at);
ALTER TABLE comments ADD INDEX idx_post_created (post_id, created_at);

-- 设置字符集确保支持emoji等特殊字符
ALTER DATABASE deer_forum CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
