-- Materialized Views for Performance Optimization
-- Pre-computed views for common analytical queries and dashboards
-- Optimized for business intelligence and ML model serving

-- =============================================================================
-- BUSINESS INTELLIGENCE VIEWS
-- =============================================================================

-- Company summary with latest predictions and verification data
CREATE OR REPLACE MATERIALIZED VIEW mv_company_data_volume_summary AS
SELECT 
    c.company_id,
    c.company_name,
    c.industry,
    c.geo,
    c.number_of_employees,
    c.annual_revenue,
    c.core_business_model,
    c.classification_technology_maturity,
    
    -- Latest prediction data
    p.predicted_annual_volume_pb as latest_predicted_volume_pb,
    p.prediction_confidence as latest_prediction_confidence,
    p.prediction_timestamp as latest_prediction_date,
    p.model_name as latest_model_name,
    p.model_version as latest_model_version,
    
    -- Human verification data (if available)
    v.verified_annual_volume_pb,
    v.verification_confidence,
    v.verification_date,
    v.verification_source,
    
    -- Prediction accuracy (if ground truth available)
    CASE 
        WHEN v.verified_annual_volume_pb IS NOT NULL AND p.predicted_annual_volume_pb IS NOT NULL
        THEN ABS(p.predicted_annual_volume_pb - v.verified_annual_volume_pb) / v.verified_annual_volume_pb
        ELSE NULL 
    END as prediction_error_percentage,
    
    -- Data source summary
    ds.total_data_sources,
    ds.total_estimated_volume_gb_monthly,
    ds.high_criticality_sources,
    
    -- Latest research session info
    rs.latest_research_phase,
    rs.latest_research_quality_score,
    rs.latest_research_date,
    
    -- Timestamps
    CURRENT_TIMESTAMP() as view_refresh_timestamp
    
FROM dim_companies c

-- Latest predictions per company
LEFT JOIN (
    SELECT 
        company_id,
        predicted_annual_volume_pb,
        prediction_confidence,
        prediction_timestamp,
        model_name,
        model_version,
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY prediction_timestamp DESC) as rn
    FROM ml_data_volume_predictions 
    WHERE prediction_status = 'ACTIVE'
) p ON c.company_id = p.company_id AND p.rn = 1

-- Latest human verification per company
LEFT JOIN (
    SELECT 
        company_id,
        verified_annual_volume_pb,
        verification_confidence,
        verification_date,
        verification_source,
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY verification_date DESC) as rn
    FROM ml_human_verification 
    WHERE verification_status = 'VERIFIED'
) v ON c.company_id = v.company_id AND v.rn = 1

-- Data sources summary per company
LEFT JOIN (
    SELECT 
        company_id,
        COUNT(*) as total_data_sources,
        SUM(estimated_volume_gb_monthly) as total_estimated_volume_gb_monthly,
        SUM(CASE WHEN business_criticality = 'CRITICAL' THEN 1 ELSE 0 END) as high_criticality_sources
    FROM fact_company_data_sources 
    WHERE data_source_status = 'ACTIVE'
    GROUP BY company_id
) ds ON c.company_id = ds.company_id

-- Latest research session per company
LEFT JOIN (
    SELECT 
        company_id,
        phase as latest_research_phase,
        research_quality_score as latest_research_quality_score,
        processing_timestamp as latest_research_date,
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY processing_timestamp DESC) as rn
    FROM fact_research_sessions
) rs ON c.company_id = rs.company_id AND rs.rn = 1;

-- =============================================================================
-- ML MODEL PERFORMANCE VIEWS
-- =============================================================================

