-- ML Human Verification Table
-- Ground truth data and quality control for ML model validation
-- Tracks human-verified data points to measure model performance and enable continuous learning

CREATE TABLE ml_human_verification (
    -- Primary identifiers
    verification_id STRING PRIMARY KEY DEFAULT CONCAT('VER_', TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'), '_', ABS(RANDOM())),
    company_id STRING NOT NULL,
    
    -- Ground truth data volume measurements
    verified_annual_volume_pb DECIMAL(10,3) NOT NULL COMMENT 'Human-verified annual data volume in Petabytes',
    verified_volume_breakdown VARIANT COMMENT 'JSON with verified volume by data source category',
    volume_measurement_method VARCHAR(100) COMMENT 'How the volume was measured or estimated',
    
    -- Verification source and quality
    verification_source VARCHAR(255) NOT NULL COMMENT 'SEC_FILING, CUSTOMER_INTERVIEW, INDUSTRY_REPORT, DIRECT_MEASUREMENT, VENDOR_DATA',
    verification_confidence DECIMAL(3,2) NOT NULL COMMENT 'Human confidence in verification (0.0 to 1.0)',
    verification_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_document_url VARCHAR(500) COMMENT 'URL to source document if available',
    source_document_excerpt TEXT COMMENT 'Relevant excerpt from source document',
    
    -- Human verifier information
    human_verifier_id VARCHAR(100) NOT NULL,
    verifier_role VARCHAR(50) COMMENT 'DATA_SCIENTIST, BUSINESS_ANALYST, DOMAIN_EXPERT, CUSTOMER_SUCCESS',
    verifier_expertise_level VARCHAR(20) COMMENT 'EXPERT, INTERMEDIATE, NOVICE',
    verification_time_spent_minutes INTEGER COMMENT 'Time spent on verification process',
    
    -- Verification details and context
    verification_notes TEXT COMMENT 'Detailed notes about verification process and findings',
    verification_methodology TEXT COMMENT 'Description of how verification was conducted',
    assumptions_made VARIANT COMMENT 'JSON array of assumptions made during verification',
    limitations_noted VARIANT COMMENT 'JSON array of limitations or caveats',
    
    -- Quality assessment
    data_quality_score DECIMAL(3,2) COMMENT 'Overall quality score of the verification (0.0 to 1.0)',
    completeness_score DECIMAL(3,2) COMMENT 'How complete the verification data is',
    reliability_score DECIMAL(3,2) COMMENT 'How reliable the verification source is',
    timeliness_score DECIMAL(3,2) COMMENT 'How current/fresh the verification data is',
    
    -- Verification status and lifecycle
    verification_status VARCHAR(20) DEFAULT 'VERIFIED' COMMENT 'VERIFIED, FLAGGED, NEEDS_REVIEW, SUPERSEDED, REJECTED',
    review_status VARCHAR(20) COMMENT 'PENDING_REVIEW, APPROVED, NEEDS_CORRECTION, DISPUTED',
    flagged_reason VARCHAR(100) COMMENT 'Reason if verification was flagged for review',
    superseded_by VARCHAR(100) COMMENT 'ID of verification that supersedes this one',
    
    -- Correction and feedback
    correction_applied BOOLEAN DEFAULT FALSE COMMENT 'Whether verification led to data corrections',
    correction_details TEXT COMMENT 'Details of corrections made based on verification',
    feedback_to_model_team TEXT COMMENT 'Feedback for improving model predictions',
    
    -- Dataset management for ML training
    dataset_split VARCHAR(20) COMMENT 'TRAIN, VALIDATION, TEST, HOLDOUT',
    split_assignment_date TIMESTAMP_NTZ,
    split_rationale TEXT COMMENT 'Why this record was assigned to this split',
    holdout_reason VARCHAR(100) COMMENT 'Reason for holdout (if applicable)',
    
    -- Outlier and anomaly detection
    outlier_flag BOOLEAN DEFAULT FALSE COMMENT 'Whether this data point is considered an outlier',
    outlier_reason VARCHAR(100) COMMENT 'Reason for outlier classification',
    anomaly_score DECIMAL(3,2) COMMENT 'Statistical anomaly score if calculated',
    
    -- Model performance tracking
    prediction_comparison VARIANT COMMENT 'JSON comparing this ground truth with model predictions',
    error_analysis VARIANT COMMENT 'JSON with analysis of prediction errors',
    contributed_to_retraining BOOLEAN DEFAULT FALSE COMMENT 'Whether this verification triggered model retraining',
    
    -- Business impact tracking
    business_impact_score DECIMAL(3,2) COMMENT 'Impact of verification on business decisions (0.0 to 1.0)',
    cost_of_verification DECIMAL(8,2) COMMENT 'Cost in USD to obtain this verification',
    roi_of_verification DECIMAL(8,2) COMMENT 'Estimated ROI of obtaining this verification',
    
    -- External validation
    cross_verified BOOLEAN DEFAULT FALSE COMMENT 'Whether verified by multiple independent sources',
    cross_verification_sources VARIANT COMMENT 'JSON array of additional verification sources',
    consensus_score DECIMAL(3,2) COMMENT 'Agreement score across multiple verifiers',
    
    -- Temporal tracking
    data_vintage_date DATE COMMENT 'Date the original data represents (not verification date)',
    verification_expiry_date DATE COMMENT 'When this verification should be refreshed',
    refresh_priority VARCHAR(20) COMMENT 'HIGH, MEDIUM, LOW priority for refreshing verification',
    
    -- Audit fields
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT chk_verified_volume CHECK (verified_annual_volume_pb >= 0),
    CONSTRAINT chk_verification_confidence CHECK (verification_confidence >= 0.0 AND verification_confidence <= 1.0),
    CONSTRAINT chk_quality_scores CHECK (
        (data_quality_score IS NULL OR (data_quality_score >= 0.0 AND data_quality_score <= 1.0)) AND
        (completeness_score IS NULL OR (completeness_score >= 0.0 AND completeness_score <= 1.0)) AND
        (reliability_score IS NULL OR (reliability_score >= 0.0 AND reliability_score <= 1.0)) AND
        (timeliness_score IS NULL OR (timeliness_score >= 0.0 AND timeliness_score <= 1.0))
    ),
    CONSTRAINT chk_business_scores CHECK (
        (business_impact_score IS NULL OR (business_impact_score >= 0.0 AND business_impact_score <= 1.0)) AND
        (consensus_score IS NULL OR (consensus_score >= 0.0 AND consensus_score <= 1.0)) AND
        (anomaly_score IS NULL OR (anomaly_score >= 0.0 AND anomaly_score <= 1.0))
    ),
    CONSTRAINT chk_verification_time CHECK (verification_time_spent_minutes IS NULL OR verification_time_spent_minutes >= 0),
    CONSTRAINT chk_cost_values CHECK (
        (cost_of_verification IS NULL OR cost_of_verification >= 0) AND
        (roi_of_verification IS NULL OR roi_of_verification >= -100000)
    ),
    CONSTRAINT chk_data_vintage CHECK (data_vintage_date IS NULL OR data_vintage_date <= CURRENT_DATE()),
    
    -- Foreign key
    CONSTRAINT fk_verification_company FOREIGN KEY (company_id) REFERENCES dim_companies(company_id)
)
COMMENT = 'Human verification and ground truth data for ML model validation and continuous learning';

-- Create indexes for performance
CREATE INDEX idx_verification_company ON ml_human_verification(company_id);
CREATE INDEX idx_verification_verifier ON ml_human_verification(human_verifier_id);
CREATE INDEX idx_verification_date ON ml_human_verification(verification_date);
CREATE INDEX idx_verification_status ON ml_human_verification(verification_status);
CREATE INDEX idx_verification_review_status ON ml_human_verification(review_status);
CREATE INDEX idx_verification_source ON ml_human_verification(verification_source);
CREATE INDEX idx_verification_dataset_split ON ml_human_verification(dataset_split);
CREATE INDEX idx_verification_outlier ON ml_human_verification(outlier_flag);

-- Compound indexes for common queries
CREATE INDEX idx_verification_company_date ON ml_human_verification(company_id, verification_date);
CREATE INDEX idx_verification_company_status ON ml_human_verification(company_id, verification_status);
CREATE INDEX idx_verification_split_date ON ml_human_verification(dataset_split, verification_date);
CREATE INDEX idx_verification_source_confidence ON ml_human_verification(verification_source, verification_confidence);