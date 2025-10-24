<task>
1. Go through the input array of target customer predictions.
2. For each target customer, extract only the production forecasts (fold_5_production) for each usage type.
3. Get the values for `predicted_usage`, `forecast_month`, `lower`, and `upper` from each production forecast.
4. Craft a well formatted slack_message in the tone of a helpful data analyst, grouping predictions by customer and then by usage type, keeping in mind everything in the slack_message_format.
5. Finally, output in a structured JSON output format with the following keys:
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
- Extract the `forecast` object which contains:
    - `forecast_month`: The month being predicted (format: "2025-10")
    - `predicted_usage`: The predicted credit usage value
    - `prediction_interval.lower`: Lower bound of prediction
    - `prediction_interval.upper`: Upper bound of prediction

Skip any usage types or customers where fold_5_production is not found.
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
- For each customer, show their customer_id (or a shortened version)
- For each usage type under that customer:
    - Mention the usage type name
    - Show the predicted credit usage for the forecast month using `predicted_usage`
    - Give the upper and lower bounds of the prediction using the `upper` and `lower` extracted values
- Use clear visual separation between customers (e.g., blank lines or separators)
- Do **NOT** include the coverage_probability
- Should not include any notes about helping further
- **CRITICAL**: If the Input is empty or there are no customers in the input array then craft a simple message summarizing their request but also saying that there are no predictions available with a tone of slight regret. In this scenario, and *ONLY* in this scenario, this message should override the previous Slack message formatting. Keep it to a single sentence.
- Format numbers with appropriate thousand separators for readability (e.g., 25,164.81 instead of 25164.81)
  </slack_message_format>

<example_message>
For an input with 2 customers, each with 2 usage types, the message might look like:

"Hey @username, here are your credit usage predictions:

**Customer: Customer Name A (customer A id)**
• Infrastructure (Oct 2025): 26,284 credits (range: 12,236 - 40,333)
• Cloud Stream Ingest (Oct 2025): 15,432 credits (range: 8,500 - 22,000)

**Customer: Customer Name B (customer B id)**
• Infrastructure (Oct 2025): 18,500 credits (range: 10,000 - 27,000)
• Data Rehydration (Oct 2025): 5,200 credits (range: 2,100 - 8,300)"
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
