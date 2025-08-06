-- ML Drift Monitoring Table
-- Tracks model performance degradation, feature drift, and prediction drift
-- Enables proactive model maintenance and retraining decisions

CREATE TABLE ml_drift_monitoring (
    -- Primary identifiers
    drift_check_id STRING PRIMARY KEY DEFAULT CONCAT('DRIFT_', TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'), '_', ABS(RANDOM())),
    check_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Model identification
    model_name VARCHAR(100) NOT NULL,
    model_version VARCHAR(50),
    model_deployment_id STRING COMMENT 'Specific deployment instance being monitored',
    
    -- Drift type and detection method
    drift_type VARCHAR(20) NOT NULL COMMENT 'FEATURE, PREDICTION, PERFORMANCE, DATA_QUALITY',
    drift_category VARCHAR(50) COMMENT 'STATISTICAL, SEMANTIC, TEMPORAL, CONCEPT, COVARIATE',
    detection_method VARCHAR(50) COMMENT 'KS_TEST, PSI, CHI_SQUARE, JENSEN_SHANNON, WASSERSTEIN, CUSTOM',
    
    -- Drift measurement
    drift_metric VARCHAR(50) NOT NULL COMMENT 'KS_STAT, POPULATION_STABILITY_INDEX, MAE, RMSE, F1_DEGRADATION',
    drift_score DECIMAL(6,4) NOT NULL COMMENT 'Calculated drift score/statistic',
    drift_threshold DECIMAL(6,4) NOT NULL COMMENT 'Threshold that triggered alert',
    drift_detected BOOLEAN NOT NULL COMMENT 'Whether drift was detected (score > threshold)',
    drift_severity VARCHAR(20) COMMENT 'LOW, MEDIUM, HIGH, CRITICAL',
    
    -- Monitoring scope and window
    monitoring_window_days INTEGER NOT NULL COMMENT 'Time window used for drift detection',
    reference_period_start TIMESTAMP_NTZ COMMENT 'Start of reference/baseline period',
    reference_period_end TIMESTAMP_NTZ COMMENT 'End of reference/baseline period',
    comparison_period_start TIMESTAMP_NTZ COMMENT 'Start of comparison period',
    comparison_period_end TIMESTAMP_NTZ COMMENT 'End of comparison period',
    
    -- Affected components
    affected_features VARIANT COMMENT 'JSON array of features showing drift',
    affected_predictions VARIANT COMMENT 'JSON with prediction drift details',
    affected_segments VARIANT COMMENT 'JSON with segments (industry, geography) showing drift',
    feature_importance_shift VARIANT COMMENT 'JSON showing how feature importance changed',
    
    -- Statistical details
    statistical_test_results VARIANT COMMENT 'JSON with detailed statistical test results',
    confidence_level DECIMAL(3,2) DEFAULT 0.95 COMMENT 'Confidence level used in statistical tests',
    p_value DECIMAL(10,8) COMMENT 'P-value from statistical test if applicable',
    effect_size DECIMAL(6,4) COMMENT 'Effect size/magnitude of drift',
    
    -- Distribution analysis
    reference_distribution VARIANT COMMENT 'JSON with reference distribution statistics',
    current_distribution VARIANT COMMENT 'JSON with current distribution statistics',
    distribution_comparison VARIANT COMMENT 'JSON with distribution comparison metrics',
    outlier_analysis VARIANT COMMENT 'JSON with outlier detection results',
    
    -- Performance impact
    performance_degradation DECIMAL(6,4) COMMENT 'Measured performance degradation (accuracy drop)',
    business_impact_score DECIMAL(3,2) COMMENT 'Estimated business impact (0.0 to 1.0)',
    prediction_confidence_drop DECIMAL(6,4) COMMENT 'Average drop in prediction confidence',
    error_rate_increase DECIMAL(6,4) COMMENT 'Increase in prediction error rate',
    
    -- Root cause analysis
    potential_causes VARIANT COMMENT 'JSON array of potential causes for drift',
    environmental_factors VARIANT COMMENT 'JSON with external factors that may cause drift',
    data_pipeline_changes VARIANT COMMENT 'JSON with recent data pipeline changes',
    model_input_changes VARIANT COMMENT 'JSON with changes to model inputs',
    
    -- Recommended actions
    recommended_action VARCHAR(100) COMMENT 'RETRAIN, INVESTIGATE, MONITOR, ADJUST_THRESHOLD, ROLLBACK',
    action_priority VARCHAR(20) COMMENT 'LOW, MEDIUM, HIGH, URGENT',
    recommended_timeline VARCHAR(50) COMMENT 'IMMEDIATE, WITHIN_24H, WITHIN_WEEK, NEXT_CYCLE',
    estimated_effort_hours DECIMAL(4,1) COMMENT 'Estimated effort to address drift',
    
    -- Alert and notification
    alert_sent BOOLEAN DEFAULT FALSE COMMENT 'Whether alert notification was sent',
    alert_recipients VARIANT COMMENT 'JSON array of alert recipients',
    alert_channel VARCHAR(50) COMMENT 'EMAIL, SLACK, PAGERDUTY, DASHBOARD',
    escalation_level INTEGER DEFAULT 1 COMMENT 'Alert escalation level (1=team, 2=manager, 3=executive)',
    
    -- Resolution tracking
    resolution_status VARCHAR(20) DEFAULT 'OPEN' COMMENT 'OPEN, IN_PROGRESS, RESOLVED, ACKNOWLEDGED, FALSE_POSITIVE',
    resolution_date TIMESTAMP_NTZ COMMENT 'When drift issue was resolved',
    resolution_method VARCHAR(100) COMMENT 'How the drift was resolved',
    resolution_notes TEXT COMMENT 'Notes about drift resolution',
    resolved_by VARCHAR(100) COMMENT 'Who resolved the drift issue',
    
    -- Model retraining tracking
    triggered_retraining BOOLEAN DEFAULT FALSE COMMENT 'Whether this drift triggered model retraining',
    retraining_job_id STRING COMMENT 'ID of triggered retraining job',
    retraining_completion_date TIMESTAMP_NTZ COMMENT 'When retraining completed',
    post_retraining_validation VARIANT COMMENT 'JSON with validation results after retraining',
    
    -- Continuous monitoring metadata
    monitoring_job_id STRING COMMENT 'ID of monitoring job that detected drift',
    monitoring_frequency VARCHAR(20) COMMENT 'HOURLY, DAILY, WEEKLY, MONTHLY',
    next_check_scheduled TIMESTAMP_NTZ COMMENT 'When next drift check is scheduled',
    false_positive_flag BOOLEAN DEFAULT FALSE COMMENT 'Whether this was a false positive',
    
    -- Learning and improvement
    feedback_score DECIMAL(3,2) COMMENT 'Quality score of drift detection (0.0 to 1.0)',
    threshold_adjustment_suggested DECIMAL(6,4) COMMENT 'Suggested threshold adjustment based on feedback',
    monitoring_improvement_notes TEXT COMMENT 'Notes for improving drift monitoring',
    
    -- Audit fields
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT chk_drift_score CHECK (drift_score >= 0),
    CONSTRAINT chk_drift_threshold CHECK (drift_threshold >= 0),
    CONSTRAINT chk_monitoring_window CHECK (monitoring_window_days > 0),
    CONSTRAINT chk_confidence_level CHECK (confidence_level > 0.0 AND confidence_level < 1.0),
    CONSTRAINT chk_p_value CHECK (p_value IS NULL OR (p_value >= 0.0 AND p_value <= 1.0)),
    CONSTRAINT chk_performance_degradation CHECK (performance_degradation IS NULL OR performance_degradation >= 0),
    CONSTRAINT chk_business_impact CHECK (business_impact_score IS NULL OR (business_impact_score >= 0.0 AND business_impact_score <= 1.0)),
    CONSTRAINT chk_escalation_level CHECK (escalation_level >= 1 AND escalation_level <= 5),
    CONSTRAINT chk_effort_hours CHECK (estimated_effort_hours IS NULL OR estimated_effort_hours >= 0),
    CONSTRAINT chk_feedback_score CHECK (feedback_score IS NULL OR (feedback_score >= 0.0 AND feedback_score <= 1.0)),
    CONSTRAINT chk_period_order CHECK (
        reference_period_start IS NULL OR 
        reference_period_end IS NULL OR 
        reference_period_start <= reference_period_end
    ),
    CONSTRAINT chk_comparison_period_order CHECK (
        comparison_period_start IS NULL OR 
        comparison_period_end IS NULL OR 
        comparison_period_start <= comparison_period_end
    )
)
COMMENT = 'ML drift monitoring and alerting for proactive model maintenance and performance tracking';

-- Create indexes for performance
CREATE INDEX idx_drift_model ON ml_drift_monitoring(model_name, model_version);
CREATE INDEX idx_drift_timestamp ON ml_drift_monitoring(check_timestamp);
CREATE INDEX idx_drift_type ON ml_drift_monitoring(drift_type);
CREATE INDEX idx_drift_detected ON ml_drift_monitoring(drift_detected);
CREATE INDEX idx_drift_severity ON ml_drift_monitoring(drift_severity);
CREATE INDEX idx_drift_resolution_status ON ml_drift_monitoring(resolution_status);
CREATE INDEX idx_drift_alert_sent ON ml_drift_monitoring(alert_sent);
CREATE INDEX idx_drift_retraining ON ml_drift_monitoring(triggered_retraining);

-- Compound indexes for common queries
CREATE INDEX idx_drift_model_timestamp ON ml_drift_monitoring(model_name, check_timestamp);
CREATE INDEX idx_drift_model_detected ON ml_drift_monitoring(model_name, drift_detected);
CREATE INDEX idx_drift_type_severity ON ml_drift_monitoring(drift_type, drift_severity);
CREATE INDEX idx_drift_status_priority ON ml_drift_monitoring(resolution_status, action_priority);
CREATE INDEX idx_drift_model_type_timestamp ON ml_drift_monitoring(model_name, drift_type, check_timestamp);