-- Model performance summary across all companies
CREATE OR REPLACE MATERIALIZED VIEW mv_model_performance_summary AS
SELECT 
    model_name,
    model_version,
    
    -- Prediction volume metrics
    COUNT(*) as total_predictions,
    COUNT(CASE WHEN prediction_status = 'ACTIVE' THEN 1 END) as active_predictions,
    AVG(prediction_confidence) as avg_prediction_confidence,
    
    -- Accuracy metrics (where ground truth available)
    COUNT(v.verified_annual_volume_pb) as verified_predictions_count,
    AVG(ABS(p.predicted_annual_volume_pb - v.verified_annual_volume_pb)) as avg_absolute_error,
    AVG(ABS(p.predicted_annual_volume_pb - v.verified_annual_volume_pb) / v.verified_annual_volume_pb) as avg_percentage_error,
    STDDEV(ABS(p.predicted_annual_volume_pb - v.verified_annual_volume_pb) / v.verified_annual_volume_pb) as stddev_percentage_error,
    
    -- Prediction ranges
    MIN(p.predicted_annual_volume_pb) as min_predicted_volume,
    MAX(p.predicted_annual_volume_pb) as max_predicted_volume,
    AVG(p.predicted_annual_volume_pb) as avg_predicted_volume,
    MEDIAN(p.predicted_annual_volume_pb) as median_predicted_volume,
    
    -- Model deployment info
    MIN(p.prediction_timestamp) as first_prediction_date,
    MAX(p.prediction_timestamp) as latest_prediction_date,
    COUNT(DISTINCT p.company_id) as companies_predicted,
    
    -- Performance by industry
    COUNT(DISTINCT c.industry) as industries_covered,
    
    CURRENT_TIMESTAMP() as view_refresh_timestamp
    
FROM ml_data_volume_predictions p
JOIN dim_companies c ON p.company_id = c.company_id
LEFT JOIN ml_human_verification v ON p.company_id = v.company_id 
    AND v.verification_status = 'VERIFIED'
    AND ABS(DATEDIFF('day', p.prediction_timestamp, v.verification_date)) <= 30

GROUP BY model_name, model_version;

-- =============================================================================
-- DRIFT MONITORING DASHBOARD VIEW
-- =============================================================================

-- Recent drift alerts and trends
CREATE OR REPLACE MATERIALIZED VIEW mv_drift_monitoring_dashboard AS
SELECT 
    model_name,
    model_version,
    drift_type,
    drift_severity,
    
    -- Recent alerts (last 30 days)
    COUNT(CASE WHEN check_timestamp >= DATEADD('day', -30, CURRENT_TIMESTAMP()) AND drift_detected THEN 1 END) as alerts_last_30_days,
    COUNT(CASE WHEN check_timestamp >= DATEADD('day', -7, CURRENT_TIMESTAMP()) AND drift_detected THEN 1 END) as alerts_last_7_days,
    COUNT(CASE WHEN check_timestamp >= DATEADD('day', -1, CURRENT_TIMESTAMP()) AND drift_detected THEN 1 END) as alerts_last_24_hours,
    
    -- Alert resolution
    COUNT(CASE WHEN resolution_status = 'OPEN' THEN 1 END) as open_alerts,
    COUNT(CASE WHEN resolution_status = 'IN_PROGRESS' THEN 1 END) as in_progress_alerts,
    COUNT(CASE WHEN resolution_status = 'RESOLVED' THEN 1 END) as resolved_alerts,
    
    -- Drift trends
    AVG(CASE WHEN check_timestamp >= DATEADD('day', -30, CURRENT_TIMESTAMP()) THEN drift_score END) as avg_drift_score_30d,
    MAX(CASE WHEN check_timestamp >= DATEADD('day', -30, CURRENT_TIMESTAMP()) THEN drift_score END) as max_drift_score_30d,
    
    -- Business impact
    AVG(business_impact_score) as avg_business_impact,
    COUNT(CASE WHEN triggered_retraining THEN 1 END) as retraining_events,
    
    -- Latest status
    MAX(check_timestamp) as latest_check_timestamp,
    ANY_VALUE(CASE WHEN check_timestamp = MAX(check_timestamp) THEN drift_detected END) as latest_drift_detected,
    ANY_VALUE(CASE WHEN check_timestamp = MAX(check_timestamp) THEN drift_score END) as latest_drift_score,
    
    CURRENT_TIMESTAMP() as view_refresh_timestamp
    
FROM ml_drift_monitoring
GROUP BY model_name, model_version, drift_type, drift_severity;

-- =============================================================================
-- FEATURE STORE SERVING VIEW
-- =============================================================================

