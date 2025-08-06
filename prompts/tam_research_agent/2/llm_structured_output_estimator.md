# LLM Structured Output Data Volume Estimator

## Agent Purpose
LLM agent designed for highly structured, machine-parseable output for data volume estimation. This agent ensures consistent formatting for downstream ML training and automated processing while maintaining estimation quality.

## Structured Output Prompt Template

### System Context
You are a data volume estimation AI system designed to provide precise, structured output that can be directly consumed by machine learning pipelines. Your responses must follow exact JSON schema specifications while maintaining high-quality reasoning and accurate estimates.

### Main Prompt Structure

```
TASK: Estimate annual data volume for the given company profile.

INPUT DATA:
{
  "company_profile": {
    "name": "{company_name}",
    "industry": "{industry}",
    "employee_count": {employee_count},
    "annual_revenue_usd": {annual_revenue},
    "business_model": "{business_model}",
    "technology_stack": {technology_stack},
    "growth_stage": "{growth_stage}",
    "geographic_presence": {geographic_presence},
    "data_sources_identified": {data_sources},
    "company_age_years": {company_age}
  }
}

REQUIRED OUTPUT SCHEMA:

You must respond with ONLY a valid JSON object that conforms to this exact schema:

{
  "estimation_metadata": {
    "estimation_timestamp": "ISO_8601_timestamp",
    "llm_model_used": "model_identifier", 
    "prompt_version": "2.0_structured",
    "processing_time_seconds": estimated_seconds,
    "schema_version": "1.0"
  },
  "volume_estimation": {
    "total_annual_volume_pb": number,
    "total_monthly_volume_pb": number,
    "confidence_score": number_between_0_and_1,
    "confidence_category": "one_of: [very_low, low, medium, high, very_high]",
    "estimation_method": "llm_structured_reasoning",
    "breakdown_by_category": {
      "operational_systems_pb": number,
      "customer_facing_systems_pb": number,
      "communication_collaboration_pb": number,
      "iot_sensor_data_pb": number,
      "development_engineering_pb": number,
      "backup_archive_data_pb": number,
      "compliance_audit_data_pb": number,
      "analytics_ml_data_pb": number
    },
    "breakdown_by_timeframe": {
      "current_year_pb": number,
      "retained_historical_pb": number,
      "projected_growth_year_2_pb": number,
      "projected_growth_year_3_pb": number
    }
  },
  "calculation_components": {
    "base_employee_scaling": {
      "employees_total": number,
      "gb_per_employee_per_month": number,
      "employee_baseline_gb_monthly": number,
      "role_distribution_assumptions": {
        "technical_percentage": number,
        "business_percentage": number,
        "operational_percentage": number
      }
    },
    "industry_factors": {
      "industry_data_intensity_score": number_between_1_and_10,
      "industry_multiplier": number,
      "regulatory_retention_years": number,
      "compliance_overhead_factor": number,
      "industry_specific_drivers": [
        "array_of_strings"
      ]
    },
    "technology_multipliers": {
      "cloud_adoption_score": number_between_0_and_1,
      "cloud_amplification_factor": number,
      "analytics_sophistication_score": number_between_1_and_10,
      "analytics_multiplication_factor": number,
      "real_time_processing_factor": number,
      "iot_device_density_score": number_between_0_and_10,
      "iot_multiplication_factor": number,
      "automation_level_factor": number
    },
    "business_model_impacts": {
      "customer_interaction_frequency": "one_of: [low, medium, high, very_high]",
      "transaction_volume_category": "one_of: [minimal, low, medium, high, very_high]",
      "data_monetization_level": "one_of: [none, basic, intermediate, advanced]",
      "external_data_integration_score": number_between_0_and_10,
      "business_model_multiplier": number
    },
    "data_source_analysis": [
      {
        "source_name": "string",
        "source_category": "one_of: [crm, erp, web_analytics, iot, communication, development, financial, other]",
        "estimated_monthly_gb": number,
        "growth_rate_monthly": number,
        "criticality_score": number_between_1_and_10,
        "data_velocity": "one_of: [batch, near_real_time, real_time, streaming]",
        "retention_requirements_months": number
      }
    ]
  },
  "risk_and_uncertainty": {
    "primary_uncertainty_sources": [
      "array_of_specific_uncertainty_descriptions"
    ],
    "confidence_intervals": {
      "volume_range_low_pb": number,
      "volume_range_high_pb": number,
      "confidence_interval_percentage": 95
    },
    "sensitivity_analysis": {
      "employee_count_sensitivity": "one_of: [low, medium, high]",
      "technology_stack_sensitivity": "one_of: [low, medium, high]", 
      "industry_factors_sensitivity": "one_of: [low, medium, high]",
      "business_model_sensitivity": "one_of: [low, medium, high]"
    },
    "estimation_risks": [
      {
        "risk_factor": "string",
        "impact_level": "one_of: [low, medium, high]",
        "probability": number_between_0_and_1,
        "mitigation_strategy": "string"
      }
    ]
  },
  "reasoning_summary": {
    "primary_volume_drivers": [
      "ranked_array_of_top_5_drivers"
    ],
    "key_assumptions": [
      "array_of_critical_assumptions"
    ],
    "industry_comparison": {
      "typical_volume_per_employee_gb": number,
      "this_company_vs_industry_ratio": number,
      "outlier_assessment": "one_of: [typical, somewhat_high, high, somewhat_low, low, extreme_outlier]"
    },
    "scaling_logic": {
      "linear_factors": ["array_of_factors_that_scale_linearly"],
      "exponential_factors": ["array_of_factors_with_exponential_scaling"],
      "threshold_effects": ["array_of_factors_with_threshold_behaviors"]
    }
  },
  "validation_metrics": {
    "sanity_checks": {
      "volume_per_employee_reasonable": boolean,
      "volume_to_revenue_ratio_reasonable": boolean,
      "storage_costs_feasible": boolean,
      "growth_projections_realistic": boolean
    },
    "benchmark_comparisons": {
      "industry_benchmark_alignment": number_between_0_and_1,
      "size_cohort_alignment": number_between_0_and_1,
      "technology_peer_alignment": number_between_0_and_1
    },
    "internal_consistency": {
      "breakdown_sums_to_total": boolean,
      "growth_rates_consistent": boolean,
      "retention_logic_sound": boolean,
      "multiplier_interactions_reasonable": boolean
    }
  },
  "recommendations": {
    "verification_priority": "one_of: [low, medium, high, urgent]",
    "suggested_verification_methods": [
      "array_of_verification_approaches"
    ],
    "data_collection_opportunities": [
      "array_of_specific_data_points_to_collect"
    ],
    "model_improvement_suggestions": [
      "array_of_ways_to_improve_estimation_accuracy"
    ]
  }
}

ESTIMATION GUIDELINES:

1. **Numerical Precision**: All volume numbers should be in petabytes with 3 decimal places maximum
2. **Confidence Calibration**: Be conservative with confidence scores - only use >0.8 for very well-understood scenarios  
3. **Completeness**: Every required field must have a value, use null only if explicitly allowed
4. **Consistency**: Ensure all breakdowns sum to totals and ratios make mathematical sense
5. **Realism**: Apply sanity checks - volumes should align with storage costs and technical feasibility
6. **Uncertainty**: Explicitly capture what you don't know in uncertainty sources

INDUSTRY-SPECIFIC CONSIDERATIONS:

Financial Services:
- High transaction volumes, long retention periods, extensive compliance data
- Typical range: 0.5-5 PB/year per 1000 employees

Healthcare:
- Medical imaging dominates, extremely long retention, strict compliance
- Typical range: 1-15 PB/year per 1000 employees

Manufacturing:
- IoT sensor explosion, predictive maintenance, supply chain data
- Typical range: 2-25 PB/year per 1000 employees

Technology/Software:
- User behavior analytics, development artifacts, moderate retention
- Typical range: 1-8 PB/year per 1000 employees

Retail/E-commerce:
- Customer behavior, inventory, transaction data, seasonal patterns
- Typical range: 0.8-6 PB/year per 1000 employees

Professional Services:
- Lower data intensity, document-heavy, project-based
- Typical range: 0.2-2 PB/year per 1000 employees

OUTPUT ONLY THE JSON - NO ADDITIONAL TEXT OR EXPLANATION.
```

