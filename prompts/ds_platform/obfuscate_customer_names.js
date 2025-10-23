
const crypto = require('crypto');

// Read the input JSON file
const inputPath = path.join(__dirname, 'obfuscate_customer_name.json');
const data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

// Create a mapping object to store original -> obfuscated names
const customerNameMapping = {};

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
  return dataset.map(record => ({
    ...record,
    customer_name: obfuscateCustomerName(record.customer_name)
  }));
}

// Obfuscate both training and target datasets
const obfuscated_customer_data = {
  output: {
    training_dataset: obfuscateDataset(data.output.training_dataset),
    target_dataset: obfuscateDataset(data.output.target_dataset)
  }
};

// Create mapping output with forward and reverse mappings
const customer_name_mapping = {
  mapping: customerNameMapping,
  reverse_mapping: Object.entries(customerNameMapping).reduce((acc, [original, obfuscated]) => {
    acc[obfuscated] = original;
    return acc;
  }, {})
};

// Return the result as an array of objects
return [
  { "obfuscated_customer_data": obfuscated_customer_data },
  { "customer_name_mapping": customer_name_mapping }
];
