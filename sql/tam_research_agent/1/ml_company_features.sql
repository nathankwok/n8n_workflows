-- ML Company Features Table (Feature Store)
-- Engineered features derived from company data for ML model training and inference
-- Supports versioning and lineage tracking for reproducible ML experiments

CREATE TABLE ml_company_features (
    -- Primary identifiers
    feature_id STRING PRIMARY KEY DEFAULT CONCAT('FEAT_', TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'), '_', ABS(RANDOM())),
    company_id STRING NOT NULL,
    session_id STRING,
    
    -- Feature metadata
    feature_version VARCHAR(20) NOT NULL,
    feature_extraction_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    feature_hash VARCHAR(64) COMMENT 'Hash of feature values for drift detection',
    feature_completeness_score DECIMAL(3,2) COMMENT 'Percentage of features successfully extracted',
    
    -- Company scale features (for data volume prediction)
    employee_count_log DECIMAL(6,3) COMMENT 'Log transform of employee count',
    revenue_per_employee DECIMAL(10,2) COMMENT 'Annual revenue divided by employee count',
    revenue_growth_rate DECIMAL(5,2) COMMENT 'Year-over-year revenue growth percentage',
    company_age_years INTEGER COMMENT 'Years since founding',
    geographic_presence_score DECIMAL(3,2) COMMENT '0-1 score based on number of locations/countries',
    
    -- Technology profile features
    technology_stack_complexity_score DECIMAL(3,2) COMMENT '0-1 score based on number and sophistication of technologies',
    cloud_adoption_percentage DECIMAL(3,2) COMMENT 'Percentage of systems that are cloud-based',
    data_maturity_index DECIMAL(3,2) COMMENT '0-1 score indicating data infrastructure sophistication',
    api_integration_score DECIMAL(3,2) COMMENT '0-1 score based on API availability and usage',
    automation_level_score DECIMAL(3,2) COMMENT '0-1 score indicating process automation maturity',
    
    -- Industry and business model features
    industry_data_intensity_multiplier DECIMAL(4,2) COMMENT 'Industry-specific data generation multiplier',
    business_model_data_factor DECIMAL(4,2) COMMENT 'Business model impact on data volume',
    customer_interaction_complexity DECIMAL(3,2) COMMENT '0-1 score based on customer touchpoints',
    transaction_intensity_score DECIMAL(3,2) COMMENT '0-1 score based on transaction volume and frequency',
    regulatory_compliance_burden DECIMAL(3,2) COMMENT '0-1 score indicating data retention requirements',
    
    -- Data source derived features
    total_operational_systems INTEGER COMMENT 'Count of operational data sources (CRM, ERP, etc.)',
    customer_facing_systems_count INTEGER COMMENT 'Count of customer-facing data sources',
    iot_sensor_density_score DECIMAL(3,2) COMMENT '0-1 score based on IoT and sensor usage',
    communication_systems_count INTEGER COMMENT 'Count of communication and collaboration systems',
    development_systems_count INTEGER COMMENT 'Count of development and engineering systems',
    
    -- Volume prediction features
    baseline_volume_per_employee DECIMAL(8,3) COMMENT 'GB per employee per month baseline',
    technology_volume_multiplier DECIMAL(4,2) COMMENT 'Technology stack impact on volume',
    growth_stage_multiplier DECIMAL(4,2) COMMENT 'Company growth stage impact (startup vs mature)',
    data_retention_multiplier DECIMAL(4,2) COMMENT 'Data retention policy impact on storage volume',
    real_time_data_percentage DECIMAL(3,2) COMMENT 'Percentage of data sources generating real-time data',
    
    -- Derived aggregate features
    estimated_total_users INTEGER COMMENT 'Sum of user bases across all systems',
    estimated_daily_transactions INTEGER COMMENT 'Sum of daily transactions across all systems',
    high_criticality_systems_percentage DECIMAL(3,2) COMMENT 'Percentage of systems marked as business critical',
    data_source_diversity_score DECIMAL(3,2) COMMENT '0-1 score based on variety of data source categories',
    integration_complexity_average DECIMAL(3,2) COMMENT 'Average integration complexity across data sources',
    
    -- Time-based features (for trend analysis)
    quarter_of_year INTEGER COMMENT 'Quarter when features were extracted (1-4)',
    month_of_year INTEGER COMMENT 'Month when features were extracted (1-12)',
    day_of_week INTEGER COMMENT 'Day of week when features were extracted (1-7)',
    is_end_of_quarter BOOLEAN COMMENT 'Whether extraction was at end of business quarter',
    
    -- Feature engineering metadata
    raw_feature_sources VARIANT COMMENT 'JSON mapping features to their source tables/columns',
    transformation_log VARIANT COMMENT 'JSON log of transformations applied to create features',
    missing_value_strategy VARIANT COMMENT 'JSON describing how missing values were handled',
    outlier_treatment_log VARIANT COMMENT 'JSON describing outlier detection and treatment',
    
    -- Model training metadata
    dataset_split VARCHAR(20) COMMENT 'TRAIN, VALIDATION, TEST, HOLDOUT',
    split_assignment_date TIMESTAMP_NTZ,
    split_strategy VARCHAR(50) COMMENT 'RANDOM, TEMPORAL, STRATIFIED_BY_INDUSTRY',
    cross_validation_fold INTEGER COMMENT 'Fold number for cross-validation experiments',
    
    -- Audit fields
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT chk_feature_completeness CHECK (feature_completeness_score IS NULL OR (feature_completeness_score >= 0.0 AND feature_completeness_score <= 1.0)),
    CONSTRAINT chk_employee_count_log CHECK (employee_count_log IS NULL OR employee_count_log >= 0),
    CONSTRAINT chk_revenue_per_employee CHECK (revenue_per_employee IS NULL OR revenue_per_employee >= 0),
    CONSTRAINT chk_company_age CHECK (company_age_years IS NULL OR company_age_years >= 0),
    CONSTRAINT chk_score_ranges CHECK (
        (geographic_presence_score IS NULL OR (geographic_presence_score >= 0.0 AND geographic_presence_score <= 1.0)) AND
        (technology_stack_complexity_score IS NULL OR (technology_stack_complexity_score >= 0.0 AND technology_stack_complexity_score <= 1.0)) AND
        (cloud_adoption_percentage IS NULL OR (cloud_adoption_percentage >= 0.0 AND cloud_adoption_percentage <= 1.0)) AND
        (data_maturity_index IS NULL OR (data_maturity_index >= 0.0 AND data_maturity_index <= 1.0))
    ),
    CONSTRAINT chk_counts CHECK (
        (total_operational_systems IS NULL OR total_operational_systems >= 0) AND
        (customer_facing_systems_count IS NULL OR customer_facing_systems_count >= 0) AND
        (communication_systems_count IS NULL OR communication_systems_count >= 0) AND
        (development_systems_count IS NULL OR development_systems_count >= 0)
    ),
    CONSTRAINT chk_quarter CHECK (quarter_of_year IS NULL OR (quarter_of_year >= 1 AND quarter_of_year <= 4)),
    CONSTRAINT chk_month CHECK (month_of_year IS NULL OR (month_of_year >= 1 AND month_of_year <= 12)),
    CONSTRAINT chk_day_of_week CHECK (day_of_week IS NULL OR (day_of_week >= 1 AND day_of_week <= 7)),
    
    -- Foreign keys
    CONSTRAINT fk_features_company FOREIGN KEY (company_id) REFERENCES dim_companies(company_id),
    CONSTRAINT fk_features_session FOREIGN KEY (session_id) REFERENCES fact_research_sessions(session_id)
)
COMMENT = 'ML feature store containing engineered features for data volume prediction and other ML models';

-- Create indexes for performance
CREATE INDEX idx_features_company ON ml_company_features(company_id);
CREATE INDEX idx_features_session ON ml_company_features(session_id);
CREATE INDEX idx_features_version ON ml_company_features(feature_version);
CREATE INDEX idx_features_extraction_time ON ml_company_features(feature_extraction_timestamp);
CREATE INDEX idx_features_dataset_split ON ml_company_features(dataset_split);
CREATE INDEX idx_features_hash ON ml_company_features(feature_hash);

-- Compound indexes for common ML queries
CREATE INDEX idx_features_company_version ON ml_company_features(company_id, feature_version);
CREATE INDEX idx_features_split_version ON ml_company_features(dataset_split, feature_version);
CREATE INDEX idx_features_company_timestamp ON ml_company_features(company_id, feature_extraction_timestamp);