-- Row Level Security (RLS) policies
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trade_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_health ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_universe ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_state ENABLE ROW LEVEL SECURITY;

-- Create service role policies (adjust based on your auth setup)
CREATE POLICY "Service role can manage all data" ON positions
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
  
CREATE POLICY "Service role can manage all data" ON trade_opportunities
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');