--create users and sessions table
CREATE TABLE IF NOT EXISTS users (
    uid SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    email TEXT NOT NULL,
    work_location TEXT NOT NULL,
    is_available BOOLEAN NOT NULL,
    balance DECIMAL(5,2) DEFAULT 0.0 CHECK(balance>=0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    rating DECIMAL(2,1) DEFAULT 0.0
);

--auth sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(uid),
    token_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    issued_at TIMESTAMPTZ NOT NULL,
    UNIQUE(user_id)
);


-- Skills table
CREATE TABLE IF NOT EXISTS skills (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    hourly_rate_credits DECIMAL(5,2) DEFAULT 1.00
);

--SERVICE SESSIONS TABLE
CREATE TABLE IF NOT EXISTS service_sessions(
    id SERIAL PRIMARY KEY,
    duration DECIMAL(5,2) NOT NULL,
    provided_by INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    provided_to INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    skill_id INTEGER REFERENCES skills(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

--FEEDBACK TABLE
CREATE TABLE IF NOT EXISTS feedback(
    id SERIAL PRIMARY KEY,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    session_id INTEGER REFERENCES service_sessions(id) ON DELETE CASCADE,
    given_by INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    given_to INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    rating DECIMAL(2,1) NOT NULL
);

--TIME CREDITS TABLE
CREATE TABLE IF NOT EXISTS time_credits(
    id SERIAL PRIMARY KEY,
    given_to INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    given_by INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    amount DECIMAL(5,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
--todo: write trigger for balance update with every update on time_credits

--SKILL REQUIREMENTS TABLE
CREATE TABLE IF NOT EXISTS skill_requirements(
    skill_id INTEGER REFERENCES skills(id) ON DELETE CASCADE,
    required_by INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    duration_required INTEGER NOT NULL,
    status BOOLEAN NOT NULL
    
);

--SKILL OFFERED TABLE
CREATE TABLE IF NOT EXISTS skill_offered(
    skill_id INTEGER REFERENCES skills(id) ON DELETE CASCADE,
    offered_by INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    duration_offering INTEGER NOT NULL,
    status BOOLEAN NOT NULL
);

--*FUNCTIONS AND TRIGGERS 
CREATE OR REPLACE FUNCTION func1()
RETURN TRIGGER AS $$
BEGIN
    --FUNCTION BODY HERE
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER session_change
AFTER UPDATE ON  service_sessions
FOR EARCH ROW 
EXECUTE FUNCTION func1();

--^NEGATIVE BALANCE CHECK USING BEFORE TRIGGER






-- Create view for user credit balance
-- CREATE VIEW user_credit_balance AS
-- SELECT 
--     u.id,
--     u.email,
--     u.first_name,
--     u.last_name,
--     COALESCE(SUM(tc.amount), 0) as current_balance,
--     COUNT(CASE WHEN tc.transaction_type = 'earned' THEN 1 END) as sessions_provided,
--     COUNT(CASE WHEN tc.transaction_type = 'spent' THEN 1 END) as sessions_received
-- FROM users u
-- LEFT JOIN time_credits tc ON u.id = tc.user_id
-- WHERE u.is_active = TRUE
-- GROUP BY u.id, u.email, u.first_name, u.last_name;

-- -- Create view for user reputation
-- CREATE VIEW user_reputation AS
-- SELECT 
--     u.id,
--     u.first_name,
--     u.last_name,
--     COUNT(f.id) as total_reviews,
--     ROUND(AVG(f.rating), 2) as average_rating,
--     COUNT(CASE WHEN f.rating = 5 THEN 1 END) as five_star_reviews,
--     COUNT(s.id) as total_sessions_completed
-- FROM users u
-- LEFT JOIN feedback f ON u.id = f.to_user_id
-- LEFT JOIN sessions s ON (u.id = s.provider_id OR u.id = s.receiver_id) AND s.status = 'completed'
-- GROUP BY u.id, u.first_name, u.last_name;




















-- User skills offered
-- CREATE TABLE user_skills_offered (
--     id SERIAL PRIMARY KEY,
--     user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     skill_id INTEGER REFERENCES skills(id) ON DELETE CASCADE,
--     proficiency_level INTEGER CHECK (proficiency_level BETWEEN 1 AND 5),
--     hourly_rate_credits DECIMAL(5,2) DEFAULT 1.00,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     UNIQUE(user_id, skill_id)
-- );

-- User skills needed
-- CREATE TABLE user_skills_needed (
--     id SERIAL PRIMARY KEY,
--     user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     skill_id INTEGER REFERENCES skills(id) ON DELETE CASCADE,
--     urgency_level INTEGER CHECK (urgency_level BETWEEN 1 AND 5),
--     max_rate_credits DECIMAL(5,2) DEFAULT 1.00,
--     description TEXT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     UNIQUE(user_id, skill_id)
-- );

-- Time credits ledger
-- CREATE TABLE time_credits (
--     id SERIAL PRIMARY KEY,
--     user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     amount DECIMAL(10,2) NOT NULL,
--     transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('earned', 'spent', 'bonus', 'penalty')),
--     reference_id INTEGER, -- session_id or other reference
--     reference_type VARCHAR(20), -- 'session', 'bonus', etc.
--     description TEXT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- Sessions table
-- CREATE TABLE sessions (
--     id SERIAL PRIMARY KEY,
--     provider_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     receiver_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     skill_id INTEGER REFERENCES skills(id),
--     title VARCHAR(255) NOT NULL,
--     description TEXT,
--     duration_hours DECIMAL(4,2) NOT NULL CHECK (duration_hours > 0),
--     status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')),
--     scheduled_at TIMESTAMP,
--     started_at TIMESTAMP,
--     completed_at TIMESTAMP,
--     location VARCHAR(255),
--     session_type VARCHAR(20) DEFAULT 'in_person' CHECK (session_type IN ('in_person', 'online', 'hybrid')),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- Feedback table
-- CREATE TABLE feedback (
--     id SERIAL PRIMARY KEY,
--     session_id INTEGER REFERENCES sessions(id) ON DELETE CASCADE,
--     from_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     to_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     rating INTEGER CHECK (rating BETWEEN 1 AND 5),
--     comment TEXT,
--     is_public BOOLEAN DEFAULT TRUE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     UNIQUE(session_id, from_user_id, to_user_id)
-- );

-- User availability
-- CREATE TABLE user_availability (
--     id SERIAL PRIMARY KEY,
--     user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday
--     start_time TIME NOT NULL,
--     end_time TIME NOT NULL,
--     is_active BOOLEAN DEFAULT TRUE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- Indexes for performance
-- CREATE INDEX idx_users_email ON users(email);
-- CREATE INDEX idx_users_location ON users(location);
-- CREATE INDEX idx_time_credits_user_id ON time_credits(user_id);
-- CREATE INDEX idx_sessions_provider_id ON sessions(provider_id);
-- CREATE INDEX idx_sessions_receiver_id ON sessions(receiver_id);
-- CREATE INDEX idx_sessions_status ON sessions(status);
-- CREATE INDEX idx_feedback_session_id ON feedback(session_id);