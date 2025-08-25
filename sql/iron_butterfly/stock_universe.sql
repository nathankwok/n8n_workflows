-- Stock universe
CREATE TABLE stock_universe (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  symbol VARCHAR(10) UNIQUE NOT NULL,
  name VARCHAR(255),
  sector VARCHAR(50),
  market_cap BIGINT,
  avg_volume BIGINT,
  options_volume BIGINT,
  last_price DECIMAL(10,2),
  last_earnings DATE,
  next_earnings DATE,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);