-- Research Sessions Fact Table
-- Tracks TAM research workflow executions and metadata
-- Links research activities to companies and captures quality metrics

CREATE TABLE fact_research_sessions (
    -- Primary identifiers
    session_id STRING PRIMARY KEY DEFAULT CONCAT('RS_', TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'), '_', ABS(RANDOM())),
    company_id STRING NOT NULL,
    workflow_execution_id STRING,
    
    -- Research phase tracking (supports evolutionary development phases 1-6)
    phase INTEGER NOT NULL DEFAULT 1,
    phase_name VARCHAR(50) COMMENT 'BASIC_RESEARCH, MULTI_AGENT, VALIDATION, CONSENSUS, OPTIMIZATION, SOURCE_VERIFICATION',
    processing_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Research results and quality
    research_results TEXT,
    research_quality_score DECIMAL(3,2) COMMENT 'Overall research quality (0.0 to 1.0)',
    confidence_score DECIMAL(3,2) COMMENT 'Confidence in research findings (0.0 to 1.0)',
    
    -- Multi-agent research results (for phase 2+)
    primary_research TEXT,
    financial_research TEXT,
    technology_research TEXT,
    structured_research_data VARIANT COMMENT 'JSON object with value/source/confidence for each data point',
    
    -- Validation and consensus (for phase 3+)
    validation_status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PASS, FAIL, REQUEST_INFO, PENDING',
    validation_results VARIANT COMMENT 'JSON with validation agent results',
    basic_consensus_score DECIMAL(3,2),
    validation_issues VARIANT COMMENT 'JSON array of validation concerns',
    
    -- Advanced consensus (for phase 4+)
    consensus_metadata VARIANT COMMENT 'Advanced consensus calculation details',
    quality_gate_status VARCHAR(20) COMMENT 'PASS, CONDITIONAL, REVIEW, FAIL',
    retry_count INTEGER DEFAULT 0,
    
    -- Performance metrics (for phase 5+)
    processing_duration_seconds INTEGER,
    token_usage_total INTEGER,
    batch_size INTEGER,
    
    -- Source verification (for phase 6+)
    source_verification_log VARIANT COMMENT 'URL verification and source quality scoring',
    learning_metrics VARIANT COMMENT 'Adaptive learning and improvement metrics',
    
    -- Workflow metadata
    source_workflow_version VARCHAR(20),
    research_agent_versions VARIANT COMMENT 'JSON object with agent names and versions',
    workflow_configuration VARIANT COMMENT 'JSON with workflow parameters and settings',
    
    -- Data lineage and provenance
    data_collection_method VARCHAR(50) COMMENT 'WEB_SCRAPING, API_CALLS, MANUAL_RESEARCH, THIRD_PARTY_DATA',
    external_data_sources VARIANT COMMENT 'JSON array of external sources used',
    data_freshness_hours INTEGER COMMENT 'How many hours old the source data was',
    data_completeness_score DECIMAL(3,2) COMMENT 'Percentage of required fields populated',
    
    -- Error handling and debugging
    error_log VARIANT COMMENT 'JSON array of errors encountered during research',
    warning_log VARIANT COMMENT 'JSON array of warnings during research',
    debug_information VARIANT COMMENT 'JSON with debugging details for troubleshooting',
    
    -- Audit fields
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT chk_phase CHECK (phase BETWEEN 1 AND 6),
    CONSTRAINT chk_research_quality_score CHECK (research_quality_score IS NULL OR (research_quality_score >= 0.0 AND research_quality_score <= 1.0)),
    CONSTRAINT chk_confidence_score CHECK (confidence_score IS NULL OR (confidence_score >= 0.0 AND confidence_score <= 1.0)),
    CONSTRAINT chk_consensus_score CHECK (basic_consensus_score IS NULL OR (basic_consensus_score >= 0.0 AND basic_consensus_score <= 1.0)),
    CONSTRAINT chk_completeness_score CHECK (data_completeness_score IS NULL OR (data_completeness_score >= 0.0 AND data_completeness_score <= 1.0)),
    CONSTRAINT chk_retry_count CHECK (retry_count >= 0),
    CONSTRAINT chk_processing_duration CHECK (processing_duration_seconds IS NULL OR processing_duration_seconds >= 0),
    CONSTRAINT chk_token_usage CHECK (token_usage_total IS NULL OR token_usage_total >= 0),
    CONSTRAINT chk_data_freshness CHECK (data_freshness_hours IS NULL OR data_freshness_hours >= 0),
    
    -- Foreign key
    CONSTRAINT fk_research_sessions_company FOREIGN KEY (company_id) REFERENCES dim_companies(company_id)
)
COMMENT = 'Fact table tracking TAM research workflow executions with quality metrics and phase progression support';

-- Create indexes for performance
CREATE INDEX idx_research_sessions_company ON fact_research_sessions(company_id);
CREATE INDEX idx_research_sessions_phase ON fact_research_sessions(phase);
CREATE INDEX idx_research_sessions_timestamp ON fact_research_sessions(processing_timestamp);
CREATE INDEX idx_research_sessions_validation_status ON fact_research_sessions(validation_status);
CREATE INDEX idx_research_sessions_quality_gate ON fact_research_sessions(quality_gate_status);
CREATE INDEX idx_research_sessions_workflow_execution ON fact_research_sessions(workflow_execution_id);

-- Compound indexes for common queries
CREATE INDEX idx_research_sessions_company_phase ON fact_research_sessions(company_id, phase);
CREATE INDEX idx_research_sessions_company_timestamp ON fact_research_sessions(company_id, processing_timestamp);
CREATE INDEX idx_research_sessions_phase_status ON fact_research_sessions(phase, validation_status);