-- Latest features per company for real-time model serving
CREATE OR REPLACE MATERIALIZED VIEW mv_latest_company_features AS
SELECT 
    f.company_id,
    f.feature_version,
    f.feature_extraction_timestamp,
    
    -- Company scale features
    f.employee_count_log,
    f.revenue_per_employee,
    f.revenue_growth_rate,
    f.company_age_years,
    f.geographic_presence_score,
    
    -- Technology features
    f.technology_stack_complexity_score,
    f.cloud_adoption_percentage,
    f.data_maturity_index,
    f.api_integration_score,
    f.automation_level_score,
    
    -- Industry features
    f.industry_data_intensity_multiplier,
    f.business_model_data_factor,
    f.customer_interaction_complexity,
    f.transaction_intensity_score,
    f.regulatory_compliance_burden,
    
    -- Data source features
    f.total_operational_systems,
    f.customer_facing_systems_count,
    f.iot_sensor_density_score,
    f.communication_systems_count,
    f.development_systems_count,
    
    -- Volume prediction features
    f.baseline_volume_per_employee,
    f.technology_volume_multiplier,
    f.growth_stage_multiplier,
    f.data_retention_multiplier,
    f.real_time_data_percentage,
    
    -- Metadata
    f.feature_completeness_score,
    f.dataset_split,
    
    CURRENT_TIMESTAMP() as view_refresh_timestamp
    
FROM ml_company_features f
JOIN (
    SELECT 
        company_id,
        MAX(feature_extraction_timestamp) as latest_extraction
    FROM ml_company_features
    GROUP BY company_id
) latest ON f.company_id = latest.company_id 
    AND f.feature_extraction_timestamp = latest.latest_extraction;

-- =============================================================================
-- DATA QUALITY MONITORING VIEW
-- =============================================================================

-- Data quality metrics across all tables
CREATE OR REPLACE MATERIALIZED VIEW mv_data_quality_summary AS
SELECT 
    'dim_companies' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN company_name IS NOT NULL THEN 1 END) / COUNT(*) as company_name_completeness,
    COUNT(CASE WHEN number_of_employees IS NOT NULL THEN 1 END) / COUNT(*) as employee_count_completeness,
    COUNT(CASE WHEN industry IS NOT NULL THEN 1 END) / COUNT(*) as industry_completeness,
    COUNT(CASE WHEN annual_revenue IS NOT NULL THEN 1 END) / COUNT(*) as revenue_completeness,
    CURRENT_TIMESTAMP() as view_refresh_timestamp
FROM dim_companies

UNION ALL

SELECT 
    'fact_company_data_sources' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN estimated_volume_gb_monthly IS NOT NULL THEN 1 END) / COUNT(*) as volume_estimate_completeness,
    COUNT(CASE WHEN volume_confidence IS NOT NULL THEN 1 END) / COUNT(*) as confidence_completeness,
    COUNT(CASE WHEN source_category IS NOT NULL THEN 1 END) / COUNT(*) as category_completeness,
    COUNT(CASE WHEN business_criticality IS NOT NULL THEN 1 END) / COUNT(*) as criticality_completeness,
    CURRENT_TIMESTAMP() as view_refresh_timestamp
FROM fact_company_data_sources

UNION ALL

SELECT 
    'ml_data_volume_predictions' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN prediction_confidence IS NOT NULL THEN 1 END) / COUNT(*) as confidence_completeness,
    COUNT(CASE WHEN feature_importance IS NOT NULL THEN 1 END) / COUNT(*) as feature_importance_completeness,
    COUNT(CASE WHEN is_latest_prediction = TRUE THEN 1 END) / COUNT(DISTINCT company_id) as latest_prediction_ratio,
    COUNT(CASE WHEN prediction_status = 'ACTIVE' THEN 1 END) / COUNT(*) as active_prediction_ratio,
    CURRENT_TIMESTAMP() as view_refresh_timestamp
FROM ml_data_volume_predictions;

-- =============================================================================
-- REFRESH SCHEDULE COMMENTS
-- =============================================================================

-- Recommended refresh schedules:
-- mv_company_data_volume_summary: Every 6 hours (for business dashboards)
-- mv_model_performance_summary: Daily (for ML team monitoring)
-- mv_drift_monitoring_dashboard: Every hour (for alerting)
-- mv_latest_company_features: Every 2 hours (for model serving)
-- mv_data_quality_summary: Daily (for data governance)