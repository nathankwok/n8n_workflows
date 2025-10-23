/**
 * Transform dataset splits into temporal cross-validation folds for time-series forecasting.
 * - All similar customers are used as training data in every fold
 * - Target customer (BlackRock) data is split temporally for walk-forward validation
 * - Each fold trains on progressively more target customer history
 */

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
            test_month: nextMonth,
            fold_type: 'production'
        };
    }

    // Split data temporally
    const trainingRecords = formatted.slice(0, training_end_month_index + 1);
    const validationRecord = formatted[validation_month_index] || null;
    const testRecord = formatted[test_month_index] || null;

    // Calculate next month for test forecast
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
        test_month: testMonth,
        fold_type: 'validation'
    };
}

// Main processing
const groupNode = $('Group by Customers').first();
const splitsNode = $('splits').first();

const groupJson = groupNode?.json || {};
const splitsInput = splitsNode?.json?.output || [];

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

// Process each temporal fold
const enrichedFolds = (Array.isArray(splitsInput) ? splitsInput : []).map((foldConfig) => {
    const targetSplit = splitTargetCustomerRecords(targetCustomerRecords, foldConfig.target_customer_config);

    return {
        fold_id: foldConfig.fold_id,
        random_data_seed: foldConfig.random_data_seed,
        description: foldConfig.description,
        similar_customers: cloneSeries(similarCustomerSeries),
        target_customer: targetSplit
    };
});

return [{ output: enrichedFolds }];
