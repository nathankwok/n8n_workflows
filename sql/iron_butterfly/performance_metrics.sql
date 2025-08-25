-- Performance metrics
CREATE TABLE performance_metrics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  metric_date DATE NOT NULL,
  daily_pnl DECIMAL(10,2),
  total_trades INTEGER,
  winning_trades INTEGER,
  losing_trades INTEGER,
  win_rate DECIMAL(5,2),
  sharpe_ratio DECIMAL(5,2),
  max_drawdown DECIMAL(5,2),
  total_delta DECIMAL(6,4),
  total_theta DECIMAL(6,4),
  margin_used DECIMAL(12,2),
  created_at TIMESTAMP DEFAULT NOW()
);