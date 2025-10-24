/**
 * Generate complete temporal cross-validation fold datasets for time-series forecasting.
 * Input: group_by_customers.json (training_dataset + target_dataset) with usage_type grouping
 * Output: Configurable number of folds with actual customer records, organized by target customer and usage_type
 *
 * - All similar customers (training_dataset) are used as training data in every fold
 * - Target customer(s) data is split temporally for walk-forward validation
 * - Each fold trains on progressively more target customer history
 * - Folds are generated PER USAGE TYPE for EACH target customer
 * - Folds 1 through (n-1): Validation folds with known validation data
 * - Fold n (production): Production fold forecasting unknown future
 *
 * Configuration (all parameters auto-calculated but can be overridden):
 * - total_months: Auto-calculated from target customer data (max months across all usage types)
 * - num_folds: Auto-calculated based on available data using formula: floor((total_months - 6) / 2)
 *   - Can override via Global Vars node: num_folds, total_months
 * - Each validation fold uses progressively more training data
 *
 * Auto-calculation examples:
 * - 9 months → 3 folds (2 validation + 1 production)
 * - 12 months → 5 folds (4 validation + 1 production)
 * - 24 months → 9 folds (8 validation + 1 production, capped at 10 max)
 */

/**
 * Generate truly random 10-digit integer for fold seed
 */
function generateRandomSeed() {
    return Math.floor(Math.random() * 9000000000) + 1000000000;
}

/**
 * Define temporal fold configurations
 * Dynamically generates folds based on num_folds parameter
 *
 * @param {number} num_folds - Total number of folds to generate (minimum 2)
 * @param {number} total_months - Total months of historical data available (default 24)
 * @returns {Array} Array of fold configuration objects
 *
 * Strategy:
 * - Reserve the last fold as the production fold (no validation)
 * - Distribute validation folds evenly across the available historical data
 * - Each validation fold trains on progressively more data
 * - Starting point is calculated to ensure enough data for training
 */
function generateFoldConfigs(num_folds = 5, total_months = 24) {
    // Validate inputs
    if (num_folds < 2) {
        throw new Error('num_folds must be at least 2 (minimum 1 validation fold + 1 production fold)');
    }

    // Adjust minimum required months based on number of folds
    // We need at least: minimum training (3 months) + validation folds + test months (3)
    const min_required_months = 3 + num_folds + 3;

    if (total_months < min_required_months) {
        throw new Error(
            `total_months (${total_months}) must be at least ${min_required_months} to support ${num_folds} folds. ` +
            `Either reduce num_folds or provide more historical data. ` +
            `Suggested: num_folds=${Math.max(2, total_months - 6)}`
        );
    }

    const num_validation_folds = num_folds - 1;  // Last fold is production
    const folds = [];

    // Calculate the starting training end index
    // We want to leave room for validation + 3 test months
    // Use at least 50% of data for first fold's training (more flexible for small datasets)
    const min_training_months = Math.max(3, Math.floor(total_months * 0.5));
    const max_validation_index = total_months - 4;  // Leave room for validation + test months

    // Distribute validation folds evenly
    const available_range = max_validation_index - min_training_months;
    const step = num_validation_folds > 1
        ? Math.floor(available_range / (num_validation_folds - 1))
        : 0;

    // Generate validation folds
    for (let i = 0; i < num_validation_folds; i++) {
        const training_end_month_index = min_training_months + (i * step);
        const validation_month_index = training_end_month_index + 1;

        // Calculate test month indices (next 3 months after validation)
        const test_month_indices = [
            validation_month_index + 1,
            validation_month_index + 2,
            validation_month_index + 3
        ].map(idx => idx < total_months ? idx : null);

        folds.push({
            fold_id: `fold_${i + 1}`,
            random_data_seed: generateRandomSeed(),
            description: `Train on target months 0-${training_end_month_index}, validate on month ${validation_month_index}, predict months ${test_month_indices.filter(x => x !== null).join(', ')}`,
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index,
                validation_month_index,
                test_month_indices
            }
        });
    }

    // Add production fold (uses all available data)
    folds.push({
        fold_id: `fold_${num_folds}_production`,
        random_data_seed: generateRandomSeed(),
        description: `Train on all available target history (0-${total_months - 1}), forecast next 3 unknown months (${total_months}-${total_months + 2})`,
        fold_type: 'production',
        target_customer_config: {
            training_end_month_index: null,
            validation_month_index: null,
            test_month_indices: null  // Will be calculated as next 3 months
        }
    });

    return folds;
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

