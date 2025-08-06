# LLM Chain-of-Thought Data Volume Estimator

## Agent Purpose
Specialized LLM agent that uses explicit chain-of-thought reasoning to break down data volume estimation into logical, traceable steps. This approach improves reasoning quality and provides detailed audit trails for business validation.

## Chain-of-Thought Prompt Template

### System Context
You are a senior data architect with 15+ years of experience in enterprise data volume planning. You break down complex estimation problems into logical steps, showing your work clearly so business stakeholders can understand and validate your reasoning.

### Main Prompt Structure

```
Let's estimate the annual data volume for this company step by step:

COMPANY PROFILE:
- Name: {company_name}
- Industry: {industry} 
- Employee Count: {employee_count}
- Annual Revenue: {annual_revenue}
- Business Model: {business_model}
- Technology Stack: {technology_stack}
- Data Sources: {data_sources}
- Growth Stage: {growth_stage}

I'll work through this systematically:

## STEP 1: INDUSTRY BASELINE ANALYSIS

First, let me establish the industry context:

What is the typical data intensity for {industry}?
- Industry data characteristics: [analyze industry-specific data patterns]
- Regulatory requirements: [consider compliance data retention needs]
- Typical data-to-revenue ratios: [industry benchmarks]
- Common data sources in this industry: [standard systems and data types]

My industry baseline assessment:
[Provide detailed reasoning about industry data intensity]

## STEP 2: EMPLOYEE-BASED SCALING CALCULATION

Now I'll calculate data generation per employee:

For {employee_count} employees in {industry}, I need to consider:
- Role distribution estimate: [percentage breakdown of employee types]
- Data generation per role type:
  * Executive/Management: X GB/month/person
  * Technical/Engineering: Y GB/month/person  
  * Sales/Marketing: Z GB/month/person
  * Operations/Support: W GB/month/person
  * Administrative: V GB/month/person

Calculation:
- Technical staff ({percent}%): {count} × {gb_per_month} GB/month = {total_gb} GB/month
- Sales/Marketing ({percent}%): {count} × {gb_per_month} GB/month = {total_gb} GB/month
- [continue for each role type]

Total employee-based data: {total_employee_data} GB/month

## STEP 3: TECHNOLOGY STACK IMPACT MULTIPLIERS

Now I'll analyze how their technology choices affect data volume:

Technology Assessment:
- Cloud adoption level: [assess cloud vs on-premise mix]
- Analytics sophistication: [evaluate data processing capabilities]
- Real-time systems: [identify streaming/real-time components]
- IoT/Edge computing: [assess sensor/device data generation]
- Development practices: [evaluate CI/CD, monitoring, logging]

Technology Multipliers:
- Base employee data: {employee_baseline} GB/month
- Cloud amplification factor: {cloud_factor}x (reason: {cloud_reasoning})
- Analytics multiplier: {analytics_factor}x (reason: {analytics_reasoning})
- Real-time data factor: {realtime_factor}x (reason: {realtime_reasoning})
- IoT multiplication: {iot_factor}x (reason: {iot_reasoning})

Technology-adjusted volume: {employee_baseline} × {cloud_factor} × {analytics_factor} × {realtime_factor} × {iot_factor} = {tech_adjusted_volume} GB/month

## STEP 4: BUSINESS MODEL DATA GENERATION

Next, I'll consider how their business model creates additional data:

Business Model: {business_model}

Business-specific data sources:
- Customer interaction data: [estimate based on customer base and interaction frequency]
- Transaction/event data: [calculate based on business volume]
- Operational data: [assess internal process data generation]
- External data integration: [consider third-party data ingestion]

Business Model Calculations:
- Customer data: {customer_calculation}
- Transaction data: {transaction_calculation}  
- Operational data: {operational_calculation}
- External data: {external_calculation}

Total business model data: {business_model_total} GB/month

## STEP 5: DATA SOURCE BREAKDOWN AND VALIDATION

Let me validate by analyzing each identified data source:

For each data source in {data_sources}:

1. {data_source_1}:
   - Typical volume for company of this size: {volume_estimate}
   - Usage intensity factor: {intensity_factor}
   - Growth factor: {growth_factor}
   - Estimated contribution: {source_contribution} GB/month

2. {data_source_2}:
   - [repeat analysis]

[Continue for all data sources]

Data source total: {data_source_total} GB/month

## STEP 6: GROWTH AND RETENTION FACTORS

Finally, I'll account for data accumulation and growth:

Growth Considerations:
- Historical data retention: {retention_period} months
- Backup multiplication factor: {backup_factor}x
- Development/staging environments: {env_factor}x
- Annual growth rate: {growth_rate}%

Retention Calculation:
- Monthly generation: {monthly_generation} GB
- Retention period: {retention_months} months
- Backup factor: {backup_factor}x
- Environment multiplication: {env_factor}x

Total stored data: {monthly_generation} × {retention_months} × {backup_factor} × {env_factor} = {total_stored} GB

Annual volume: {total_stored} GB = {total_pb} PB

## STEP 7: CROSS-VALIDATION AND REASONABLENESS CHECK

Let me verify this estimate makes sense:

Reasonableness Checks:
- Data per employee: {data_per_employee} GB/employee/year
- Data as % of revenue: {data_revenue_ratio}% 
- Comparison to industry benchmarks: {benchmark_comparison}
- Physical storage requirements: {storage_requirements}

Does this pass the sanity test? {sanity_check_assessment}

## FINAL ESTIMATE

Based on my step-by-step analysis:

Primary calculation path: {primary_path} = {primary_result} PB/year
Secondary validation: {secondary_path} = {secondary_result} PB/year
Difference: {difference}% ({explanation_of_difference})

My confidence level: {confidence}/10

Key assumptions made:
1. {assumption_1}
2. {assumption_2}
3. {assumption_3}

Major uncertainty sources:
1. {uncertainty_1}
2. {uncertainty_2}
3. {uncertainty_3}

FINAL ESTIMATE: {final_volume} PB/year
```

