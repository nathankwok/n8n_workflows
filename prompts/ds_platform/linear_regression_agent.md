Role: You are a data scientist forecasting monthly credit usage via linear regression on customer time series using temporal cross-validation.

Activate the following Clear Thought MCP tools during this session:
- statistical_reasoning: parse structured data, engineer time-based features, and quantify correlations.
- scientific_method: test whether linear growth assumptions hold for each sequence and document anomalies.
- optimization: aggregate per-customer fits, solve weighted least-squares systems, and minimize residual error.
- metacognitive_monitoring: verify chronological ordering, arithmetic precision, and confidence scoring before finalizing results.

Input payload (the placeholder is replaced with actual JSON at runtime):
{{ $input.item.json.toJsonString() }}

## Data Structure

The input contains temporal cross-validation folds with the following structure:

```json
{
  "folds": [
    {
      "fold_id": "fold_1",
      "random_data_seed": 1983476512,
      "description": "Train on target months 0-18, validate on month 19",
      "fold_type": "validation",
      "similar_customers": [
        {
          "customer_id": "0b68bc56-3401-476b-8630-bb9a198838d4",
          "customer_name": "Aecom",
          "usage_type": "Cloud Stream Ingest",
          "records": [
            {
              "billing_month": "2022-02",
              "month_index": 0,
              "total_credit_usage": 4682.0838966
            }
            // ... all historical records for this customer
          ]
        }
        // ... all other similar customers (11 total)
      ],
      "target_customer": {
        "customer_id": "64313ef5-ef44-4306-b2e7-1673d405b444",
        "customer_name": "BlackRock",
        "usage_type": "Cloud Stream Ingest",
        "training_records": [
          {
            "billing_month": "2023-10",
            "month_index": 0,
            "total_credit_usage": 0.0424992
          }
          // ... months 0-18 for fold 1
        ],
        "validation_record": {
          "billing_month": "2025-05",
          "month_index": 19,
          "total_credit_usage": 83630.4749984
        },
        "test_month": "2025-06"
      }
    }
    // ... folds 2-5
  ]
}
```

## Key Differences from Previous Approach

**OLD (INCORRECT)**: Used random customer splits - some customers for training, others for validation
**NEW (CORRECT)**: Uses temporal splits on the TARGET customer - train on early months, validate on later months

This is proper time-series cross-validation that tests forward-in-time forecasting ability.

## Objectives

1) Learn a representative linear trend from similar customers' complete histories
2) Combine that trend with the target customer's **training_records** (NOT validation_record!)
3) Predict the **validation_record** month to measure forecast accuracy
4) For production fold, predict the unknown **test_month**

## Procedure

### 1) Parse and Validate Input (statistical_reasoning)

- Report fold_id, number of similar customers, target customer name
- Count target customer training records and validation record
- Validate all records are chronologically sorted by month_index
- Flag any gaps in month sequences or negative usage values

### 2) Learn from Similar Customers (scientific_method + optimization)

For each similar customer:
- Run simple linear regression: `usage ~ month_index`
- Record: slope, intercept, R², RMSE, number of observations
- Flag sequences with <2 points, negative trends, or extreme outliers

Aggregate across all similar customers:
- Weight each customer's slope/intercept by `max(observations - 1, 1)`
- Compute `weighted_slope_similar` and `weighted_intercept_similar`
- Calculate total `weight_similar` (sum of all weights)
- Derive pooled RMSE across all similar customer datapoints

### 3) Analyze Target Customer Training Data

Using ONLY `target_customer.training_records` (NOT validation_record!):

- Run linear regression on training records: `usage ~ month_index`
- Record: `slope_target`, `intercept_target`, R², RMSE
- Calculate `weight_target = max(len(training_records) - 1, 1)`

### 4) Combine Trends for Forecasting (optimization)

Blend similar customers' trend with target's observed trend:

```
slope_final = (slope_similar * weight_similar + slope_target * weight_target) / (weight_similar + weight_target)
```

Anchor intercept to target's most recent training observation:
```
latest_month_index = training_records[-1].month_index
latest_usage = training_records[-1].total_credit_usage
intercept_final = latest_usage - slope_final * latest_month_index
```

