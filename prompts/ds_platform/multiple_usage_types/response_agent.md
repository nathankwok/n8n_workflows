<task>
1. Go through the input array of target customer predictions.
2. For each target customer, extract only the production forecasts (fold_5_production) for each usage type.
3. Get the values for `predicted_usage`, `forecast_month`, `lower`, and `upper` from the 3 test_forecasts for each production forecast.
4. Extract historical trend information from `target_customer_analysis` including `recent_history` and `slope_final`.
5. Craft a well formatted slack_message in the tone of a helpful data analyst, grouping predictions by customer and then by usage type, keeping in mind everything in the slack_message_format.
6. Finally, output in a structured JSON output format with the following keys:
- message
</task>

<input>
{{ $json.output.toJsonString() }}
</input>

<guidelines>

<parsing_input>
The input is an array of target customer prediction objects. Each object has:
- `target_customer_id`: The customer identifier
- `usage_type_predictions`: An array of usage type objects, each containing:
    - `usage_type`: The type of usage (e.g., "Infrastructure", "Cloud Stream Ingest")
    - `folds`: An array of fold objects containing predictions

For each customer and usage type:
- Filter folds to find only `fold_5_production` (where `fold_type` is "production")
- Extract from the production fold:
    - `test_forecasts`: Array of 3 future month predictions, each containing:
        - `forecast_month`: The month being predicted (format: "2025-10")
        - `predicted_usage`: The predicted credit usage value
        - `prediction_interval.lower`: Lower bound of prediction
        - `prediction_interval.upper`: Upper bound of prediction
    - `target_customer_analysis`: Contains historical trend information:
        - `training_period`: Date range of historical data (e.g., "2023-09 to 2025-03")
        - `training_months`: Number of months of historical data
        - `slope_final`: The monthly growth/decline rate in credits
        - `recent_history`: Array of the last 3 months of actual usage data (most recent historical data), each containing:
            - `billing_month`: Month in "YYYY-MM" format
            - `total_credit_usage`: Actual credit usage for that month
    - `reasoning_notes`: Array of qualitative insights (available but NOT used in the message)


Skip any usage types or customers where fold_5_production is not found.

**Note**: Each production forecast includes 3 months of predictions instead of 1.

</parsing_input>

<customer_id_to_customer_name>
- Use the following mapping to find the customer name to use in the slack message along with the customer id, where appropriate:
  {{ $('Obfuscate Customer Names').last().json.customer_name_mapping.customer_id_to_name.toJsonString() }}
- Do **NOT** hallucinate customer names and customer ids; use **ONLY** what is in the mapping.
- When using the customer id, use the full id (e.g. `30042cab-faf8-473c-b98a-921da0a1a7cb` instead of `30042cab`)
  </customer_id_to_customer_name>


<slack_message_format>
The message should:
- Tag the user's username, which is `{{ $('Global Vars').first().json.body.message_user_name }}`.
- Address their original request, which was `{{ $('Global Vars').first().json.body.message_text }}`.
- Should not write word-for-word their original request but instead should extract key words from their request to use to summarize what their original request might be related to.
- Convert the forecast_month from a format like `2025-10` to `Oct 2025`
- Group predictions by customer first, then by usage type within each customer
- For each customer, show their customer_id
- For each usage type under that customer:
    - Mention the usage type name
    - **Show the past 3 months of actual usage** from `recent_history` in a compact format (e.g., "Past: Jan: 22,145 | Feb: 23,679 | Mar: 24,512")
    - Include a brief trend context using `slope_final`:
        - If slope_final > 0: mention "growing" or "increasing" trend with the rate
        - If slope_final < 0: mention "declining" or "decreasing" trend with the rate
        - If slope_final ≈ 0: mention "stable" or "flat" trend
    - **Show ALL 3 monthly predictions** in a compact format (e.g., "Forecast: Oct: 26,284 | Nov: 27,896 | Dec: 29,508")
    - **Do NOT include any notes from `reasoning_notes`** - keep the message clean and focused on the numbers

- Use clear visual separation between customers (e.g., blank lines or separators)
- Do **NOT** include the coverage_probability
- Should not include any notes about helping further
- **CRITICAL**: If the Input is empty or there are no customers in the input array then craft a simple message summarizing their request but also saying that there are no predictions available with a tone of slight regret. In this scenario, and *ONLY* in this scenario, this message should override the previous Slack message formatting. Keep it to a single sentence.
- Format numbers with appropriate thousand separators for readability (e.g., 25,164.81 instead of 25164.81)
- Keep the message concise but informative - users should understand both the predictions AND the historical trend behind them
  </slack_message_format>

<example_message>
For an input with 2 customers, each with 2 usage types, the message might look like:

"Hey @username, here are your credit usage predictions:

*Customer: Customer Name A (customer A id)*
• *Infrastructure* - Growing +1,313 credits/month (based on 24 months of data)
Past: Jul 2025: 22,145 | Aug 2025: 23,458 | Sep 2025: 24,771
Forecast: Oct 2025: 26,084 | Nov 2025: 27,397 | Dec 2025: 28,710

• *Cloud Stream Ingest* - Stable trend (~50 credits/month)
Past: Jul 2025: 15,232 | Aug 2025: 15,282 | Sep 2025: 15,332
Forecast: Oct 2025: 15,382 | Nov 2025: 15,432 | Dec 2025: 15,482

*Customer: Customer Name B (customer B id)*
• *Infrastructure* - Declining -850 credits/month (based on 19 months of data)
Past: Jul 2025: 21,050 | Aug 2025: 20,200 | Sep 2025: 19,350
Forecast: Oct 2025: 18,500 | Nov 2025: 17,650 | Dec 2025: 16,800

• *Data Rehydration* - Growing +320 credits/month
Past: Jul 2025: 4,240 | Aug 2025: 4,560 | Sep 2025: 4,880
Forecast: Oct 2025: 5,200 | Nov 2025: 5,520 | Dec 2025: 5,840"
</example_message>

</guidelines>

<output_format>
The resulting output JSON should be like this:
```json
{
  "message": "formatted slack message"
}
```
</output_format>
