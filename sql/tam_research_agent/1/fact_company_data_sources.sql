-- Company Data Sources Fact Table
-- Tracks specific data generation systems per company for bottom-up volume estimation
-- Each row represents one data source/system that generates data for a company

CREATE TABLE fact_company_data_sources (
    -- Primary identifiers
    data_source_id STRING PRIMARY KEY DEFAULT CONCAT('DS_', TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'), '_', ABS(RANDOM())),
    company_id STRING NOT NULL,
    
    -- Data source classification
    source_category VARCHAR(50) NOT NULL COMMENT 'CRM, ERP, IoT, WEB_ANALYTICS, EMAIL, COLLABORATION, DEVELOPMENT, FINANCIAL, MANUFACTURING, CUSTOMER_SUPPORT',
    source_name VARCHAR(100) COMMENT 'Salesforce, SAP, Google Analytics, Slack, GitHub, etc.',
    source_vendor VARCHAR(100),
    deployment_type VARCHAR(50) COMMENT 'CLOUD, ON_PREMISE, HYBRID',
    
    -- Volume estimation
    estimated_volume_gb_monthly DECIMAL(10,3),
    volume_confidence DECIMAL(3,2) COMMENT 'Confidence in volume estimate (0.0 to 1.0)',
    growth_multiplier DECIMAL(4,2) DEFAULT 1.0 COMMENT 'How volume scales with company growth (1.0 = linear)',
    technology_multiplier DECIMAL(4,2) DEFAULT 1.0 COMMENT 'Cloud vs legacy impact on data volume',
    
    -- Data characteristics
    data_characteristics VARIANT COMMENT 'JSON: {velocity: "real-time/batch", variety: "structured/semi/unstructured", retention_days: int, compression_ratio: float}',
    data_velocity VARCHAR(20) COMMENT 'REAL_TIME, NEAR_REAL_TIME, BATCH, STATIC',
    data_variety VARCHAR(20) COMMENT 'STRUCTURED, SEMI_STRUCTURED, UNSTRUCTURED, MIXED',
    retention_days INTEGER,
    
    -- Business context
    business_criticality VARCHAR(20) COMMENT 'CRITICAL, HIGH, MEDIUM, LOW',
    user_base_size INTEGER COMMENT 'Number of users generating data in this system',
    transaction_volume_daily INTEGER COMMENT 'Daily transactions/events',
    
    -- Technology details
    integration_complexity VARCHAR(20) COMMENT 'HIGH, MEDIUM, LOW',
    api_availability BOOLEAN DEFAULT FALSE,
    real_time_access BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    data_source_status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT 'ACTIVE, INACTIVE, MIGRATING, DECOMMISSIONED',
    first_discovered_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    last_validated_date TIMESTAMP_NTZ,
    validation_method VARCHAR(50) COMMENT 'MANUAL_RESEARCH, API_DISCOVERY, CUSTOMER_INTERVIEW, THIRD_PARTY_DATA',
    
    -- Audit fields
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT chk_volume_confidence CHECK (volume_confidence IS NULL OR (volume_confidence >= 0.0 AND volume_confidence <= 1.0)),
    CONSTRAINT chk_growth_multiplier CHECK (growth_multiplier > 0.0),
    CONSTRAINT chk_technology_multiplier CHECK (technology_multiplier > 0.0),
    CONSTRAINT chk_retention_days CHECK (retention_days IS NULL OR retention_days >= 0),
    CONSTRAINT chk_user_base_size CHECK (user_base_size IS NULL OR user_base_size >= 0),
    CONSTRAINT chk_transaction_volume CHECK (transaction_volume_daily IS NULL OR transaction_volume_daily >= 0),
    
    -- Foreign key
    CONSTRAINT fk_data_sources_company FOREIGN KEY (company_id) REFERENCES dim_companies(company_id)
)
COMMENT = 'Fact table tracking data generation systems per company for bottom-up data volume estimation and prediction';

-- Create indexes for performance
CREATE INDEX idx_data_sources_company ON fact_company_data_sources(company_id);
CREATE INDEX idx_data_sources_category ON fact_company_data_sources(source_category);
CREATE INDEX idx_data_sources_status ON fact_company_data_sources(data_source_status);
CREATE INDEX idx_data_sources_criticality ON fact_company_data_sources(business_criticality);
CREATE INDEX idx_data_sources_last_validated ON fact_company_data_sources(last_validated_date);

-- Compound indexes for common queries
CREATE INDEX idx_data_sources_company_category ON fact_company_data_sources(company_id, source_category);
CREATE INDEX idx_data_sources_company_volume ON fact_company_data_sources(company_id, estimated_volume_gb_monthly);