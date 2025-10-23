/**
 * Generate complete temporal cross-validation fold datasets for time-series forecasting.
 * Input: group_by_customers.json (training_dataset + target_dataset)
 * Output: 5 complete folds with actual customer records
 *
 * - All similar customers are used as training data in every fold
 * - Target customer (BlackRock) data is split temporally for walk-forward validation
 * - Each fold trains on progressively more target customer history
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
            description: 'Train on target months 0-18, validate on month 19',
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index: 18,
                validation_month_index: 19,
                test_month_index: 20
            }
        },
        {
            fold_id: 'fold_2',
            random_data_seed: generateRandomSeed(),
            description: 'Train on target months 0-19, validate on month 20',
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index: 19,
                validation_month_index: 20,
                test_month_index: 21
            }
        },
        {
            fold_id: 'fold_3',
            random_data_seed: generateRandomSeed(),
            description: 'Train on target months 0-20, validate on month 21',
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index: 20,
                validation_month_index: 21,
                test_month_index: 22
            }
        },
        {
            fold_id: 'fold_4',
            random_data_seed: generateRandomSeed(),
            description: 'Train on target months 0-21, validate on month 22',
            fold_type: 'validation',
            target_customer_config: {
                training_end_month_index: 21,
                validation_month_index: 22,
                test_month_index: 23
            }
        },
        {
            fold_id: 'fold_5_production',
            random_data_seed: generateRandomSeed(),
            description: 'Train on all available target history (0-23), forecast next unknown month (24)',
            fold_type: 'production',
            target_customer_config: {
                training_end_month_index: null,
                validation_month_index: null,
                test_month_index: null
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
 * Build complete series for similar customers (all their history)
 */
function buildSimilarCustomerSeries(records) {
    const sorted = sortRecords(records);
    if (!sorted.length) {
        return null;
    }

    const formatted = sorted.map(({ record, parsedDate }, monthIndex) => ({
        billing_month: formatBillingMonth(parsedDate, record.billing_month),
        month_index: monthIndex,
        total_credit_usage: toNumber(record.total_credit_usage)
    }));

    const { customer_id, customer_name, usage_type } = sorted[0].record || {};

    return {
        customer_id,
        customer_name,
        usage_type,
        records: formatted
    };
}

/**
 * Split target customer records into training, validation, and test sets based on temporal fold config
 */
function splitTargetCustomerRecords(allRecords, foldConfig) {
    const sorted = sortRecords(allRecords);
    if (!sorted.length) {
        return null;
    }

    const formatted = sorted.map(({ record, parsedDate }, monthIndex) => ({
        billing_month: formatBillingMonth(parsedDate, record.billing_month),
        month_index: monthIndex,
        total_credit_usage: toNumber(record.total_credit_usage)
    }));

    const { customer_id, customer_name, usage_type } = sorted[0].record || {};
    const { training_end_month_index, validation_month_index, test_month_index } = foldConfig;

    // For production fold (no validation), use all data for training
    if (training_end_month_index === null) {
        const lastRecord = formatted[formatted.length - 1];
        const lastDate = parseBillingMonth(lastRecord.billing_month);
        const nextMonth = formatBillingMonth(addMonths(lastDate, 1), null);

        return {
            customer_id,
            customer_name,
            usage_type,
            training_records: formatted,
            validation_record: null,
            test_month: nextMonth
        };
    }

    // Split data temporally for validation folds
    const trainingRecords = formatted.slice(0, training_end_month_index + 1);
    const validationRecord = formatted[validation_month_index] || null;
    const testRecord = formatted[test_month_index] || null;

    // Calculate test month
    let testMonth = null;
    if (testRecord) {
        testMonth = testRecord.billing_month;
    } else if (validationRecord) {
        const valDate = parseBillingMonth(validationRecord.billing_month);
        testMonth = formatBillingMonth(addMonths(valDate, 1), null);
    }

    return {
        customer_id,
        customer_name,
        usage_type,
        training_records: trainingRecords,
        validation_record: validationRecord,
        test_month: testMonth
    };
}

// ===========================
// Main Processing
// ===========================

const groupNode = $('Group by Customers').first();
const groupJson = groupNode?.json || {};

const trainingLookup = groupJson.training_dataset || {};
const targetLookup = groupJson.target_dataset || {};

// Get target customer data (should be BlackRock)
const targetCustomerIds = Object.keys(targetLookup);
if (targetCustomerIds.length !== 1) {
    throw new Error(`Expected exactly 1 target customer, found ${targetCustomerIds.length}`);
}

const targetCustomerId = targetCustomerIds[0];
const targetCustomerRecords = targetLookup[targetCustomerId];

// Build similar customer series (use all their data in every fold)
const similarCustomerSeries = Object.entries(trainingLookup)
    .map(([customerId, records]) => buildSimilarCustomerSeries(records))
    .filter(Boolean);

// Generate fold configurations
const foldConfigs = generateFoldConfigs();

// Process each temporal fold
const folds = foldConfigs.map((foldConfig) => {
    const targetSplit = splitTargetCustomerRecords(
        targetCustomerRecords,
        foldConfig.target_customer_config
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

// Return in the format expected by downstream agents
return [{ folds }];
