-- BƯỚC 4: CƠ SỞ DỮ LIỆU PHÚC LONG MART AFFILIATE
-- MySQL 8.0+
-- Dữ liệu thiết kế phục vụ bài tập/đồ án. Không chứa dữ liệu thật.

CREATE DATABASE IF NOT EXISTS phuclongmart_affiliate
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE phuclongmart_affiliate;

CREATE TABLE roles (
  role_id INT AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE users (
  user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  role_id INT NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  username VARCHAR(60) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  email VARCHAR(150) UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(role_id)
) ENGINE=InnoDB;

CREATE TABLE affiliates (
  affiliate_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  affiliate_code VARCHAR(40) NOT NULL UNIQUE,
  display_name VARCHAR(150) NOT NULL,
  tiktok_handle VARCHAR(100),
  contact_email VARCHAR(150),
  phone VARCHAR(25),
  status ENUM('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_code VARCHAR(50) NOT NULL UNIQUE,
  product_name VARCHAR(200) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE commission_rates (
  rate_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT NULL,
  campaign_name VARCHAR(150),
  rate_percent DECIMAL(6,3) NOT NULL,
  effective_from DATE NOT NULL,
  effective_to DATE NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_rate_percent CHECK (rate_percent >= 0 AND rate_percent <= 100),
  CONSTRAINT fk_rates_product FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

CREATE TABLE orders (
  order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  platform_order_code VARCHAR(80) NOT NULL UNIQUE,
  affiliate_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL,
  order_date DATETIME NOT NULL,
  order_amount DECIMAL(14,2) NOT NULL,
  commission_base_amount DECIMAL(14,2) NOT NULL,
  order_status ENUM('PENDING','COMPLETED','CANCELLED','RETURNED','REFUNDED') NOT NULL DEFAULT 'PENDING',
  source_batch VARCHAR(100),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_order_amount CHECK (order_amount >= 0),
  CONSTRAINT chk_commission_base CHECK (commission_base_amount >= 0),
  CONSTRAINT fk_orders_affiliate FOREIGN KEY (affiliate_id) REFERENCES affiliates(affiliate_id),
  CONSTRAINT fk_orders_product FOREIGN KEY (product_id) REFERENCES products(product_id),
  INDEX idx_orders_date (order_date),
  INDEX idx_orders_status (order_status)
) ENGINE=InnoDB;

CREATE TABLE commissions (
  commission_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  rate_id BIGINT NULL,
  internal_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  platform_amount DECIMAL(14,2) NULL,
  currency CHAR(3) NOT NULL DEFAULT 'VND',
  calculation_note VARCHAR(500),
  calculated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_commission_order UNIQUE (order_id),
  CONSTRAINT chk_internal_amount CHECK (internal_amount >= 0),
  CONSTRAINT chk_platform_amount CHECK (platform_amount IS NULL OR platform_amount >= 0),
  CONSTRAINT fk_commissions_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT fk_commissions_rate FOREIGN KEY (rate_id) REFERENCES commission_rates(rate_id)
) ENGINE=InnoDB;

CREATE TABLE reconciliation_runs (
  run_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  run_name VARCHAR(150) NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  imported_file_name VARCHAR(255),
  performed_by BIGINT NOT NULL,
  run_status ENUM('DRAFT','PROCESSING','COMPLETED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_run_period CHECK (period_end >= period_start),
  CONSTRAINT fk_runs_user FOREIGN KEY (performed_by) REFERENCES users(user_id)
) ENGINE=InnoDB;

CREATE TABLE reconciliations (
  reconciliation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  run_id BIGINT NOT NULL,
  commission_id BIGINT NULL,
  platform_order_code VARCHAR(80) NOT NULL,
  internal_amount DECIMAL(14,2) NULL,
  platform_amount DECIMAL(14,2) NULL,
  difference_amount DECIMAL(14,2) NULL,
  result_status ENUM('MATCHED','DIFFERENCE','MISSING_INTERNAL','MISSING_PLATFORM','NEEDS_REVIEW') NOT NULL,
  resolution_note VARCHAR(1000),
  resolved_by BIGINT NULL,
  resolved_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_recon_run FOREIGN KEY (run_id) REFERENCES reconciliation_runs(run_id),
  CONSTRAINT fk_recon_commission FOREIGN KEY (commission_id) REFERENCES commissions(commission_id),
  CONSTRAINT fk_recon_user FOREIGN KEY (resolved_by) REFERENCES users(user_id),
  INDEX idx_recon_status (result_status),
  INDEX idx_recon_order (platform_order_code)
) ENGINE=InnoDB;

CREATE TABLE payments (
  payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  affiliate_id BIGINT NOT NULL,
  reconciliation_id BIGINT NULL,
  payment_reference VARCHAR(80) UNIQUE,
  payment_amount DECIMAL(14,2) NOT NULL,
  payment_date DATE NULL,
  payment_status ENUM('PLANNED','PROCESSING','PAID','ON_HOLD','CANCELLED') NOT NULL DEFAULT 'PLANNED',
  note VARCHAR(500),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_payment_amount CHECK (payment_amount >= 0),
  CONSTRAINT fk_payments_affiliate FOREIGN KEY (affiliate_id) REFERENCES affiliates(affiliate_id),
  CONSTRAINT fk_payments_recon FOREIGN KEY (reconciliation_id) REFERENCES reconciliations(reconciliation_id)
) ENGINE=InnoDB;

-- Dữ liệu danh mục mẫu (không phải dữ liệu thật)
INSERT INTO roles (role_name, description) VALUES
('ADMIN','Quản trị hệ thống'),
('AFFILIATE_STAFF','Nhân viên quản lý Affiliate và đơn hàng'),
('ACCOUNTANT','Nhân viên kế toán/đối soát'),
('MANAGER','Quản lý xem báo cáo');

-- Gợi ý: tạo người dùng qua ứng dụng và lưu password_hash bằng thuật toán băm an toàn.
-- Không ghi mật khẩu dạng văn bản thuần vào cơ sở dữ liệu hoặc GitHub.
