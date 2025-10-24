
const crypto = require('crypto');

const input_data = $input.first().json.output;
const training_dataset = input_data.training_dataset;
const target_dataset = input_data.target_dataset;

// Create a mapping object to store original -> obfuscated names
const customerNameMapping = {};
// Create a mapping object to store customer_id -> original customer name
const customerIdToNameMapping = {};

// Function to create a simple hash
// Reason: Using MD5 for deterministic hash generation - same input always produces same output
function simpleHash(str) {
  const hash = crypto.createHash('md5').update(str).digest('hex');
  return hash.substring(hash.length - 8);
}

// Function to obfuscate a customer name
function obfuscateCustomerName(originalName) {
  // If we've already obfuscated this name, return the cached value
  if (customerNameMapping[originalName]) {
    return customerNameMapping[originalName];
  }

  // Create a hash-based obfuscated name
  const obfuscatedName = simpleHash(originalName);
  customerNameMapping[originalName] = obfuscatedName;

  return obfuscatedName;
}

// Process the dataset
function obfuscateDataset(dataset) {
  return dataset.filter(record => record.customer_id && record.customer_name && record.customer_name.length > 0 && record.customer_id.length > 0).map(record => {
    // Store customer_id -> original customer_name mapping
    // Reason: Track customer_id to name relationship before obfuscation for reference

    if (record.customer_id && record.customer_name && record.customer_name.length > 0 && record.customer_id.length > 0) {
      customerIdToNameMapping[record.customer_id] = record.customer_name;

    }

    return {
      ...record,
      customer_name: obfuscateCustomerName(record.customer_name)
    };
  });
}

// Obfuscate both training and target datasets
const obfuscated_customer_data = {
  training_dataset: obfuscateDataset(training_dataset),
  target_dataset: obfuscateDataset(target_dataset)
};

// Create mapping output with forward and reverse mappings
const customer_name_mapping = {
  mapping: customerNameMapping,
  reverse_mapping: Object.entries(customerNameMapping).reduce((acc, [original, obfuscated]) => {
    acc[obfuscated] = original;
    return acc;
  }, {}),
  customer_id_to_name: customerIdToNameMapping
};

// Return the result as an array of objects
return [
  { "obfuscated_customer_data": obfuscated_customer_data },
  { "customer_name_mapping": customer_name_mapping }
];
