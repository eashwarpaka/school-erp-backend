-- db/seed/seed.sql

-- Create demo tenant
INSERT INTO tenants (name, slug, school_code, school_name, primary_color, timezone, currency, currency_symbol, locale, status)
VALUES ('Smart School ERP Demo', 'demo', 'DEMO', 'Smart School ERP Demo', '#f59e0b', 'Asia/Kolkata', 'INR', '₹', 'en-IN', 'active')
ON CONFLICT (school_code) DO UPDATE
SET school_name = EXCLUDED.school_name,
    name = EXCLUDED.name,
    slug = EXCLUDED.slug,
    primary_color = EXCLUDED.primary_color,
    status = 'active';

-- Create super admin (password: Admin@123)
INSERT INTO users (tenant_id, full_name, email, password_hash, role, first_name, last_name, is_active, is_email_verified)
SELECT id, 'Super Admin', 'super@schoolerp.com',
  '$2b$10$Urgmn1zbzCw9rYOvVUKsieFjuIz.jnJFte7gdCRQgWSOYxnB2XBta', -- bcrypt of 'Admin@123'
  'super_admin', 'Super', 'Admin', TRUE, TRUE
FROM tenants WHERE school_code = 'DEMO'
ON CONFLICT (email) DO UPDATE
SET password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    is_active = TRUE;

-- Create school admin (password: Admin@123)
INSERT INTO users (tenant_id, full_name, email, password_hash, role, first_name, last_name, is_active, is_email_verified)
SELECT id, 'School Admin', 'admin@demo.schoolerp.com',
  '$2b$10$Urgmn1zbzCw9rYOvVUKsieFjuIz.jnJFte7gdCRQgWSOYxnB2XBta',
  'school_admin', 'School', 'Admin', TRUE, TRUE
FROM tenants WHERE school_code = 'DEMO'
ON CONFLICT (email) DO UPDATE
SET password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    is_active = TRUE;

-- Map roles into user_roles
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON (
  (u.email = 'super@schoolerp.com' AND r.name = 'super_admin') OR
  (u.email = 'admin@demo.schoolerp.com' AND r.name = 'school_admin')
)
ON CONFLICT (user_id, role_id) DO NOTHING;

-- Demo academic year
INSERT INTO academic_years (tenant_id, name, start_date, end_date, is_current)
SELECT id, '2026-27', '2026-04-01', '2027-03-31', TRUE
FROM tenants WHERE school_code = 'DEMO'
AND NOT EXISTS (
  SELECT 1 FROM academic_years ay
  JOIN tenants t ON t.id = ay.tenant_id
  WHERE t.school_code = 'DEMO' AND ay.name = '2026-27'
);
