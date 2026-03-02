-- ==========================================
-- 运动康复预约系统 - 数据库表结构 & RLS策略
-- 请按顺序在Supabase SQL编辑器中执行
-- ==========================================

-- 1. 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. 创建用户信息表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    package_type TEXT NOT NULL CHECK (package_type IN ('A', 'B')), -- A:8次, B:4次
    total_sessions INTEGER NOT NULL,
    remaining_sessions INTEGER NOT NULL,
    used_session_indices TEXT[] DEFAULT '{}', -- 记录已使用的序号,如 ['A1','A2']
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 创建预约记录表
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_phone TEXT NOT NULL,
    appointment_date DATE NOT NULL,
    time_slot TEXT NOT NULL, -- 如 '11:00-12:00'
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled')),
    package_type TEXT NOT NULL,
    session_index TEXT NOT NULL, -- 如 'A3'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(appointment_date, time_slot)
);

-- 4. 创建操作记录表 (用于限制每月取消次数)
CREATE TABLE IF NOT EXISTS operation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    operation_type TEXT NOT NULL CHECK (operation_type IN ('cancel')),
    operation_date TIMESTAMPTZ DEFAULT NOW(),
    year_month TEXT NOT NULL -- 格式 '2026-03'
);

-- ==========================================
-- 行级安全策略 (RLS) - 核心安全保障
-- ==========================================

-- 启用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE operation_logs ENABLE ROW LEVEL SECURITY;

-- Users 表策略: 仅可查看自己信息
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

-- Appointments 表策略: 用户看自己的,商户看全部
CREATE POLICY "Users can view own appointments" ON appointments
    FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "Users can insert own appointments" ON appointments
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "Users can update own appointments" ON appointments
    FOR UPDATE USING (auth.uid()::text = user_id::text);

-- Operation_logs 表策略
CREATE POLICY "Users can view own logs" ON operation_logs
    FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "Users can insert own logs" ON operation_logs
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

-- ==========================================
-- 商户专用视图 (用于绕过RLS查看全部数据, 需配合service_role key)
-- 实际商户端逻辑建议使用Edge Functions或在前端使用service_role key(谨慎)
-- 此处演示为简化版, 商户端将使用独立的密码验证+service_role
-- ==========================================

-- ==========================================
-- 初始化一些测试数据 (可选执行)
-- ==========================================
-- 注意：实际使用时，请确保先在Supabase Auth中创建用户，
-- 然后将auth.users表中的id手动对应插入到users表中，或使用Trigger自动同步
-- 以下为示例结构，实际ID请替换为真实Auth UUID
/*
INSERT INTO users (id, phone, name, package_type, total_sessions, remaining_sessions, used_session_indices) VALUES
('替换为真实Auth用户UUID1', '13800138001', '张三', 'A', 8, 6, ARRAY['A1','A2']),
('替换为真实Auth用户UUID2', '13800138002', '李四', 'B', 4, 3, ARRAY['B1']);
*/

-- ==========================================
-- 创建自动更新 updated_at 字段的函数
-- ==========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
