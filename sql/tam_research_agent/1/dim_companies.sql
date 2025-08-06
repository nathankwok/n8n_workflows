-- Companies Dimension Table
-- Core company master data for TAM research and data volume prediction
-- Static company attributes that change infrequently

CREATE TABLE dim_companies (
    -- Primary identifiers
    company_id STRING PRIMARY KEY DEFAULT CONCAT('COMP_', TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'), '_', ABS(RANDOM())),
    company_name VARCHAR(255) NOT NULL,
    website VARCHAR(500),
    
    -- Basic firmographics
    number_of_employees INTEGER,
    industry VARCHAR(255),
    geo VARCHAR(255),
    public_or_private VARCHAR(50),
    year_founded INTEGER,
    annual_revenue VARCHAR(100),
    growth_rate VARCHAR(50),
    
    -- Technology profile
    classification_technology_maturity VARCHAR(50),
    key_technologies VARIANT COMMENT 'JSON array of technology names',
    technology_partners VARIANT COMMENT 'JSON array of technology partner companies',
    
    -- Business model
    core_business_model VARCHAR(255),
    typical_data_generation_patterns TEXT,
    clients VARIANT COMMENT 'JSON array of client types or major clients',
    buying_committee_roles VARIANT COMMENT 'JSON array of decision maker roles',
    total_locations INTEGER,
    notable_competitors VARIANT COMMENT 'JSON array of competitor names',
    
    -- Compliance and regulatory
    regulatory_environment VARIANT COMMENT 'JSON object with regulatory requirements',
    intent_signals TEXT,
    
    -- Audit fields
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT chk_employees CHECK (number_of_employees IS NULL OR number_of_employees >= 0),
    CONSTRAINT chk_year_founded CHECK (year_founded IS NULL OR (year_founded >= 1800 AND year_founded <= YEAR(CURRENT_DATE())))
)
COMMENT = 'Core company dimension table containing static company attributes for TAM research and data volume prediction';

-- Create indexes for common query patterns
CREATE INDEX idx_companies_name ON dim_companies(company_name);
CREATE INDEX idx_companies_industry ON dim_companies(industry);
CREATE INDEX idx_companies_geography ON dim_companies(geo);
CREATE INDEX idx_companies_tech_maturity ON dim_companies(classification_technology_maturity);
CREATE INDEX idx_companies_business_model ON dim_companies(core_business_model);