CREATE TABLE IF NOT EXISTS board_sessions (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(100) UNIQUE NOT NULL,
    question TEXT NOT NULL,
    model VARCHAR(100),
    version VARCHAR(50),
    execution_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS board_agents (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES board_sessions(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,
    summary TEXT,
    analysis JSONB,
    recommendation TEXT,
    confidence NUMERIC(4,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS board_reports (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES board_sessions(id) ON DELETE CASCADE,
    title TEXT,
    report_markdown TEXT,
    summary TEXT,
    recommendation TEXT,
    confidence NUMERIC(4,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