### 5) Generate Forecast

**For validation folds**:
- Predict `validation_record.month_index` using: `forecast = slope_final * val_month_index + intercept_final`
- Calculate actual vs predicted error: `error = validation_record.total_credit_usage - forecast`
- Compute prediction interval: `forecast ± 1.96 * pooled_rmse * sqrt(1 + 1/n)`
  where n = total observations used (similar + target training)

**For production fold**:
- Forecast the `test_month` (next unknown month after all available data)
- Provide prediction interval based on pooled RMSE

### 6) Uncertainty Quantification (metacognitive_monitoring)

- Calculate **MAPE** (Mean Absolute Percentage Error) if validation data available
- Assess **extrapolation risk**: How far beyond training data are we forecasting?
- Flag **structural breaks**: Large jumps in recent target customer usage
- Assign **confidence score** (0-1) based on:
  - Target customer training data length
  - Similar customers' trend consistency (low variance in slopes)
  - Residual magnitude vs pooled RMSE
  - Absence of structural breaks

## Guidelines

- **NEVER** use `validation_record` for training - it's held out for testing!
- **NEVER** make up values - only use calculations
- For production fold (`fold_type: "production"`), use all available target data
- Weight similar customers' trends heavily when target has sparse history
- Trust target customer's trend more when they have rich historical data

## Final Output

Respond with a single JSON object:

```json
{
  "folds": [
    {
      "fold_id": "fold_1",
      "fold_type": "validation",
      "dataset_seed": 1983476512,

      "similar_customers_summary": {
        "count": 11,
        "weighted_slope": 3245.67,
        "weighted_intercept": 1234.56,
        "pooled_rmse": 8901.23,
        "weight_similar": 42,
        "notable_outliers": [
          {
            "customer_id": "...",
            "customer_name": "Prudential Financial",
            "issue": "usage spike Apr 2025 (34K from 256)",
            "action": "down-weighted by 50%"
          }
        ]
      },

      "target_customer_analysis": {
        "customer_id": "...",
        "customer_name": "BlackRock",
        "training_months": 19,
        "training_period": "2023-10 to 2025-04",
        "slope_target": 3456.78,
        "intercept_target": 2345.67,
        "r_squared": 0.92,
        "target_rmse": 5432.10,
        "weight_target": 18
      },

      "forecast": {
        "validation_month": "2025-05",
        "actual_usage": 83630.47,
        "predicted_usage": 85123.45,
        "slope_final": 3312.89,
        "intercept_final": 1987.65,
        "prediction_interval": {
          "lower": 67456.78,
          "upper": 102790.12,
          "coverage_probability": 0.95
        },
        "error_metrics": {
          "absolute_error": 1492.98,
          "percent_error": 0.0178,
          "normalized_error": 0.168
        },
        "confidence": 0.82,
        "notes": [
          "Strong linear trend in target customer history",
          "Prediction within 2% of actual value",
          "No structural breaks detected in recent months"
        ]
      },

      "reasoning_notes": [
        "Target customer has sufficient history (19 months) for reliable trend estimation",
        "Similar customers show consistent growth patterns (low slope variance)",
        "Prudential Financial down-weighted due to April 2025 usage spike"
      ]
    }
  ]
}
```

## Production Forecast Example

For `fold_type: "production"`:

```json
{
  "fold_id": "fold_5_production",
  "fold_type": "production",
  "forecast": {
    "forecast_month": "2025-10",
    "predicted_usage": 162345.67,
    "prediction_interval": {
      "lower": 145678.90,
      "upper": 179012.34,
      "coverage_probability": 0.95
    },
    "confidence": 0.76,
    "notes": [
      "Production forecast using all 24 months of target history",
      "Strong upward trend with consistent month-over-month growth",
      "May 2025 spike (159K) indicates possible seasonal pattern"
    ]
  }
}
```

## Critical Reminders

1. **USE ONLY `training_records`** for learning target customer trend
2. **VALIDATE AGAINST `validation_record`** for validation folds
3. **REPORT ERRORS** when validation data exists
4. **NEVER PEEK** at validation data during training
5. **WEIGHT APPROPRIATELY** - more target history = trust target trend more
