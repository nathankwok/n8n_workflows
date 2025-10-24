/**
 * Generate complete temporal cross-validation fold datasets for time-series forecasting.
 * Input: group_by_customers.json (training_dataset + target_dataset) with usage_type grouping
 * Output: 5 complete folds with actual customer records, organized by target customer and usage_type
 *
 * - All similar customers (training_dataset) are used as training data in every fold
 * - Target customer(s) data is split temporally for walk-forward validation
 * - Each fold trains on progressively more target customer history
 * - Folds are generated PER USAGE TYPE for EACH target customer
 * - Folds 1-4: Validation folds with known validation data
 * - Fold 5: Production fold forecasting unknown future
 */

/**
 * Generate truly random 10-digit integer for fold seed
 */
function generateRandomSeed() {
    return Math.floor(Math.random() * 9000000000) + 1000000000;
}

/**
 * Define temporal fold configurations
 * These specify how to split the target customer's 24 months of data
 */
function generateFoldConfigs() {
    return [
        {
            fold_id: 'fold_1',
            random_data_seed: generateRandomSeed(),
            description: 'Train on target months 0-18, validate on month 19, predict months 20-22',
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index: 18,
                validation_month_index: 19,
                test_month_indices: [20, 21, 22]  // Predict next 3 months
            }
        },
        {
            fold_id: 'fold_2',
            random_data_seed: generateRandomSeed(),
            description: 'Train on target months 0-19, validate on month 20, predict months 21-23',
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index: 19,
                validation_month_index: 20,
                test_month_indices: [21, 22, 23]  // Predict next 3 months
            }
        },
        {
            fold_id: 'fold_3',
            random_data_seed: generateRandomSeed(),
            description: 'Train on target months 0-20, validate on month 21, predict months 22-24',
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index: 20,
                validation_month_index: 21,
                test_month_indices: [22, 23, null]  // Month 24 may not exist in historical data
            }
        },
        {
            fold_id: 'fold_4',
            random_data_seed: generateRandomSeed(),
            description: 'Train on target months 0-21, validate on month 22, predict months 23-25',
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index: 21,
                validation_month_index: 22,
                test_month_indices: [23, null, null]  // Months 24-25 may not exist in historical data
            }
        },
        {
            fold_id: 'fold_5_production',
            random_data_seed: generateRandomSeed(),
            description: 'Train on all available target history (0-23), forecast next 3 unknown months (24-26)',
            fold_type: 'production',
            target_customer_config: {
                training_end_month_index: null,
                validation_month_index: null,
                test_month_indices: null  // Will be calculated as next 3 months
            }
        }
    ];
}

function parseBillingMonth(raw) {
    if (!raw || typeof raw !== 'string') {
        return null;
    }

    const trimmed = raw.trim();
    const isoMatch = trimmed.match(/^(\d{4})-(\d{1,2})$/);

    if (isoMatch) {
        const year = Number(isoMatch[1]);
        const month = Number(isoMatch[2]) - 1;
        if (Number.isFinite(year) && Number.isFinite(month)) {
            return new Date(Date.UTC(year, month, 1));
        }
    }

    let parsed = Date.parse(trimmed);
    if (Number.isNaN(parsed)) {
        parsed = Date.parse(`${trimmed} 1`);
    }
    if (Number.isNaN(parsed)) {
        return null;
    }

    const date = new Date(parsed);
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));
}

function formatBillingMonth(date, fallback) {
    if (!date || Number.isNaN(date.getTime())) {
        return fallback || null;
    }

    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');

    return `${year}-${month}`;
}

function addMonths(date, monthsToAdd) {
    if (!date || Number.isNaN(date.getTime())) {
        return null;
    }

    const year = date.getUTCFullYear();
    const month = date.getUTCMonth();

    return new Date(Date.UTC(year, month + monthsToAdd, 1));
}

function toNumber(value) {
    const num = Number(value);
    return Number.isFinite(num) ? num : null;
}

function cloneSeries(series) {
    if (series === null || series === undefined) {
        return series;
    }

    return JSON.parse(JSON.stringify(series));
}

function sortRecords(records) {
    return (Array.isArray(records) ? records : [])
        .map((record, index) => {
            const parsedDate = parseBillingMonth(record.billing_month);
            return { record, parsedDate, index };
        })
        .sort((a, b) => {
            const aHasDate = a.parsedDate instanceof Date;
            const bHasDate = b.parsedDate instanceof Date;

            if (aHasDate && bHasDate) {
                return a.parsedDate - b.parsedDate;
            }
            if (aHasDate) {
                return -1;
            }
            if (bHasDate) {
                return 1;
            }
            return a.index - b.index;
        });
}

/**
 * Build complete series for similar customers (all their history) for a specific usage type
 */
function buildSimilarCustomerSeries(records, usageType) {
    const sorted = sortRecords(records);
    if (!sorted.length) {
        return null;
    }

    const formatted = sorted.map(({ record, parsedDate }, monthIndex) => ({
        billing_month: formatBillingMonth(parsedDate, record.billing_month),
        month_index: monthIndex,
        total_credit_usage: toNumber(record.total_credit_usage)
    }));

    const { customer_id, customer_name } = sorted[0].record || {};

    return {
        customer_id,
        customer_name,
        usage_type: usageType,
        records: formatted
    };
}

/**
 * Split target customer records into training, validation, and test sets based on temporal fold config
 */
