-- Complete Supabase Database Schema for YouTube Comment Automation

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Videos table - stores scraped YouTube videos
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    channel_title TEXT,
    published_at TIMESTAMP,
    keyword TEXT,
    score INTEGER DEFAULT 0,
    posted BOOLEAN DEFAULT false,
    flagged BOOLEAN DEFAULT false,
    thumbnail_url TEXT,
    repost_reason TEXT,
    last_health_check TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- YouTube accounts table - stores account credentials and cookies
CREATE TABLE youtube_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password TEXT,
    cookies_json TEXT,
    proxy_host TEXT,
    proxy_port INTEGER,
    proxy_type TEXT DEFAULT 'http',
    recovery_email TEXT,
    recovery_phone TEXT,
    active BOOLEAN DEFAULT true,
    success_rate DECIMAL(3,2) DEFAULT 0.0,
    last_used TIMESTAMP,
    total_posts INTEGER DEFAULT 0,
    total_failures INTEGER DEFAULT 0,
    comment_step INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Thread logs table - tracks all comment posting attempts
CREATE TABLE thread_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id TEXT NOT NULL,
    account_email TEXT NOT NULL,
    comment_text TEXT NOT NULL,
    proxy_used TEXT,
    status TEXT NOT NULL, -- 'success', 'failed', 'pending'
    error_message TEXT,
    qqtube_order_id TEXT,
    likes_purchased INTEGER,
    ai_provider TEXT,
    engagement_score INTEGER,
    health_status TEXT, -- 'healthy', 'comment_deleted', 'video_unavailable'
    last_health_check TIMESTAMP,
    engagement_likes TEXT DEFAULT '0',
    engagement_replies TEXT DEFAULT '0',
    timestamp TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Settings table - stores configuration values
CREATE TABLE settings (
    id SERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Flagged words table - tracks words that get comments flagged
CREATE TABLE flagged_words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word TEXT UNIQUE NOT NULL,
    severity TEXT DEFAULT 'medium', -- 'low', 'medium', 'high'
    flag_count INTEGER DEFAULT 1,
    last_flagged TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Analytics table - stores performance metrics
CREATE TABLE analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    videos_scraped INTEGER DEFAULT 0,
    comments_posted INTEGER DEFAULT 0,
    comments_successful INTEGER DEFAULT 0,
    comments_failed INTEGER DEFAULT 0,
    total_likes_purchased INTEGER DEFAULT 0,
    total_cost DECIMAL(10,2) DEFAULT 0.0,
    avg_engagement_score DECIMAL(5,2) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(date)
);

-- Proxy pool table - manages rotating proxies
CREATE TABLE proxy_pool (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host TEXT NOT NULL,
    port INTEGER NOT NULL,
    type TEXT DEFAULT 'http',
    country TEXT,
    speed_ms INTEGER,
    success_rate DECIMAL(3,2) DEFAULT 0.0,
    last_used TIMESTAMP,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(host, port)
);

