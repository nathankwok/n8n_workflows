# LLM Active Learning Prioritization Agent

## Agent Purpose
Specialized LLM agent that analyzes prediction uncertainty and business value to prioritize which companies should be selected for human verification. This agent optimizes the active learning process by identifying companies that will provide maximum information gain for model improvement.

## Active Learning Prioritization Prompt Template

### System Context
You are an AI systems expert specializing in active learning optimization for machine learning models. Your role is to analyze model predictions, uncertainty measures, and business context to recommend which companies should be prioritized for expensive human verification processes.

### Main Prompt Structure

```
ACTIVE LEARNING PRIORITIZATION TASK

I need to select {budget_count} companies from {total_candidates} candidates for human data volume verification. The goal is to maximize model improvement while considering verification costs and business value.

CURRENT MODEL STATE:
- Model Type: {model_type}
- Training Dataset Size: {training_size} companies
- Current Performance: {current_performance_metrics}
- Last Retrain Date: {last_retrain_date}
- Performance Trend: {performance_trend}

CANDIDATE COMPANIES FOR VERIFICATION:

{candidate_companies}

For each company, I have:
- LLM prediction and confidence
- Traditional ML model predictions (if available)
- Business metadata (industry, size, revenue)
- Verification cost estimate
- Strategic business value

ACTIVE LEARNING ANALYSIS FRAMEWORK:

## 1. UNCERTAINTY-BASED PRIORITIZATION

For each company, analyze the uncertainty signals:

### Model Uncertainty (Epistemic)
- Cross-model disagreement between LLM and traditional ML
- LLM confidence calibration assessment
- Prediction variance across multiple runs
- Feature space coverage (how different is this company from training data)

### Data Uncertainty (Aleatoric)  
- Input data quality and completeness
- Industry-specific estimation difficulty
- Business model complexity factors
- Technology stack novelty

### Compound Uncertainty Score
Combine uncertainty sources into prioritization score:
```
uncertainty_priority = (
    model_disagreement_weight * cross_model_variance +
    confidence_weight * (1 - llm_confidence) +
    novelty_weight * feature_space_distance +
    complexity_weight * estimation_difficulty
)
```

## 2. INFORMATION GAIN ANALYSIS

Assess expected learning value:

### Feature Space Diversity
- How different is this company from already verified companies?
- Does it represent undersampled regions of feature space?
- Will it help model generalize to new company types?

### Representation Learning
- Industry coverage gaps in training data
- Size/scale combinations not well represented  
- Technology stack patterns needing validation
- Business model variants requiring verification

### Error Pattern Investigation
- Does this company represent a systematic error pattern?
- Could verification reveal model bias or blind spots?
- Will it help calibrate confidence estimation?

## 3. BUSINESS VALUE ASSESSMENT

Consider strategic importance:

### Market Significance
- Revenue size and growth potential
- Strategic customer or prospect status
- Market share in important segments
- Competitive intelligence value

### Operational Impact
- Customer success implications
- Sales process efficiency gains
- Product development insights
- Risk mitigation value

### Learning Leverage
- Will insights generalize to similar companies?
- Could verification unlock new market segments?
- Does it validate critical business assumptions?

## 4. COST-BENEFIT OPTIMIZATION

Balance learning value against verification costs:

### Verification Cost Factors
- Data availability and accessibility
- Research complexity and time required
- Expert domain knowledge needed
- Confidence in obtaining accurate ground truth

### Expected ROI Calculation
```
expected_roi = (
    information_gain_score * model_improvement_value +
    business_strategic_value +
    generalization_benefit
) / verification_cost_estimate
```

## 5. PORTFOLIO OPTIMIZATION

Ensure balanced selection across dimensions:

### Diversity Requirements
- Industry distribution balance
- Company size representation
- Geographic coverage
- Technology maturity spectrum
- Business model variety

### Risk Management
- Mix of high-confidence and uncertain predictions
- Balance of strategic and learning-focused selections
- Hedge against verification failures
- Maintain some "safe" choices for calibration

PRIORITIZATION OUTPUT:

Rank all candidate companies and provide detailed reasoning:

```json
{
  "prioritization_metadata": {
    "analysis_timestamp": "ISO_8601_timestamp",
    "total_candidates_analyzed": number,
    "budget_allocation": number,
    "optimization_strategy": "string",
    "model_improvement_focus": ["array_of_focus_areas"]
  },
  "company_rankings": [
    {
      "company_id": "string",
      "company_name": "string", 
      "priority_rank": number,
      "priority_score": number_between_0_and_1,
      "selection_recommendation": "one_of: [high_priority, medium_priority, low_priority, not_recommended]",
      
      "uncertainty_analysis": {
        "model_uncertainty_score": number_between_0_and_1,
        "data_uncertainty_score": number_between_0_and_1,
        "cross_model_disagreement": number,
        "llm_confidence": number_between_0_and_1,
        "prediction_variance": number,
        "feature_space_novelty": number_between_0_and_1
      },
      
      "information_gain_assessment": {
        "expected_information_gain": number_between_0_and_1,
        "feature_space_diversity_value": number_between_0_and_1,
        "representation_gap_filling": number_between_0_and_1,
        "error_pattern_investigation_value": number_between_0_and_1,
        "model_calibration_value": number_between_0_and_1
      },
      
      "business_value": {
        "strategic_importance": number_between_0_and_1,
        "revenue_impact_potential": number,
        "market_significance": "one_of: [low, medium, high, critical]",
        "competitive_intelligence_value": number_between_0_and_1,
        "customer_success_impact": number_between_0_and_1
      },
      
      "cost_benefit": {
        "verification_cost_estimate": number,
        "verification_difficulty": "one_of: [easy, moderate, difficult, very_difficult]",
        "data_accessibility": "one_of: [high, medium, low]",
        "expected_roi": number,
        "time_to_verification_days": number
      },
      
      "selection_reasoning": {
        "primary_selection_factors": ["array_of_key_reasons"],
        "uncertainty_contributions": ["array_of_uncertainty_sources"],
        "business_justification": "string",
        "learning_objectives": ["array_of_learning_goals"],
        "risks_and_mitigations": ["array_of_risk_factors"]
      }
    }
  ],
  
  "portfolio_analysis": {
    "selection_diversity": {
      "industry_distribution": {},
      "size_tier_distribution": {},
      "uncertainty_level_distribution": {},
      "business_value_distribution": {}
    },
    "optimization_trade_offs": {
      "uncertainty_vs_business_value": "string_analysis",
      "cost_vs_information_gain": "string_analysis", 
      "diversity_vs_focus": "string_analysis"
    },
    "expected_outcomes": {
      "model_performance_improvement_estimate": "string",
      "new_market_segments_unlocked": ["array"],
      "bias_reduction_potential": "string",
      "confidence_calibration_improvement": "string"
    }
  },
  
  "strategic_recommendations": {
    "immediate_selections": ["array_of_company_ids"],
    "backup_selections": ["array_of_company_ids"],
    "future_waves": ["array_of_company_ids"],
    "verification_methodology_recommendations": ["array_of_methods"],
    "success_metrics": ["array_of_metrics_to_track"]
  }
}
```

PRIORITIZATION PRINCIPLES:

1. **Maximum Information Gain**: Prioritize companies that will teach the model the most
2. **Uncertainty Resolution**: Focus on high-uncertainty predictions where verification has highest impact  
3. **Diversity Preservation**: Ensure selection covers important feature space regions
4. **Business Alignment**: Balance learning objectives with business strategic value
5. **Cost Efficiency**: Optimize for information gain per dollar spent
6. **Risk Management**: Include hedge selections and validation cases
7. **Generalization**: Choose companies whose insights will transfer broadly

SELECTION GUIDELINES:

- **High Priority (Top 25%)**: Maximum uncertainty + high business value + reasonable cost
- **Medium Priority (Next 35%)**: Strong uncertainty or business value, balanced cost-benefit
- **Low Priority (Next 25%)**: Moderate signals, good for portfolio diversity
- **Not Recommended (Bottom 15%)**: Low information gain, high cost, or redundant

Focus on companies that will:
✓ Resolve significant model uncertainties
✓ Fill gaps in training data representation
✓ Provide insights applicable to similar companies
✓ Validate critical business assumptions
✓ Improve model calibration and confidence estimation

Remember: The goal is model improvement, not just accuracy measurement. Select companies that will make the model better at predicting similar future cases.
```

