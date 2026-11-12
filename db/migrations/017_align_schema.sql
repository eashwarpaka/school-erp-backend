-- db/migrations/017_align_schema.sql

-- Add missing columns to tenants expected by auth, seed, and tenant routes
ALTER TABLE tenants
  ADD COLUMN IF NOT EXISTS name VARCHAR(200),
  ADD COLUMN IF NOT EXISTS slug VARCHAR(100),
  ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active';

UPDATE tenants SET name = school_name WHERE name IS NULL AND school_name IS NOT NULL;
UPDATE tenants SET slug = LOWER(school_code) WHERE slug IS NULL AND school_code IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_slug ON tenants(slug);

-- Add missing columns to users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS full_name VARCHAR(200);

UPDATE users SET full_name = TRIM(CONCAT(first_name, ' ', last_name)) WHERE full_name IS NULL;

-- Ensure roles table exists
CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT
);

INSERT INTO roles (name, description) VALUES
  ('super_admin', 'Super Administrator'),
  ('school_admin', 'School Administrator'),
  ('accountant', 'Accountant'),
  ('hr_manager', 'HR Manager'),
  ('teacher', 'Teacher'),
  ('librarian', 'Librarian'),
  ('hostel_warden', 'Hostel Warden'),
  ('transport_manager', 'Transport Manager'),
  ('parent', 'Parent'),
  ('student', 'Student')
ON CONFLICT (name) DO NOTHING;

-- Ensure user_roles table exists
CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role_id INT REFERENCES roles(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- Ensure refresh_sessions table exists
CREATE TABLE IF NOT EXISTS refresh_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

