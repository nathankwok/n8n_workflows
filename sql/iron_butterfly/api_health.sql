-- API rate limiting and circuit breaker
CREATE TABLE api_health (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  api_name VARCHAR(50) NOT NULL,
  error_count INTEGER DEFAULT 0,
  circuit_state VARCHAR(20) DEFAULT 'CLOSED',
  circuit_open_time TIMESTAMP,
  last_success TIMESTAMP,
  last_failure TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);