## Usage Instructions

### Integration with Active Learning Pipeline
```python
def execute_active_learning_cycle(model, unlabeled_pool, budget):
    """Execute one active learning cycle"""
    
    # Generate predictions for all candidates
    candidates = []
    for company in unlabeled_pool:
        llm_pred = llm_predictor.predict(company)
        ml_pred = ml_model.predict(company) if ml_model else None
        
        candidates.append({
            'company_data': company,
            'llm_prediction': llm_pred,
            'ml_prediction': ml_pred,
            'business_metadata': get_business_metadata(company),
            'verification_cost': estimate_verification_cost(company)
        })
    
    # Use LLM to prioritize candidates
    prioritization_prompt = ACTIVE_LEARNING_PROMPT.format(
        budget_count=budget,
        total_candidates=len(candidates),
        candidate_companies=candidates,
        model_type=model.model_type,
        current_performance_metrics=model.get_performance_metrics()
    )
    
    prioritization = llm.generate(prioritization_prompt, temperature=0.1)
    
    # Parse and validate prioritization
    priority_data = json.loads(prioritization)
    selected_companies = priority_data['strategic_recommendations']['immediate_selections']
    
    return selected_companies, priority_data
```

### Verification Queue Management
```python
def manage_verification_queue(prioritization_data, verification_capacity):
    """Manage verification queue based on prioritization"""
    
    # Sort by priority score
    ranked_companies = sorted(
        prioritization_data['company_rankings'],
        key=lambda x: x['priority_score'],
        reverse=True
    )
    
    # Allocate to verification queues
    queues = {
        'immediate': [],
        'scheduled': [],
        'future': []
    }
    
    for i, company in enumerate(ranked_companies):
        if i < verification_capacity['immediate']:
            queues['immediate'].append(company)
        elif i < verification_capacity['immediate'] + verification_capacity['scheduled']:
            queues['scheduled'].append(company)
        else:
            queues['future'].append(company)
    
    return queues
```

### Performance Tracking
```python
def track_active_learning_performance(selections, verification_results, model_performance):
    """Track active learning effectiveness"""
    
    metrics = {
        'information_gain_realized': calculate_actual_information_gain(selections, verification_results),
        'uncertainty_reduction': measure_uncertainty_reduction(selections, verification_results),
        'model_improvement': measure_model_improvement(model_performance),
        'cost_efficiency': calculate_cost_per_improvement(selections, verification_results),
        'selection_accuracy': assess_selection_quality(selections, verification_results)
    }
    
    return metrics
```

## Key Advantages

1. **Intelligent Prioritization**: Considers multiple factors beyond simple uncertainty
2. **Business Alignment**: Balances learning objectives with strategic value
3. **Cost Optimization**: Maximizes information gain per verification dollar
4. **Portfolio Management**: Ensures diverse, balanced selections
5. **Reasoning Transparency**: Provides detailed justification for selections
6. **Adaptive Strategy**: Adjusts priorities based on current model state

This active learning approach transforms random verification into strategic, targeted learning that maximally improves model performance.