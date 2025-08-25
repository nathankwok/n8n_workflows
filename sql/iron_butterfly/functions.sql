-- Functions for atomic operations
CREATE OR REPLACE FUNCTION increment_error_count(p_api_name VARCHAR)
RETURNS TABLE(error_count INTEGER, circuit_state VARCHAR) AS $$
BEGIN
  UPDATE api_health 
  SET error_count = error_count + 1,
      last_failure = NOW(),
      circuit_state = CASE 
        WHEN error_count >= 10 THEN 'OPEN'
        ELSE circuit_state
      END,
      circuit_open_time = CASE
        WHEN error_count >= 10 AND circuit_state != 'OPEN' THEN NOW()
        ELSE circuit_open_time
      END,
      updated_at = NOW()
  WHERE api_name = p_api_name;
  
  IF NOT FOUND THEN
    INSERT INTO api_health (api_name, error_count, last_failure)
    VALUES (p_api_name, 1, NOW());
  END IF;
  
  RETURN QUERY
  SELECT ah.error_count, ah.circuit_state 
  FROM api_health ah 
  WHERE ah.api_name = p_api_name;
END;
$$ LANGUAGE plpgsql;

-- Function to check circuit breaker state
CREATE OR REPLACE FUNCTION check_circuit_breaker(p_api_name VARCHAR)
RETURNS TABLE(can_proceed BOOLEAN, state VARCHAR, wait_time INTEGER) AS $$
DECLARE
  v_state VARCHAR;
  v_open_time TIMESTAMP;
  v_wait_time INTEGER;
BEGIN
  SELECT circuit_state, circuit_open_time 
  INTO v_state, v_open_time
  FROM api_health 
  WHERE api_name = p_api_name;
  
  IF v_state = 'OPEN' THEN
    v_wait_time := EXTRACT(EPOCH FROM (v_open_time + INTERVAL '60 seconds' - NOW()))::INTEGER;
    
    IF v_wait_time <= 0 THEN
      -- Move to HALF_OPEN state
      UPDATE api_health 
      SET circuit_state = 'HALF_OPEN', updated_at = NOW()
      WHERE api_name = p_api_name;
      
      RETURN QUERY SELECT TRUE, 'HALF_OPEN'::VARCHAR, 0;
    ELSE
      RETURN QUERY SELECT FALSE, v_state, v_wait_time;
    END IF;
  ELSE
    RETURN QUERY SELECT TRUE, COALESCE(v_state, 'CLOSED'), 0;
  END IF;
END;
$$ LANGUAGE plpgsql;