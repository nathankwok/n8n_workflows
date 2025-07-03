#!/bin/bash

# Stock Options Trading Workflow Validation Script
# Based on PRP validation requirements

echo "🔍 Validating Stock Options Trading Workflow..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0

# Test function
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAIL++))
    fi
}

echo "📋 Running validation tests..."

# 1. JSON Syntax Validation
echo "🔧 Testing JSON syntax..."
if python3 -m json.tool workflows/stock-options-trading-workflow.json > /dev/null 2>&1; then
    test_result 0 "JSON syntax is valid"
else
    test_result 1 "JSON syntax validation failed"
fi

# 2. Required Node Types Check
echo "🔧 Testing required node types..."
required_nodes=(
    "n8n-nodes-base.scheduleTrigger"
    "n8n-nodes-base.set"
    "@n8n/n8n-nodes-langchain.agent"
    "n8n-nodes-base.splitInBatches"
    "n8n-nodes-base.merge"
    "n8n-nodes-base.if"
)

for node_type in "${required_nodes[@]}"; do
    if grep -q "\"type\": \"$node_type\"" workflows/stock-options-trading-workflow.json; then
        test_result 0 "Node type $node_type found"
    else
        test_result 1 "Node type $node_type missing"
    fi
done

# 3. Agent Configuration Check
echo "🔧 Testing agent configurations..."
agent_count=$(grep -c "@n8n/n8n-nodes-langchain.agent" workflows/stock-options-trading-workflow.json)
if [ $agent_count -ge 5 ]; then
    test_result 0 "Sufficient agents configured ($agent_count found)"
else
    test_result 1 "Insufficient agents configured ($agent_count found, need ≥5)"
fi

# 4. Schedule Trigger Configuration
echo "🔧 Testing schedule trigger..."
if grep -q "0 9,15 \* \* 1-5" workflows/stock-options-trading-workflow.json; then
    test_result 0 "Market hours schedule configured"
else
    test_result 1 "Market hours schedule not found"
fi

# 5. MCP Server Configuration Files
echo "🔧 Testing MCP server configurations..."
mcp_configs=(
    "mcp-servers/financial-data-server.json"
    "mcp-servers/broker-api-server.json"
    "mcp-servers/tasty-agent-server.json"
    "mcp-servers/interactive-brokers-server.json"
    "mcp-servers/risk-management-server.json"
)

for config in "${mcp_configs[@]}"; do
    if [ -f "$config" ]; then
        if python3 -m json.tool "$config" > /dev/null 2>&1; then
            test_result 0 "MCP config $config is valid"
        else
            test_result 1 "MCP config $config has invalid JSON"
        fi
    else
        test_result 1 "MCP config $config not found"
    fi
done

# 6. Agent Prompt Files
echo "🔧 Testing agent prompt files..."
prompt_files=(
    "prompts/orchestrator-agent.txt"
    "prompts/analysis-subagent.txt"
    "prompts/validator-agent.txt"
)

for prompt in "${prompt_files[@]}"; do
    if [ -f "$prompt" ] && [ -s "$prompt" ]; then
        test_result 0 "Prompt file $prompt exists and has content"
    else
        test_result 1 "Prompt file $prompt missing or empty"
    fi
done

# 7. Workflow Structure Validation
echo "🔧 Testing workflow structure..."

# Check for proper connections
if grep -q "\"connections\":" workflows/stock-options-trading-workflow.json; then
    test_result 0 "Workflow connections defined"
else
    test_result 1 "Workflow connections missing"
fi

# Check for global variables
if grep -q "max_symbols_per_batch" workflows/stock-options-trading-workflow.json; then
    test_result 0 "Global variables configured"
else
    test_result 1 "Global variables missing"
fi

# 8. Risk Management Parameters
echo "🔧 Testing risk management parameters..."
risk_params=(
    "risk_tolerance"
    "max_position_size"
    "target_delta"
)

for param in "${risk_params[@]}"; do
    if grep -q "\"$param\"" workflows/stock-options-trading-workflow.json; then
        test_result 0 "Risk parameter $param found"
    else
        test_result 1 "Risk parameter $param missing"
    fi
done

# 9. Error Handling Configuration
echo "🔧 Testing error handling..."
if grep -q "\"continueOnFail\": true" workflows/stock-options-trading-workflow.json; then
    test_result 0 "Error handling configured"
else
    test_result 1 "Error handling not configured"
fi

if grep -q "\"retryOnFail\": true" workflows/stock-options-trading-workflow.json; then
    test_result 0 "Retry logic configured"
else
    test_result 1 "Retry logic not configured"
fi

# 10. Logging and Monitoring
echo "🔧 Testing logging configuration..."
if grep -q "execution_timestamp" workflows/stock-options-trading-workflow.json; then
    test_result 0 "Execution logging configured"
else
    test_result 1 "Execution logging missing"
fi

# Summary
echo ""
echo "📊 Validation Summary:"
echo -e "Tests Passed: ${GREEN}$PASS${NC}"
echo -e "Tests Failed: ${RED}$FAIL${NC}"
echo "Total Tests: $((PASS + FAIL))"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Workflow ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAIL tests failed. Please fix issues before deployment.${NC}"
    exit 1
fi