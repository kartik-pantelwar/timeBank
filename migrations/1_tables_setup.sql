-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    uid SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    work_location TEXT NOT NULL,
    balance DECIMAL(5,2) DEFAULT 5.0 CHECK(balance >= 0),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- AUTH SESSIONS TABLE
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(uid),
    token_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    issued_at TIMESTAMPTZ NOT NULL,
    UNIQUE(user_id)
);

-- SKILLS TABLE
CREATE TABLE IF NOT EXISTS skills (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    user_id INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    status BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id,name)
);

-- SERVICE SESSIONS TABLE
CREATE TABLE IF NOT EXISTS service_sessions (
    id SERIAL PRIMARY KEY,
    duration INTERVAL NOT NULL,
    provided_by INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    provided_to INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    skill_name VARCHAR(100) REFERENCES skills(name) ON DELETE CASCADE,
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ
);

-- FEEDBACK TABLE
CREATE TABLE IF NOT EXISTS feedback (
    id SERIAL PRIMARY KEY,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, 
    session_id INTEGER REFERENCES service_sessions(id) ON DELETE CASCADE,
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5)
);

-- TIME CREDITS TABLE
CREATE TABLE IF NOT EXISTS time_credits (
    id SERIAL PRIMARY KEY,
    given_to INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    given_by INTEGER REFERENCES users(uid) ON DELETE CASCADE,
    amount DECIMAL(5,2) NOT NULL CHECK (amount >= 0),
    transaction_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- *TRIGGERS
-- ^FOR CHECKING BALANCE BEFORE CREATING SESSION
CREATE OR REPLACE FUNCTION check_balance()
RETURNS TRIGGER AS $$
DECLARE
    user_balance DECIMAL(5,2);
    required_credits DECIMAL(5,2);
BEGIN
    --CONVERTING DURATION INTO DECIMAL(FOR REQUIRED CREDITS)
    required_credits:=EXTRACT(EPOCH FROM NEW.duration)/3600.0;

    SELECT balance INTO user_balance
    FROM users
    WHERE uid = NEW.provided_to;

    IF user_balance < required_credits THEN 
        RAISE EXCEPTION 'Insufficient Balance!';
    END IF;

    UPDATE users
    SET balance = balance - required_credits
    WHERE uid = NEW.provided_to;

    UPDATE users
    SET balance = balance + required_credits
    WHERE uid = NEW.provided_by;

    INSERT INTO time_credits (given_to, given_by, amount)
    VALUES (NEW.provided_by, NEW.provided_to, required_credits);

    RAISE NOTICE 'Session successfully Completed';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER session_change
BEFORE INSERT ON service_sessions
FOR EACH ROW 
EXECUTE FUNCTION check_balance();


-- ^END TIME TRIGGER
CREATE OR REPLACE FUNCTION set_ended_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ended_at = NEW.started_at + NEW.duration;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER ending_time
BEFORE INSERT ON service_sessions
FOR EACH ROW
EXECUTE FUNCTION set_ended_at();
