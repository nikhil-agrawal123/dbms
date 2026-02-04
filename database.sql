CREATE DATABASE dbms_project;
USE dbms_project;

-- ============================================
-- ENTITY: USERS
-- ============================================
CREATE TABLE users(
    uid INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL UNIQUE,
    user_contact JSON NOT NULL,
    password VARCHAR(255) NOT NULL,
    metadata JSON NOT NULL,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)ENGINE=InnoDB;

-- ============================================
-- ENTITY: CLUSTERS
-- ============================================
CREATE TABLE clusters(
    cid INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    data JSON NOT NULL,
    settings JSON NOT NULL,
    metadata JSON NOT NULL,
    creator_uid INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (creator_uid) REFERENCES users(uid) ON DELETE SET NULL ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- ENTITY: WINDOW
-- ============================================
CREATE TABLE windowp(
    wid INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    parameters JSON NOT NULL,
    metadata JSON NOT NULL,
    origin_data JSON NOT NULL,
    creator_uid INT,
    cluster_cid INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cluster_cid) REFERENCES clusters(cid) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (creator_uid) REFERENCES users(uid) ON DELETE SET NULL ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- ENTITY: POSTS
-- ============================================
CREATE TABLE posts(
    pid INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    author_uid INT,
    cluster_cid INT,
    metadata JSON NOT NULL,
    context JSON,
    engagement JSON NOT NULL,
    lifecycle_status JSON NOT NULL,
    -- References: Post can reference another post or window
    ref_post_pid INT DEFAULT NULL,
    ref_window_wid INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_uid) REFERENCES users(uid) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (cluster_cid) REFERENCES clusters(cid) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ref_post_pid) REFERENCES posts(pid) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (ref_window_wid) REFERENCES windowp(wid) ON DELETE SET NULL ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- ENTITY: COMMENTS (with self-referencing for parent/child)
-- ============================================
CREATE TABLE comments(
    cmid INT PRIMARY KEY AUTO_INCREMENT,
    content TEXT NOT NULL,
    author_uid INT,
    post_pid INT,
    cluster_cid INT,
    parent_cmid INT DEFAULT NULL,  -- Self-referencing for nested comments (parent/new)
    metadata JSON NOT NULL,
    engagement JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_uid) REFERENCES users(uid) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (post_pid) REFERENCES posts(pid) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (cluster_cid) REFERENCES clusters(cid) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (parent_cmid) REFERENCES comments(cmid) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- ENTITY: MEGAPHONE
-- ============================================
CREATE TABLE megaphone(
    mgid INT PRIMARY KEY AUTO_INCREMENT,
    message TEXT NOT NULL,
    data JSON NOT NULL,
    sender_uid INT,
    cluster_cid INT,
    metadata JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_uid) REFERENCES users(uid) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (cluster_cid) REFERENCES clusters(cid) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- ENTITY: RULES
-- Rules that are enforced within clusters
-- ============================================
CREATE TABLE rules(
    rid INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    cluster_cid INT NOT NULL,
    priority INT DEFAULT 0,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cluster_cid) REFERENCES clusters(cid) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- RELATIONSHIP: USER REACTS TO POST (Many-to-Many)
