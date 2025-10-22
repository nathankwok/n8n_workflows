/**
 * Transform dataset splits into structured training and target series objects.
 * - Training series expose historical records plus the observed target record.
 * - Target series expose only historical records and the next billing month to forecast.
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

function buildTrainingSeries(records) {
    const sorted = sortRecords(records);
    if (!sorted.length) {
        return null;
    }

    const formatted = sorted.map(({ record, parsedDate }, monthIndex) => ({
        billing_month: formatBillingMonth(parsedDate, record.billing_month),
        month_index: monthIndex,
        total_credit_usage: toNumber(record.total_credit_usage)
    }));

    const targetRecord = formatted.length ? formatted[formatted.length - 1] : null;
    const historicalRecords = formatted.slice(0, Math.max(formatted.length - 1, 0));
    const { customer_id, customer_name, usage_type } = sorted[0].record || {};

    return {
        customer_id,
        customer_name,
        usage_type,
        historical_records: historicalRecords,
        target_record: targetRecord
    };
}

function buildTargetSeries(records) {
    const sorted = sortRecords(records);
    if (!sorted.length) {
        return null;
    }

    const formatted = sorted.map(({ record, parsedDate }, monthIndex) => ({
        billing_month: formatBillingMonth(parsedDate, record.billing_month),
        month_index: monthIndex,
        total_credit_usage: toNumber(record.total_credit_usage)
    }));

    const lastEntry = sorted.length ? sorted[sorted.length - 1] : null;
    const lastParsedDate = lastEntry?.parsedDate || null;
    const nextBillingMonth = formatBillingMonth(addMonths(lastParsedDate, 1), null);
    const { customer_id, customer_name, usage_type } = sorted[0].record || {};

    return {
        customer_id,
        customer_name,
        usage_type,
        historical_records: formatted,
        next_billing_month: nextBillingMonth
    };
}

const groupNode = $('Group by Customers').first();
const splitsNode = $('splits').first();

const groupJson = groupNode?.json || {};
const splitsInput = splitsNode?.json?.output || [];

const trainingLookup = groupJson.training_dataset || {};
const targetLookup = groupJson.target_dataset || {};

const targetSeriesList = Object.values(targetLookup)
    .map(buildTargetSeries)
    .filter(Boolean);

const fallbackTargetSeries = (() => {
    if (!targetSeriesList.length && splitsInput.length) {
        const firstSplit = splitsInput[0];
        const validationIds = Array.isArray(firstSplit?.validation_dataset)
            ? firstSplit.validation_dataset
            : [];

        return validationIds
            .map((id) => buildTargetSeries(trainingLookup[id]))
            .filter(Boolean);
    }
    return [];
})();

const resolvedTargetSeries = targetSeriesList.length
    ? targetSeriesList
    : fallbackTargetSeries;

const targetSeriesOutput = resolvedTargetSeries.length === 1
    ? resolvedTargetSeries[0]
    : resolvedTargetSeries;

const enrichedSplits = (Array.isArray(splitsInput) ? splitsInput : []).map((split) => {
    const trainingIds = Array.isArray(split?.training_dataset) ? split.training_dataset : [];
    const trainingSeries = trainingIds
        .map((id) => buildTrainingSeries(trainingLookup[id]))
        .filter(Boolean);

    return {
        random_data_seed: split?.random_data_seed,
        training_series: trainingSeries,
        target_series: cloneSeries(targetSeriesOutput)
    };
});

return [{ output: enrichedSplits }];