-- Video engagement tracking
CREATE TABLE video_engagement (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id TEXT NOT NULL,
    thread_id UUID REFERENCES thread_logs(id),
    check_timestamp TIMESTAMP DEFAULT NOW(),
    comment_likes INTEGER DEFAULT 0,
    comment_replies INTEGER DEFAULT 0,
    comment_position INTEGER, -- position in comments section
    video_views BIGINT,
    video_likes INTEGER,
    video_comments INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert default settings
INSERT INTO settings (key, value, description) VALUES
('trader_username', 'BullishWhalesClub', 'Main trader name to reference in comments'),
('telegram_handle', '@BullishwhalesChief', 'Telegram handle to drop in comments'),
('youtube_api_key', '', 'YouTube Data API v3 key'),
('openai_api_key', '', 'OpenAI API key for comment generation'),
('deepseek_api_key', '', 'DeepSeek API key (alternative to OpenAI)'),
('qqtube_api_key', '', 'QQTube API key for social proof boosting'),
('qqtube_service_id', '1234', 'QQTube service ID for YouTube likes'),
('ai_provider', 'openai', 'Primary AI provider (openai, deepseek, gemini)'),
('min_likes_per_boost', '120', 'Minimum likes to purchase per comment'),
('max_likes_per_boost', '200', 'Maximum likes to purchase per comment'),
('comment_delay_min', '300', 'Minimum seconds between comments'),
('comment_delay_max', '600', 'Maximum seconds between comments'),
('health_check_interval', '6', 'Hours between thread health checks'),
('repost_deleted_videos', 'true', 'Whether to repost on deleted videos'),
('max_daily_posts', '50', 'Maximum posts per day per account'),
('proxy_rotation_enabled', 'true', 'Enable automatic proxy rotation'),
('sentiment_analysis_enabled', 'true', 'Enable AI sentiment analysis of replies');

-- Create indexes for better performance
CREATE INDEX idx_videos_posted ON videos(posted);
CREATE INDEX idx_videos_video_id ON videos(video_id);
CREATE INDEX idx_videos_created_at ON videos(created_at);
CREATE INDEX idx_youtube_accounts_active ON youtube_accounts(active);
CREATE INDEX idx_youtube_accounts_last_used ON youtube_accounts(last_used);
CREATE INDEX idx_thread_logs_video_id ON thread_logs(video_id);
CREATE INDEX idx_thread_logs_status ON thread_logs(status);
CREATE INDEX idx_thread_logs_timestamp ON thread_logs(timestamp);
CREATE INDEX idx_analytics_date ON analytics(date);
CREATE INDEX idx_proxy_pool_active ON proxy_pool(active);
CREATE INDEX idx_video_engagement_video_id ON video_engagement(video_id);

-- Create views for easier data access
CREATE VIEW account_performance AS
SELECT 
    ya.email,
    ya.success_rate,
    ya.total_posts,
    ya.total_failures,
    ya.last_used,
    COUNT(tl.id) as recent_posts,
    AVG(CASE WHEN tl.status = 'success' THEN 1.0 ELSE 0.0 END) as recent_success_rate
FROM youtube_accounts ya
LEFT JOIN thread_logs tl ON ya.email = tl.account_email 
    AND tl.created_at > NOW() - INTERVAL '7 days'
WHERE ya.active = true
GROUP BY ya.email, ya.success_rate, ya.total_posts, ya.total_failures, ya.last_used
ORDER BY ya.success_rate DESC;

CREATE VIEW daily_performance AS
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as total_attempts,
    COUNT(CASE WHEN status = 'success' THEN 1 END) as successful_posts,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_posts,
    ROUND(COUNT(CASE WHEN status = 'success' THEN 1 END) * 100.0 / COUNT(*), 2) as success_rate,
    SUM(likes_purchased) as total_likes_purchased
FROM thread_logs
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;

CREATE VIEW video_performance AS
SELECT 
    v.video_id,
    v.title,
    v.channel_title,
    v.score,
    COUNT(tl.id) as comments_posted,
    COUNT(CASE WHEN tl.status = 'success' THEN 1 END) as successful_comments,
    SUM(tl.likes_purchased) as total_likes_purchased,
    MAX(ve.comment_likes) as max_engagement_likes,
    MAX(ve.comment_replies) as max_engagement_replies
FROM videos v
LEFT JOIN thread_logs tl ON v.video_id = tl.video_id
LEFT JOIN video_engagement ve ON v.video_id = ve.video_id
WHERE v.posted = true
GROUP BY v.video_id, v.title, v.channel_title, v.score
ORDER BY successful_comments DESC, total_likes_purchased DESC;

-- Functions for automated tasks
CREATE OR REPLACE FUNCTION update_daily_analytics()
RETURNS void AS $
BEGIN
    INSERT INTO analytics (
        date, 
        videos_scraped, 
        comments_posted, 
        comments_successful, 
        comments_failed,
        total_likes_purchased
    )
    SELECT 
        CURRENT_DATE,
        (SELECT COUNT(*) FROM videos WHERE DATE(created_at) = CURRENT_DATE),
        (SELECT COUNT(*) FROM thread_logs WHERE DATE(timestamp) = CURRENT_DATE),
        (SELECT COUNT(*) FROM thread_logs WHERE DATE(timestamp) = CURRENT_DATE AND status = 'success'),
        (SELECT COUNT(*) FROM thread_logs WHERE DATE(timestamp) = CURRENT_DATE AND status = 'failed'),
        (SELECT COALESCE(SUM(likes_purchased), 0) FROM thread_logs WHERE DATE(timestamp) = CURRENT_DATE AND status = 'success')
    ON CONFLICT (date) DO UPDATE SET
        videos_scraped = EXCLUDED.videos_scraped,
        comments_posted = EXCLUDED.comments_posted,
        comments_successful = EXCLUDED.comments_successful,
        comments_failed = EXCLUDED.comments_failed,
        total_likes_purchased = EXCLUDED.total_likes_purchased;
END;
$ LANGUAGE plpgsql;

-- Function to get optimal posting times by timezone
CREATE OR REPLACE FUNCTION get_optimal_posting_times()
RETURNS TABLE(
    timezone TEXT,
    hour INTEGER,
    avg_engagement DECIMAL,
    total_posts INTEGER
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        'UTC' as timezone,
        EXTRACT(HOUR FROM tl.timestamp)::INTEGER as hour,
        AVG(COALESCE(tl.engagement_score, 0))::DECIMAL as avg_engagement,
        COUNT(*)::INTEGER as total_posts
    FROM thread_logs tl
    WHERE tl.status = 'success' 
        AND tl.timestamp > NOW() - INTERVAL '30 days'
    GROUP BY EXTRACT(HOUR FROM tl.timestamp)
    ORDER BY avg_engagement DESC;
END;
$ LANGUAGE plpgsql;

-- Function to clean old data
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $
BEGIN
    -- Remove thread logs older than 90 days
    DELETE FROM thread_logs WHERE created_at < NOW() - INTERVAL '90 days';
    
    -- Remove video engagement data older than 60 days
    DELETE FROM video_engagement WHERE created_at < NOW() - INTERVAL '60 days';
    
    -- Remove analytics data older than 1 year
    DELETE FROM analytics WHERE date < CURRENT_DATE - INTERVAL '1 year';
    
    -- Archive flagged videos older than 30 days
    UPDATE videos SET flagged = true 
    WHERE created_at < NOW() - INTERVAL '30 days' 
        AND posted = false;
END;
$ LANGUAGE plpgsql;

-- Triggers for automatic updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER update_videos_updated_at 
    BEFORE UPDATE ON videos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_youtube_accounts_updated_at 
    BEFORE UPDATE ON youtube_accounts 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at 
    BEFORE UPDATE ON settings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS) for multi-tenant support if needed
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE youtube_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE thread_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust based on your auth requirements)
CREATE POLICY "Enable all operations for authenticated users" ON videos
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON youtube_accounts
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON thread_logs
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON settings
    FOR ALL USING (auth.role() = 'authenticated');

-- Grant necessary permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;