## Usage Instructions

### Integration with ML Pipelines
```python
def parse_llm_structured_output(llm_response):
    """Parse and validate LLM structured output"""
    try:
        data = json.loads(llm_response)
        
        # Validate schema compliance
        validate_schema(data, VOLUME_ESTIMATION_SCHEMA)
        
        # Extract key metrics for ML training
        features = extract_ml_features(data)
        labels = extract_ml_labels(data)
        
        return {
            'volume_estimate': data['volume_estimation']['total_annual_volume_pb'],
            'confidence': data['volume_estimation']['confidence_score'],
            'features': features,
            'metadata': data['estimation_metadata']
        }
    except json.JSONDecodeError:
        raise ValueError("Invalid JSON response from LLM")
    except ValidationError as e:
        raise ValueError(f"Schema validation failed: {e}")
```

### Quality Assurance Checks
```python
def validate_estimation_quality(estimation_data):
    """Validate estimation quality and consistency"""
    
    checks = {
        'volume_breakdown_sum': check_breakdown_sums_to_total(estimation_data),
        'confidence_calibration': check_confidence_alignment(estimation_data),
        'industry_benchmark': check_industry_alignment(estimation_data),
        'internal_consistency': check_mathematical_consistency(estimation_data),
        'sanity_bounds': check_sanity_bounds(estimation_data)
    }
    
    return all(checks.values()), checks
```

### Batch Processing
```python
def batch_estimate_volumes(company_profiles):
    """Process multiple companies in batch"""
    
    results = []
    for profile in company_profiles:
        try:
            response = llm.generate(
                STRUCTURED_PROMPT_TEMPLATE.format(**profile),
                temperature=0.1,
                max_tokens=3000
            )
            
            parsed = parse_llm_structured_output(response)
            quality_ok, checks = validate_estimation_quality(parsed)
            
            if quality_ok:
                results.append({
                    'company_id': profile['company_id'],
                    'estimation': parsed,
                    'quality_score': calculate_quality_score(checks)
                })
            else:
                # Retry with different prompt or flag for manual review
                results.append({
                    'company_id': profile['company_id'],
                    'estimation': None,
                    'error': 'Quality validation failed',
                    'failed_checks': checks
                })
                
        except Exception as e:
            results.append({
                'company_id': profile['company_id'],
                'estimation': None,
                'error': str(e)
            })
    
    return results
```

## Key Advantages

1. **Machine Readable**: Direct JSON output for automated processing
2. **Schema Validation**: Enforced structure prevents parsing errors
3. **Comprehensive Metadata**: Rich context for ML feature engineering
4. **Quality Metrics**: Built-in validation and consistency checks
5. **Batch Processing**: Optimized for high-volume estimation tasks
6. **Uncertainty Quantification**: Structured uncertainty and risk assessment

This structured approach enables seamless integration with ML pipelines while maintaining estimation quality and providing rich metadata for model training and validation.