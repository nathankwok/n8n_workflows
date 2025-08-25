-- Error and recovery logs
CREATE TABLE error_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  error_type VARCHAR(50) NOT NULL,
  error_message TEXT,
  error_context JSONB,
  severity VARCHAR(20),
  recovery_action VARCHAR(100),
  resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);