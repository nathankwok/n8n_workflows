// Helper to turn "Sep 2025" or "September 2025" into a sortable number
function parseMonthKey(s) {
    const months = {
        jan: 0, january: 0,
        feb: 1, february: 1,
        mar: 2, march: 2,
        apr: 3, april: 3,
        may: 4,
        jun: 5, june: 5,
        jul: 6, july: 6,
        aug: 7, august: 7,
        sep: 8, sept: 8, september: 8,
        oct: 9, october: 9,
        nov: 10, november: 10,
        dec: 11, december: 11,
    };
    const [mRaw, yRaw] = s.trim().split(/\s+/);
    const m = months[mRaw.toLowerCase()];
    const y = Number(yRaw);
    // Use UTC to avoid TZ surprises
    return Date.UTC(y, m, 1);
}

// Flatten rows
// const rows = $input.first().json.output.flatMap(d => Array.isArray(d) ? d.output : []);

const input_data = $input.first().json.obfuscated_customer_data;
console.log(input_data);

// Group by customer_id and usage_type
const training_dataset = input_data.training_dataset.reduce((acc, row) => {
    const customerId = row["customer_id"];
    const usageType = row["usage_type"] || "Unknown";

    if (!acc[customerId]) acc[customerId] = {};
    if (!acc[customerId][usageType]) acc[customerId][usageType] = [];

    acc[customerId][usageType].push(row);
    return acc;
}, {});

// Sort each customer's usage_type arrays by month ascending
Object.values(training_dataset).forEach(usageTypeObj => {
    Object.values(usageTypeObj).forEach(arr => {
        // Filter out items with invalid or missing billing_month
        const filteredItems = arr.filter(
            item => typeof item.billing_month === 'string' && item.billing_month.trim() !== ''
        );
        filteredItems.sort(
            (a, b) => parseMonthKey(a.billing_month) - parseMonthKey(b.billing_month)
        );
        // Replace original array contents with filtered and sorted items
        arr.length = 0;
        arr.push(...filteredItems);
    });
});


console.log(training_dataset);
// grouped is: { "<customer-id>": { "<usage-type>": [rows sorted by month asc], ... }, ... }




const target_dataset = input_data.target_dataset.reduce((acc, row) => {
    const customerId = row["customer_id"];
    const usageType = row["usage_type"] || "Unknown";

    if (!acc[customerId]) acc[customerId] = {};
    if (!acc[customerId][usageType]) acc[customerId][usageType] = [];

    acc[customerId][usageType].push(row);
    return acc;
}, {});

Object.values(target_dataset).forEach(usageTypeObj => {
    Object.values(usageTypeObj).forEach(arr => {
        // Filter out items with invalid or missing billing_month
        const filteredItems = arr.filter(
            item => typeof item.billing_month === 'string' && item.billing_month.trim() !== ''
        );
        filteredItems.sort(
            (a, b) => parseMonthKey(a.billing_month) - parseMonthKey(b.billing_month)
        );
        // Replace original array contents with filtered and sorted items
        arr.length = 0;
        arr.push(...filteredItems);
    });
});

return {
    "training_dataset": training_dataset,
    "target_dataset": target_dataset
}