/**
 * Calculate total months of historical data available across all target customers and usage types
 * Finds the maximum number of months in any target customer's usage type data
 *
 * @param {Object} targetLookup - Target dataset organized by customer_id -> usage_type -> records[]
 * @returns {number} Maximum number of months found in any usage type
 */
function calculateTotalMonths(targetLookup) {
    let maxMonths = 0;

    // Iterate through all target customers
    Object.values(targetLookup).forEach((usageTypeRecords) => {
        // Iterate through all usage types for this customer
        Object.values(usageTypeRecords).forEach((records) => {
            if (Array.isArray(records) && records.length > 0) {
                // Count the number of records (months) for this usage type
                maxMonths = Math.max(maxMonths, records.length);
            }
        });
    });

    console.log(`Calculated total_months from data: ${maxMonths}`);
    return maxMonths;
}

/**
 * Calculate optimal number of folds based on available historical data
 * Strategy: Use 20-30% of data for validation/testing, rest for training
 *
 * @param {number} total_months - Total months of historical data available
 * @returns {number} Optimal number of folds
 *
 * Formula: num_folds = floor((total_months - 6) / 2)
 * - Reserve 3 months minimum for training
 * - Reserve 3 months for final test period
 * - Distribute remaining months between validation folds and training growth
 *
 * Examples:
 * - 9 months → 3 folds (4.5 → 3): Tight but workable
 * - 12 months → 5 folds (6 → 5): Good balance
 * - 24 months → 9 folds (18 → 9): Many validation points
 */
function calculateOptimalFolds(total_months) {
    if (total_months < 8) {
        console.log(`Warning: Only ${total_months} months available. Using minimum 2 folds.`);
        return 2;
    }

    // Calculate based on 20-30% validation strategy
    // Reserve 6 months (3 for min training + 3 for test)
    // Split remaining by 2 (progressive training + validation)
    const calculated = Math.floor((total_months - 6) / 2);

    // Cap at reasonable maximum (more than 10 folds is usually overkill)
    const optimal = Math.min(10, Math.max(2, calculated));

    console.log(`Calculated optimal num_folds: ${optimal} (based on ${total_months} months)`);
    return optimal;
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

// Get configuration parameters
// Both num_folds and total_months are auto-calculated from data but can be overridden via input

// Step 1: Calculate total months from actual data
const calculatedTotalMonths = calculateTotalMonths(targetLookup);
const total_months = parseInt($('Global Vars').first().json.total_months) || calculatedTotalMonths;

// Step 2: Calculate optimal folds based on total_months (this is the minimum)
const calculatedNumFolds = calculateOptimalFolds(total_months);

// Step 3: Use override only if it's higher than calculated minimum AND valid
let num_folds = calculatedNumFolds;
let overrideRejected = false;
let rejectionReason = '';

const requestedNumFolds = $('Global Vars').first().json.num_folds;
if (requestedNumFolds) {
    const requestedFolds = parseInt(requestedNumFolds);

    // Check if requested folds is lower than calculated minimum
    if (requestedFolds < calculatedNumFolds) {
        overrideRejected = true;
        rejectionReason = `requested (${requestedFolds}) is below calculated minimum (${calculatedNumFolds})`;
        num_folds = calculatedNumFolds; // Use calculated minimum
    } else {
        // Check if requested folds is valid for available data
        const min_required_months = 3 + requestedFolds + 3;
        if (total_months < min_required_months) {
            overrideRejected = true;
            rejectionReason = `requested (${requestedFolds}) requires ${min_required_months} months, but only ${total_months} available`;
            num_folds = calculatedNumFolds; // Use calculated minimum
        } else {
            // Valid override - use it
            num_folds = requestedFolds;
        }
    }
}

console.log(`Configuration Summary:`);
console.log(`  total_months: ${total_months} (calculated: ${calculatedTotalMonths}, override: ${$('Global Vars').first().json.total_months || 'auto'})`);
console.log(`  num_folds: ${num_folds} (calculated minimum: ${calculatedNumFolds}, requested: ${requestedNumFolds || 'auto'})`);
if (overrideRejected) {
    console.log(`  ⚠️  Override rejected: ${rejectionReason}`);
    console.log(`  ✅ Using calculated minimum: ${calculatedNumFolds}`);
}

// Get all target customer IDs
const targetCustomerIds = Object.keys(targetLookup);
if (targetCustomerIds.length === 0) {
    throw new Error('No target customers found in target_dataset');
}

console.log(`Processing ${targetCustomerIds.length} target customer(s)`);

// Generate fold configurations (same for all customers and usage types)
const foldConfigs = generateFoldConfigs(num_folds, total_months);

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
return [{"output": targetCustomerResults}];
