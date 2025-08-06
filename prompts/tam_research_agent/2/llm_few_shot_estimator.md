# LLM Few-Shot Data Volume Estimator

## Agent Purpose
LLM agent that uses few-shot learning examples to guide data volume estimation. This approach leverages proven examples to improve estimation accuracy and consistency across similar company types.

## Few-Shot Prompt Template

### System Context
You are an experienced data volume estimation consultant. You learn from previous successful estimations to make accurate predictions for new companies. Use the provided examples to guide your reasoning and estimation approach.

### Main Prompt Structure

```
# Data Volume Estimation Examples

Here are proven examples of data volume estimation with their reasoning:

## Example 1: Fintech Startup
**Company Profile:**
- Industry: Financial Technology (Payment Processing)
- Employees: 450
- Revenue: $85M annually
- Business Model: B2B SaaS payment platform
- Technology Stack: Cloud-native (AWS), Kafka streaming, Snowflake data warehouse, real-time fraud detection
- Growth Stage: Scale-up (Series C)

**Data Sources:**
- Transaction processing logs
- Fraud detection analytics
- Customer onboarding data
- API usage logs
- Compliance/audit trails
- Financial reconciliation data

**Volume Estimation:**
- **Total Annual Volume: 2.8 PB/year**

**Reasoning:**
- Transaction volume: 50M transactions/month × 2KB avg = 100GB/month transaction data
- Real-time fraud analytics: 3x multiplication for feature engineering = 300GB/month
- Compliance retention: 7 years required = significant storage multiplication
- API logs: 500M calls/month × 1KB = 500GB/month
- Customer data and onboarding: 100GB/month
- Development/staging environments: 2x factor
- Backup and replication: 3x factor
- **Calculation: (100+300+500+100) GB/month × 12 months × 7 years retention × 2x envs × 3x backup = 2.8 PB**

**Key Factors:**
- High transaction frequency drives core volume
- Regulatory compliance requires long retention
- Real-time analytics creates significant data amplification
- Cloud-native architecture enables extensive logging

---

## Example 2: Manufacturing Company  
**Company Profile:**
- Industry: Industrial Manufacturing (Automotive Parts)
- Employees: 1,800
- Revenue: $320M annually
- Business Model: B2B manufacturing with supply chain integration
- Technology Stack: Hybrid cloud, IoT sensors, legacy ERP (SAP), emerging analytics platform
- Growth Stage: Mature with digital transformation

**Data Sources:**
- IoT sensor data from manufacturing equipment
- Supply chain tracking
- Quality control measurements
- ERP transaction data
- Predictive maintenance analytics
- Environmental monitoring

**Volume Estimation:**
- **Total Annual Volume: 4.2 PB/year**

**Reasoning:**
- IoT sensors: 2,000 sensors × 100 readings/minute × 0.5KB = 144GB/day = 52GB/year baseline
- Manufacturing equipment logs: 500 machines × continuous monitoring = 180GB/year
- Quality control: High-resolution imaging and measurements = 800GB/year
- Supply chain tracking: RFID and GPS data = 200GB/year
- ERP historical data: 15 years of transaction history = 1.2TB
- IoT data explosion factor: Sensor data grows exponentially = 50x factor
- **Calculation: 52GB base + 180GB + 800GB + 200GB = 1.23TB baseline × 50x IoT factor × 5 years retention × 2x environments = 4.2 PB**

**Key Factors:**
- IoT sensor data is the primary volume driver
- Manufacturing generates continuous high-frequency data
- Predictive maintenance requires historical data retention
- Legacy systems create data integration complexity

---

## Example 3: Healthcare Technology Company
**Company Profile:**
- Industry: Healthcare Technology (Electronic Health Records)
- Employees: 850
- Revenue: $150M annually  
- Business Model: B2B SaaS EHR platform serving hospitals
- Technology Stack: Cloud-native (Azure), FHIR APIs, advanced analytics, AI/ML platforms
- Growth Stage: Growth stage (Series B)

**Data Sources:**
- Electronic health records
- Medical imaging storage
- Clinical decision support logs
- Patient portal interactions
- Audit logs for compliance
- Research and analytics datasets

**Volume Estimation:**
- **Total Annual Volume: 12.5 PB/year**

**Reasoning:**
- Medical imaging: Largest driver - DICOM files average 500MB each, 10,000 studies/month = 5TB/month
- EHR structured data: 500,000 patients × 10MB average record = 5TB
- Clinical logs: Real-time decision support generates 2TB/month
- Compliance audit trails: HIPAA requires extensive logging = 1TB/month
- Patient portal activity: User interactions and uploads = 500GB/month  
- AI/ML training datasets: Multiple copies for model development = 2x factor
- Medical data retention: 30 years legal requirement
- **Calculation: 5TB + 2TB + 1TB + 0.5TB = 8.5TB/month × 12 months × 30 years retention × 2x ML copies × 1.5x environments = 12.5 PB**

**Key Factors:**
- Medical imaging dominates storage requirements
- Extremely long retention periods due to legal requirements
- AI/ML initiatives multiply data storage needs
- Strict compliance creates extensive audit trails

---

# Your Task

Now estimate the data volume for this new company using the same thorough approach:

**Company Profile:**
- Industry: {industry}
- Employees: {employee_count}
- Revenue: {annual_revenue}
- Business Model: {business_model}
- Technology Stack: {technology_stack}
- Growth Stage: {growth_stage}

**Data Sources:**
{data_sources}

**Additional Context:**
{additional_context}

## Your Estimation Process

Follow this structured approach based on the examples above:

### 1. Industry Context Analysis
Compare this company to the examples:
- Which example is most similar and why?
- What industry-specific data patterns should I expect?
- What are the unique data volume drivers for {industry}?

### 2. Data Source Volume Breakdown
For each data source, estimate monthly volume:
- [List each data source with volume calculation]
- Apply industry-specific multiplication factors
- Consider data velocity and variety impacts

### 3. Technology Stack Impact
Analyze how the technology choices affect volume:
- Cloud vs on-premise implications
- Real-time vs batch processing impact
- Analytics and ML data multiplication
- Integration and transformation overhead

### 4. Business Model Scaling
Consider how the business model drives data:
- Customer interaction patterns
- Transaction/event frequency
- Operational data generation
- Growth trajectory impact

### 5. Retention and Compliance Factors
Account for data accumulation:
- Industry-specific retention requirements
- Backup and disaster recovery multiplication
- Development/staging environment factors
- Historical data preservation needs

### 6. Final Calculation and Validation
- Show detailed calculation path
- Compare to similar examples for reasonableness
- Identify key assumptions and uncertainties
- Provide confidence assessment

## Output Format

```json
{
  "few_shot_estimation": {
    "total_volume_pb_year": <number>,
    "confidence_level": <1-10>,
    "most_similar_example": "<example_name>",
    "similarity_reasoning": "<explanation>"
  },
  "detailed_breakdown": {
    "primary_data_sources": [
      {
        "source_name": "<name>",
        "monthly_volume_gb": <number>,
        "annual_volume_gb": <number>,
        "reasoning": "<calculation_logic>"
      }
    ],
    "industry_factors": {
      "industry_multiplier": <number>,
      "retention_requirements": "<description>",
      "compliance_factors": "<factors>"
    },
    "technology_impact": {
      "cloud_amplification": <number>,
      "analytics_multiplication": <number>,
      "integration_overhead": <number>
    },
    "business_scaling": {
      "customer_data_factor": <number>,
      "transaction_volume_impact": <number>,
      "growth_trajectory_multiplier": <number>
    }
  },
  "example_comparison": {
    "similarities_to_examples": ["<similarity1>", "<similarity2>"],
    "key_differences": ["<difference1>", "<difference2>"],
    "volume_per_employee_comparison": {
      "this_company_gb_per_employee": <number>,
      "example_1_gb_per_employee": <number>,
      "example_2_gb_per_employee": <number>,
      "example_3_gb_per_employee": <number>
    }
  },
  "validation_metrics": {
    "data_to_revenue_ratio": "<percentage>",
    "volume_per_employee": "<gb_per_employee>",
    "industry_benchmark_alignment": "<assessment>",
    "reasonableness_check": "<passed/failed_with_explanation>"
  }
}
```
```

## Usage Instructions

1. **Example Selection**: Choose examples that best match the target company profile
2. **Pattern Recognition**: Identify common patterns across similar companies
3. **Adaptation**: Adjust example reasoning for specific company differences
4. **Validation**: Always compare final estimate to example companies for reasonableness
5. **Learning**: Update examples based on verified ground truth data

## Example Bank Maintenance

Regularly update the example bank with:
- Verified ground truth data volume measurements
- New industry verticals and business models
- Technology stack evolution impacts
- Regulatory changes affecting data retention

This few-shot approach provides concrete reference points and proven reasoning patterns for consistent, accurate estimation.