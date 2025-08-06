-- ML Data Volume Predictions Table
-- Stores model predictions for company data volume with confidence scores and explainability
-- Supports multiple models predicting the same company for A/B testing and ensemble methods

CREATE TABLE ml_data_volume_predictions (
    -- Primary identifiers
    prediction_id STRING PRIMARY KEY DEFAULT CONCAT('PRED_', TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'), '_', ABS(RANDOM())),
    company_id STRING NOT NULL,
    feature_id STRING,
    
    -- Model metadata
    model_name VARCHAR(100) NOT NULL COMMENT 'Name of the ML model making the prediction',
    model_version VARCHAR(50) NOT NULL COMMENT 'Version identifier of the model',
    model_type VARCHAR(50) COMMENT 'REGRESSION, ENSEMBLE, NEURAL_NETWORK, GRADIENT_BOOSTING, etc.',
    training_date TIMESTAMP_NTZ COMMENT 'When the model was last trained',
    
    -- Primary prediction: Total annual data volume
    predicted_annual_volume_pb DECIMAL(10,3) NOT NULL COMMENT 'Predicted total annual data volume in Petabytes',
    prediction_confidence DECIMAL(3,2) COMMENT 'Model confidence in prediction (0.0 to 1.0)',
    prediction_interval_lower DECIMAL(10,3) COMMENT 'Lower bound of prediction interval (95% confidence)',
    prediction_interval_upper DECIMAL(10,3) COMMENT 'Upper bound of prediction interval (95% confidence)',
    
    -- Breakdown by data source categories (for explainability)
    predicted_operational_volume_pb DECIMAL(10,3) COMMENT 'CRM, ERP, HR systems',
    predicted_customer_volume_pb DECIMAL(10,3) COMMENT 'Web analytics, mobile apps, e-commerce',
    predicted_iot_volume_pb DECIMAL(10,3) COMMENT 'IoT sensors, manufacturing equipment',
    predicted_communication_volume_pb DECIMAL(10,3) COMMENT 'Email, Slack, video conferencing',
    predicted_development_volume_pb DECIMAL(10,3) COMMENT 'Code repos, CI/CD, monitoring',
    predicted_financial_volume_pb DECIMAL(10,3) COMMENT 'Transaction systems, accounting',
    
    -- Prediction metadata
    prediction_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    prediction_latency_ms INTEGER COMMENT 'Time taken to generate prediction in milliseconds',
    is_latest_prediction BOOLEAN DEFAULT FALSE COMMENT 'Flag indicating the most recent prediction for this company',
    prediction_batch_id STRING COMMENT 'Identifier for batch prediction runs',
    
    -- Model explainability
    feature_importance VARIANT COMMENT 'JSON object with feature importance scores',
    shap_values VARIANT COMMENT 'SHAP values for model interpretability',
    prediction_explanation TEXT COMMENT 'Human-readable explanation of key factors driving prediction',
    top_contributing_features VARIANT COMMENT 'JSON array of top 5 features influencing prediction',
    
    -- Prediction quality metrics
    prediction_outlier_flag BOOLEAN DEFAULT FALSE COMMENT 'Whether prediction is considered an outlier',
    model_uncertainty_score DECIMAL(3,2) COMMENT 'Model uncertainty/epistemic uncertainty score',
    prediction_stability_score DECIMAL(3,2) COMMENT 'How stable this prediction is across model runs',
    
    -- Business context
    prediction_scenario VARCHAR(50) COMMENT 'CURRENT_STATE, GROWTH_PROJECTION, CONSERVATIVE_ESTIMATE',
    business_assumptions VARIANT COMMENT 'JSON with business assumptions used in prediction',
    external_factors VARIANT COMMENT 'JSON with external factors considered (market conditions, etc.)',
    
    -- Prediction validation
    prediction_status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT 'ACTIVE, SUPERSEDED, INVALIDATED, UNDER_REVIEW',
    validation_notes TEXT COMMENT 'Notes from prediction validation process',
    approved_for_business_use BOOLEAN DEFAULT FALSE COMMENT 'Whether prediction is approved for business decisions',
    
    -- Performance tracking (populated after ground truth is available)
    actual_vs_predicted_error DECIMAL(10,3) COMMENT 'Absolute error when ground truth becomes available',
    prediction_accuracy_score DECIMAL(3,2) COMMENT 'Accuracy score (1 - |error|/actual)',
    error_category VARCHAR(50) COMMENT 'UNDER_ESTIMATE, OVER_ESTIMATE, ACCURATE',
    
    -- A/B testing and experimentation
    experiment_id STRING COMMENT 'Identifier for A/B testing experiments',
    control_or_treatment VARCHAR(20) COMMENT 'CONTROL, TREATMENT_A, TREATMENT_B, etc.',
    experiment_segment VARCHAR(50) COMMENT 'Industry or company size segment for experiment',
    
    -- Data lineage
    input_data_version VARCHAR(20) COMMENT 'Version of input data used for prediction',
    feature_engineering_version VARCHAR(20) COMMENT 'Version of feature engineering pipeline',
    model_deployment_id STRING COMMENT 'Identifier for model deployment instance',
    
    -- Audit fields
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT chk_predicted_volume CHECK (predicted_annual_volume_pb >= 0),
    CONSTRAINT chk_prediction_confidence CHECK (prediction_confidence IS NULL OR (prediction_confidence >= 0.0 AND prediction_confidence <= 1.0)),
    CONSTRAINT chk_prediction_intervals CHECK (
        prediction_interval_lower IS NULL OR 
        prediction_interval_upper IS NULL OR 
        prediction_interval_lower <= prediction_interval_upper
    ),
    CONSTRAINT chk_volume_breakdown CHECK (
        predicted_operational_volume_pb IS NULL OR predicted_operational_volume_pb >= 0 AND
        predicted_customer_volume_pb IS NULL OR predicted_customer_volume_pb >= 0 AND
        predicted_iot_volume_pb IS NULL OR predicted_iot_volume_pb >= 0 AND
        predicted_communication_volume_pb IS NULL OR predicted_communication_volume_pb >= 0 AND
        predicted_development_volume_pb IS NULL OR predicted_development_volume_pb >= 0 AND
        predicted_financial_volume_pb IS NULL OR predicted_financial_volume_pb >= 0
    ),
    CONSTRAINT chk_uncertainty_score CHECK (model_uncertainty_score IS NULL OR (model_uncertainty_score >= 0.0 AND model_uncertainty_score <= 1.0)),
    CONSTRAINT chk_stability_score CHECK (prediction_stability_score IS NULL OR (prediction_stability_score >= 0.0 AND prediction_stability_score <= 1.0)),
    CONSTRAINT chk_accuracy_score CHECK (prediction_accuracy_score IS NULL OR (prediction_accuracy_score >= 0.0 AND prediction_accuracy_score <= 1.0)),
    CONSTRAINT chk_prediction_latency CHECK (prediction_latency_ms IS NULL OR prediction_latency_ms >= 0),
    
    -- Foreign keys
    CONSTRAINT fk_predictions_company FOREIGN KEY (company_id) REFERENCES dim_companies(company_id),
    CONSTRAINT fk_predictions_features FOREIGN KEY (feature_id) REFERENCES ml_company_features(feature_id)
)
COMMENT = 'ML predictions for company data volume with confidence scores, explainability, and performance tracking';

-- Create indexes for performance
CREATE INDEX idx_predictions_company ON ml_data_volume_predictions(company_id);
CREATE INDEX idx_predictions_model ON ml_data_volume_predictions(model_name, model_version);
CREATE INDEX idx_predictions_timestamp ON ml_data_volume_predictions(prediction_timestamp);
CREATE INDEX idx_predictions_latest ON ml_data_volume_predictions(is_latest_prediction);
CREATE INDEX idx_predictions_status ON ml_data_volume_predictions(prediction_status);
CREATE INDEX idx_predictions_batch ON ml_data_volume_predictions(prediction_batch_id);
CREATE INDEX idx_predictions_experiment ON ml_data_volume_predictions(experiment_id);

-- Compound indexes for common queries
CREATE INDEX idx_predictions_company_latest ON ml_data_volume_predictions(company_id, is_latest_prediction);
CREATE INDEX idx_predictions_company_model ON ml_data_volume_predictions(company_id, model_name, model_version);
CREATE INDEX idx_predictions_model_timestamp ON ml_data_volume_predictions(model_name, prediction_timestamp);
CREATE INDEX idx_predictions_company_timestamp ON ml_data_volume_predictions(company_id, prediction_timestamp);