function splitTargetCustomerRecords(allRecords, foldConfig, usageType) {
    const sorted = sortRecords(allRecords);
    if (!sorted.length) {
        return null;
    }

    const formatted = sorted.map(({ record, parsedDate }, monthIndex) => ({
        billing_month: formatBillingMonth(parsedDate, record.billing_month),
        month_index: monthIndex,
        total_credit_usage: toNumber(record.total_credit_usage)
    }));

    const { customer_id, customer_name } = sorted[0].record || {};
    const { training_end_month_index, validation_month_index, test_month_indices } = foldConfig;

    // For production fold (no validation), use all data for training
    if (training_end_month_index === null) {
        const lastRecord = formatted[formatted.length - 1];
        const lastDate = parseBillingMonth(lastRecord.billing_month);

        // Generate next 3 months
        const testMonths = [
            formatBillingMonth(addMonths(lastDate, 1), null),
            formatBillingMonth(addMonths(lastDate, 2), null),
            formatBillingMonth(addMonths(lastDate, 3), null)
        ];

        return {
            customer_id,
            customer_name,
            usage_type: usageType,
            training_records: formatted,
            validation_record: null,
            test_months: testMonths
        };
    }

    // Split data temporally for validation folds
    const trainingRecords = formatted.slice(0, training_end_month_index + 1);
    const validationRecord = formatted[validation_month_index] || null;

    // Get test records for the next 3 months (may not all exist in historical data)
    const testRecords = test_month_indices.map(index =>
        index !== null ? formatted[index] || null : null
    );

    // Calculate test months - use actual data if available, otherwise calculate from validation month
    const testMonths = testRecords.map((record, i) => {
        if (record) {
            return record.billing_month;
        } else if (validationRecord) {
            const valDate = parseBillingMonth(validationRecord.billing_month);
            return formatBillingMonth(addMonths(valDate, i + 1), null);
        }
        return null;
    });

    return {
        customer_id,
        customer_name,
        usage_type: usageType,
        training_records: trainingRecords,
        validation_record: validationRecord,
        test_months: testMonths,
        test_records: testRecords  // Include actual test records if they exist
    };
}

/**
 * Process a single target customer and generate folds for all their usage types
 */
function processTargetCustomer(targetCustomerId, targetCustomerUsageTypes, trainingLookup, foldConfigs) {
    // Get all unique usage types from this target customer
    const targetUsageTypes = Object.keys(targetCustomerUsageTypes);

    if (targetUsageTypes.length === 0) {
        console.log(`Warning: Target customer ${targetCustomerId} has no usage types`);
        return null;
    }

    console.log(`Processing target customer ${targetCustomerId} with ${targetUsageTypes.length} usage type(s): ${targetUsageTypes.join(', ')}`);

    // Process each usage type separately
    const usageTypeFolds = targetUsageTypes.map((usageType) => {
        console.log(`  Processing usage type: ${usageType}`);

        // Build similar customer series for this usage type
        // Only include similar customers that have data for this specific usage type
        const similarCustomerSeries = Object.entries(trainingLookup)
            .map(([customerId, usageTypeRecords]) => {
                // usageTypeRecords is { usage_type: [records] }
                const recordsForUsageType = usageTypeRecords[usageType];
                if (!recordsForUsageType || !recordsForUsageType.length) {
                    return null; // This customer doesn't have this usage type
                }
                return buildSimilarCustomerSeries(recordsForUsageType, usageType);
            })
            .filter(Boolean);

        console.log(`    Found ${similarCustomerSeries.length} similar customers with usage type: ${usageType}`);

        // Get target customer records for this usage type
        const targetRecordsForUsageType = targetCustomerUsageTypes[usageType];

        if (!targetRecordsForUsageType || !targetRecordsForUsageType.length) {
            console.log(`    Warning: Target customer has no records for usage type: ${usageType}`);
            return null;
        }

        // Process each temporal fold for this usage type
        const folds = foldConfigs.map((foldConfig) => {
            const targetSplit = splitTargetCustomerRecords(
                targetRecordsForUsageType,
                foldConfig.target_customer_config,
                usageType
            );

            return {
                fold_id: foldConfig.fold_id,
                random_data_seed: foldConfig.random_data_seed,
                description: foldConfig.description,
                fold_type: foldConfig.fold_type,
                similar_customers: cloneSeries(similarCustomerSeries),
                target_customer: targetSplit
            };
        });

        return {
            usage_type: usageType,
            folds: folds
        };
    }).filter(Boolean);

    return {
        target_customer_id: targetCustomerId,
        usage_type_folds: usageTypeFolds
    };
}

// ===========================
// Main Processing
// ===========================

const groupNode = $('Group by Customers').first();
const groupJson = groupNode?.json || {};

const trainingLookup = groupJson.training_dataset || {};
const targetLookup = groupJson.target_dataset || {};

// Get all target customer IDs
const targetCustomerIds = Object.keys(targetLookup);
if (targetCustomerIds.length === 0) {
    throw new Error('No target customers found in target_dataset');
}

console.log(`Processing ${targetCustomerIds.length} target customer(s)`);

// Generate fold configurations (same for all customers and usage types)
const foldConfigs = generateFoldConfigs();

// Process each target customer
const targetCustomerResults = targetCustomerIds.map((targetCustomerId) => {
    const targetCustomerUsageTypes = targetLookup[targetCustomerId]; // { usage_type: [records] }
    return processTargetCustomer(targetCustomerId, targetCustomerUsageTypes, trainingLookup, foldConfigs);
}).filter(Boolean);

// Return in the format expected by downstream agents
// Structure: [
//   {
//     target_customer_id: "id1",
//     usage_type_folds: [
//       { usage_type: "type1", folds: [...] },
//       { usage_type: "type2", folds: [...] }
//     ]
//   },
//   {
//     target_customer_id: "id2",
//     usage_type_folds: [...]
//   }
// ]
return targetCustomerResults;