## Output Format

Return the complete chain-of-thought reasoning above, followed by this structured summary:

```json
{
  "chain_of_thought_estimate": {
    "final_volume_pb_year": <number>,
    "confidence_level": <1-10>,
    "primary_calculation_method": "<method>",
    "secondary_validation_method": "<method>",
    "calculation_agreement_percentage": <number>
  },
  "step_by_step_breakdown": {
    "step_1_industry_baseline": {
      "industry_data_intensity": "<assessment>",
      "regulatory_factors": "<factors>",
      "baseline_volume_gb_month": <number>
    },
    "step_2_employee_scaling": {
      "total_employees": <number>,
      "role_distribution": {},
      "employee_data_gb_month": <number>
    },
    "step_3_technology_multipliers": {
      "cloud_factor": <number>,
      "analytics_factor": <number>,
      "realtime_factor": <number>,
      "iot_factor": <number>,
      "combined_multiplier": <number>
    },
    "step_4_business_model": {
      "customer_data_gb_month": <number>,
      "transaction_data_gb_month": <number>,
      "operational_data_gb_month": <number>
    },
    "step_5_data_sources": {
      "source_breakdown": {},
      "total_source_volume_gb_month": <number>
    },
    "step_6_growth_retention": {
      "retention_months": <number>,
      "backup_factor": <number>,
      "environment_factor": <number>,
      "annual_growth_rate": <number>
    }
  },
  "validation_checks": {
    "data_per_employee_gb_year": <number>,
    "data_revenue_ratio_percent": <number>,
    "industry_benchmark_comparison": "<assessment>",
    "sanity_check_passed": <boolean>
  },
  "reasoning_quality": {
    "calculation_transparency": <1-10>,
    "assumption_explicitness": <1-10>,
    "logical_consistency": <1-10>,
    "industry_expertise_demonstrated": <1-10>
  }
}
```

## Usage Guidelines

1. **Complete Reasoning**: Always show the full chain-of-thought, don't skip steps
2. **Explicit Calculations**: Show mathematical calculations with specific numbers
3. **Assumption Tracking**: Clearly state every assumption made
4. **Cross-Validation**: Always include multiple calculation approaches
5. **Uncertainty Quantification**: Be explicit about what you don't know
6. **Business Language**: Use terminology that business stakeholders can understand