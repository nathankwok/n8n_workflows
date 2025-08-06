-- TAM Research Results Table Schema
-- Supporting evolutionary development phases 1-6
-- Based on TAM_Research_Phase1_Basic workflow and supporting documentation

CREATE TABLE tam_research_results_evolutionary (
    -- Primary identifiers
    id STRING DEFAULT CONCAT('TAM_', TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'), '_', ABS(RANDOM())),
    company_name VARCHAR(255) NOT NULL,
    website VARCHAR(500),
    
    -- Workflow metadata
    phase INTEGER NOT NULL DEFAULT 1,
    processing_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    workflow_execution_id STRING,
    
    -- Phase 1: Basic research results
    research_results TEXT,
    confidence_score DECIMAL(3,2),
    
    -- Phase 2: Multi-agent results (future enhancement)
    primary_research TEXT,
    financial_research TEXT,
    technology_research TEXT,
    
    -- Structured research data (from research_agent.md specification)
    structured_research_data VARIANT COMMENT 'JSON object with value/source/confidence for each data point',
    
    -- Core company data extracted fields (for easier querying)
    number_of_employees INTEGER,
    industry VARCHAR(255),
    geo VARCHAR(255),
    public_or_private VARCHAR(50),
    year_founded INTEGER,
    annual_revenue VARCHAR(100),
    growth_rate VARCHAR(50),
    
    -- Technology profile
    classification_technology_maturity VARCHAR(50),
    key_technologies VARIANT,
    technology_partners VARIANT,
    
    -- Business model
    core_business_model VARCHAR(255),
    typical_data_generation_patterns TEXT,
    clients VARIANT,
    buying_committee_roles VARIANT,
    total_locations INTEGER,
    notable_competitors VARIANT,
    
    -- Compliance and regulatory
    regulatory_environment VARIANT,
    intent_signals TEXT,
    
    -- Data volume estimation (from estimator_agent.md)
    estimated_annual_data_volume_pb DECIMAL(10,3) COMMENT 'Estimated annual data volume in Petabytes',
    estimation_rationale TEXT,
    estimation_confidence DECIMAL(3,2),
    
    -- Phase 3: Validation results (future enhancement)
    validation_results VARIANT COMMENT 'JSON with validation agent results',
    basic_consensus_score DECIMAL(3,2),
    validation_status VARCHAR(20) DEFAULT 'PENDING', -- PASS, FAIL, REQUEST_INFO
    validation_issues VARIANT,
    
    -- Phase 4: Advanced consensus (future enhancement)
    consensus_metadata VARIANT COMMENT 'Advanced consensus calculation details',
    quality_gate_status VARCHAR(20), -- PASS, CONDITIONAL, REVIEW, FAIL
    retry_count INTEGER DEFAULT 0,
    
    -- Phase 5: Performance optimization (future enhancement)
    processing_duration_seconds INTEGER,
    token_usage_total INTEGER,
    batch_size INTEGER,
    
    -- Phase 6: Source verification (future enhancement)
    source_verification_log VARIANT COMMENT 'URL verification and source quality scoring',
    learning_metrics VARIANT COMMENT 'Adaptive learning and improvement metrics',
    
    -- Audit fields
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT chk_phase CHECK (phase BETWEEN 1 AND 6),
    CONSTRAINT chk_confidence_score CHECK (confidence_score IS NULL OR (confidence_score >= 0.0 AND confidence_score <= 1.0)),
    CONSTRAINT chk_estimation_confidence CHECK (estimation_confidence IS NULL OR (estimation_confidence >= 0.0 AND estimation_confidence <= 1.0)),
    CONSTRAINT chk_consensus_score CHECK (basic_consensus_score IS NULL OR (basic_consensus_score >= 0.0 AND basic_consensus_score <= 1.0))
)
COMMENT = 'Evolutionary TAM research results supporting 6-phase development from basic research to advanced multi-agent consensus validation';

-- Create indexes for common query patterns
CREATE INDEX idx_tam_company_name ON tam_research_results_evolutionary(company_name);
CREATE INDEX idx_tam_phase ON tam_research_results_evolutionary(phase);
CREATE INDEX idx_tam_processing_timestamp ON tam_research_results_evolutionary(processing_timestamp);
CREATE INDEX idx_tam_industry ON tam_research_results_evolutionary(industry);
CREATE INDEX idx_tam_validation_status ON tam_research_results_evolutionary(validation_status);