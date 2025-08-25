-- Trade opportunities analysis
CREATE TABLE trade_opportunities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  symbol VARCHAR(10) NOT NULL,
  analysis_date TIMESTAMP NOT NULL,
  research_score DECIMAL(5,2),
  risk_score DECIMAL(5,2),
  composite_score DECIMAL(5,2),
  credit_received DECIMAL(10,2),
  max_loss DECIMAL(10,2),
  delta DECIMAL(6,4),
  theta DECIMAL(6,4),
  iv_rank DECIMAL(5,2),
  liquidity_score DECIMAL(5,2),
  selected BOOLEAN DEFAULT FALSE,
  execution_status VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW()
);