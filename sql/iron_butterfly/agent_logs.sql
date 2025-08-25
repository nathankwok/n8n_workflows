-- Agent execution logs
CREATE TABLE agent_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  agent_type VARCHAR(50) NOT NULL,
  agent_id INTEGER,
  execution_id VARCHAR(100),
  input_data JSONB,
  output_data JSONB,
  execution_time_ms INTEGER,
  status VARCHAR(20),
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);