-- ============================================
CREATE TABLE user_reacts_post(
    uid INT NOT NULL,
    pid INT NOT NULL,
    reaction_type VARCHAR(50) NOT NULL,  -- like, love, angry, etc.
    reacted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (uid, pid),
    FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (pid) REFERENCES posts(pid) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- RELATIONSHIP: USER REACTS TO COMMENT (Many-to-Many)
-- ============================================
CREATE TABLE user_reacts_comment(
    uid INT NOT NULL,
    cmid INT NOT NULL,
    reaction_type VARCHAR(50) NOT NULL,  -- like, love, angry, etc.
    reacted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (uid, cmid),
    FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (cmid) REFERENCES comments(cmid) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- RELATIONSHIP: USER JOINS CLUSTER (Many-to-Many)
-- Users can join multiple clusters
-- ============================================
CREATE TABLE user_joins_cluster(
    uid INT NOT NULL,
    cid INT NOT NULL,
    role VARCHAR(50) NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (uid, cid),
    FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (cid) REFERENCES clusters(cid) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB;

-- ============================================
-- RELATIONSHIP: USER MODERATES CLUSTER (Many-to-Many)
-- Users can moderate multiple clusters
-- ============================================
CREATE TABLE user_moderates_cluster(
    uid INT NOT NULL,
    cid INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    permissions JSON,
    PRIMARY KEY (uid, cid),
    FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (cid) REFERENCES clusters(cid) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB;


-- ============================================
-- INDEXES FOR BETTER QUERY PERFORMANCE
-- ============================================
CREATE INDEX idx_posts_author ON posts(author_uid);
CREATE INDEX idx_posts_cluster ON posts(cluster_cid);
CREATE INDEX idx_posts_ref_post ON posts(ref_post_pid);
CREATE INDEX idx_posts_ref_window ON posts(ref_window_wid);
CREATE INDEX idx_comments_author ON comments(author_uid);
CREATE INDEX idx_comments_post ON comments(post_pid);
CREATE INDEX idx_comments_cluster ON comments(cluster_cid);
CREATE INDEX idx_comments_parent ON comments(parent_cmid);
CREATE INDEX idx_window_creator ON windowp(creator_uid);
CREATE INDEX idx_window_cluster ON windowp(cluster_cid);
CREATE INDEX idx_megaphone_sender ON megaphone(sender_uid);
CREATE INDEX idx_megaphone_cluster ON megaphone(cluster_cid);
CREATE INDEX idx_clusters_creator ON clusters(creator_uid);
CREATE INDEX idx_rules_cluster ON rules(cluster_cid);

-- ============================================
-- SAMPLE INSERT QUERIES
-- ============================================

-- Insert Users
INSERT INTO users (username, user_contact, password, metadata, role) VALUES
('john_doe', '{"email": "john@example.com", "phone": "1234567890"}', 'hashed_password_1', '{"profile_pic": "url1", "bio": "Hello World"}', 'admin'),
('jane_smith', '{"email": "jane@example.com", "phone": "0987654321"}', 'hashed_password_2', '{"profile_pic": "url2", "bio": "Hi there"}', 'user'),
('bob_wilson', '{"email": "bob@example.com", "phone": "5555555555"}', 'hashed_password_3', '{"profile_pic": "url3", "bio": "Developer"}', 'user');

-- Insert Clusters
INSERT INTO clusters (name, data, settings, metadata, creator_uid) VALUES
('Tech Enthusiasts', '{"description": "A cluster for tech lovers"}', '{"privacy": "public", "join_approval": false}', '{"tags": ["tech", "programming"]}', 1),
('Book Club', '{"description": "Monthly book discussions"}', '{"privacy": "private", "join_approval": true}', '{"tags": ["books", "reading"]}', 2);

-- Insert Posts
INSERT INTO posts (title, content, author_uid, cluster_cid, metadata, context, engagement, lifecycle_status) VALUES
('Welcome to Tech Enthusiasts!', 'This is our first post in the cluster.', 1, 1, '{"pinned": true}', '{"tags": ["welcome"]}', '{"likes": 0, "shares": 0}', '{"status": "published", "visibility": "public"}'),
('Best Programming Languages 2024', 'Lets discuss the top programming languages.', 2, 1, '{"pinned": false}', '{"tags": ["programming"]}', '{"likes": 5, "shares": 2}', '{"status": "published", "visibility": "public"}');

-- Insert a Post that References another Post
INSERT INTO posts (title, content, author_uid, cluster_cid, metadata, context, engagement, lifecycle_status, ref_post_pid) VALUES
('Follow-up: Programming Languages', 'Following up on the previous discussion...', 3, 1, '{"pinned": false}', '{"tags": ["followup"]}', '{"likes": 1, "shares": 0}', '{"status": "published", "visibility": "public"}', 2);

-- Insert Windows
INSERT INTO windowp (name, parameters, metadata, origin_data, creator_uid, cluster_cid) VALUES
('Weekly Discussion', '{"frequency": "weekly", "day": "Monday"}', '{"type": "discussion"}', '{"source": "manual"}', 1, 1),
('Book of the Month', '{"frequency": "monthly", "day": 1}', '{"type": "announcement"}', '{"source": "automated"}', 2, 2);

-- Insert Comments (including nested/parent comments)
INSERT INTO comments (content, author_uid, post_pid, cluster_cid, parent_cmid, metadata, engagement) VALUES
('Great post! Welcome everyone!', 2, 1, 1, NULL, '{"edited": false}', '{"likes": 3}'),
('I love Python!', 3, 2, 1, NULL, '{"edited": false}', '{"likes": 1}'),
('JavaScript is my favorite!', 1, 2, 1, NULL, '{"edited": true}', '{"likes": 2}');

-- Insert nested comment (reply to comment 2)
INSERT INTO comments (content, author_uid, post_pid, cluster_cid, parent_cmid, metadata, engagement) VALUES
('Python is great for beginners!', 1, 2, 1, 2, '{"edited": false}', '{"likes": 1}'),
('I agree, Python syntax is clean!', 2, 2, 1, 2, '{"edited": false}', '{"likes": 0}');

-- Insert Megaphone Messages
INSERT INTO megaphone (message, data, sender_uid, cluster_cid, metadata) VALUES
('Important: Cluster meeting tomorrow at 5 PM!', '{"priority": "high", "expiry": "2024-12-31"}', 1, 1, '{"read_count": 0}'),
('New book selection announced!', '{"priority": "medium", "expiry": "2024-12-15"}', 2, 2, '{"read_count": 0}');

-- Insert Rules for Clusters
INSERT INTO rules (title, description, cluster_cid, priority) VALUES
('Be Respectful', 'Treat all members with respect and courtesy.', 1, 1),
('No Spam', 'Do not post spam or promotional content.', 1, 2),
('Stay On Topic', 'Keep discussions relevant to the book being discussed.', 2, 1);

-- Insert User Reacts to Post
INSERT INTO user_reacts_post (uid, pid, reaction_type) VALUES
(2, 1, 'like'), (3, 1, 'love'),
(1, 2, 'like'), (3, 2, 'like');

-- Insert User Reacts to Comment
INSERT INTO user_reacts_comment (uid, cmid, reaction_type) VALUES
(1, 1, 'like'), (3, 1, 'like'),
(2, 2, 'like');

-- Insert User Joins Cluster Relationships
INSERT INTO user_joins_cluster (uid, cid, role) VALUES
(1, 1, 'admin'), (2, 1, 'user'), (3, 1, 'user'),
(2, 2, 'admin'), (1, 2, 'user');

-- Insert User Moderates Cluster Relationships
INSERT INTO user_moderates_cluster (uid, cid, permissions) VALUES
(1, 1, '{"can_delete_posts": true, "can_ban_users": true}'),
(2, 2, '{"can_delete_posts": true, "can_ban_users": false}');