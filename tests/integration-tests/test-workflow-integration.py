#!/usr/bin/env python3
"""
Integration Tests for Stock Options Trading Workflow
Tests end-to-end workflow execution with mock data
"""

import json
import requests
import time
from datetime import datetime
from typing import Dict, List, Any

class WorkflowIntegrationTest:
    def __init__(self, n8n_base_url: str = "http://localhost:5678"):
        self.n8n_base_url = n8n_base_url
        self.workflow_id = None
        
    def load_workflow(self) -> Dict[str, Any]:
        """Load workflow JSON from file"""
        with open('../../workflows/stock-options-trading-workflow.json', 'r') as f:
            return json.load(f)
    
    def test_workflow_import(self) -> bool:
        """Test importing workflow into n8n"""
        try:
            workflow = self.load_workflow()
            
            # Import workflow via n8n API
            response = requests.post(
                f"{self.n8n_base_url}/rest/workflows/import",
                json=workflow,
                headers={'Content-Type': 'application/json'}
            )
            
            if response.status_code == 200:
                self.workflow_id = response.json().get('id')
                print(f"✓ Workflow imported successfully (ID: {self.workflow_id})")
                return True
            else:
                print(f"✗ Workflow import failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"✗ Workflow import error: {e}")
            return False
    
    def test_manual_execution(self) -> bool:
        """Test manual workflow execution"""
        if not self.workflow_id:
            print("✗ No workflow ID available for testing")
            return False
            
        try:
            # Trigger manual execution
            response = requests.post(
                f"{self.n8n_base_url}/rest/workflows/{self.workflow_id}/execute",
                json={"startNodes": ["Market Hours Trigger"]},
                headers={'Content-Type': 'application/json'}
            )
            
            if response.status_code == 200:
                execution_id = response.json().get('data', {}).get('executionId')
                print(f"✓ Manual execution started (ID: {execution_id})")
                
                # Monitor execution status
                return self.monitor_execution(execution_id)
            else:
                print(f"✗ Manual execution failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"✗ Manual execution error: {e}")
            return False
    
    def monitor_execution(self, execution_id: str, timeout: int = 300) -> bool:
        """Monitor workflow execution until completion"""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                response = requests.get(
                    f"{self.n8n_base_url}/rest/executions/{execution_id}"
                )
                
                if response.status_code == 200:
                    execution = response.json()
                    status = execution.get('status', 'unknown')
                    
                    if status == 'success':
                        print(f"✓ Execution completed successfully")
                        self.analyze_execution_results(execution)
                        return True
                    elif status == 'error':
                        print(f"✗ Execution failed with error")
                        self.analyze_execution_errors(execution)
                        return False
                    elif status in ['waiting', 'running']:
                        print(f"⏳ Execution status: {status}")
                        time.sleep(10)
                    else:
                        print(f"? Unknown execution status: {status}")
                        time.sleep(5)
                else:
                    print(f"✗ Failed to get execution status: {response.status_code}")
                    return False
                    
            except Exception as e:
                print(f"✗ Error monitoring execution: {e}")
                return False
        
        print(f"✗ Execution timeout after {timeout} seconds")
        return False
    
    def analyze_execution_results(self, execution: Dict[str, Any]):
        """Analyze successful execution results"""
        print("\n📊 Execution Analysis:")
        
        data = execution.get('data', {})
        
        # Check if all nodes executed
        if 'resultData' in data:
            result_data = data['resultData']
            nodes_executed = len(result_data.get('runData', {}))
            print(f"Nodes executed: {nodes_executed}")
            
            # Check for specific node outputs
            run_data = result_data.get('runData', {})
            
            # Orchestrator output
            if 'Orchestrator Agent' in run_data:
                orchestrator_output = run_data['Orchestrator Agent'][0]['data']['main'][0]
                print(f"Orchestrator symbols: {len(orchestrator_output)} generated")
            
            # Analysis results
            if 'Merge Analysis Results' in run_data:
                merge_output = run_data['Merge Analysis Results'][0]['data']['main'][0]
                print(f"Analysis results: {len(merge_output)} opportunities")
            
            # Validator output
            if 'Risk Validator Agent' in run_data:
                validator_output = run_data['Risk Validator Agent'][0]['data']['main'][0]
                print(f"Validation completed: {validator_output}")
            
            # Final logger
            if 'Execution Logger' in run_data:
                logger_output = run_data['Execution Logger'][0]['data']['main'][0]
                print(f"Final status: {logger_output[0]['json']['workflow_status']}")
    
    def analyze_execution_errors(self, execution: Dict[str, Any]):
        """Analyze failed execution for debugging"""
        print("\n❌ Execution Error Analysis:")
        
        data = execution.get('data', {})
        
        if 'resultData' in data:
            result_data = data['resultData']
            
            # Check for error information
            if 'error' in result_data:
                error = result_data['error']
                print(f"Error message: {error.get('message', 'Unknown error')}")
                print(f"Error node: {error.get('node', 'Unknown node')}")
            
            # Check last successful node
            run_data = result_data.get('runData', {})
            last_node = max(run_data.keys()) if run_data else "None"
            print(f"Last successful node: {last_node}")
    
    def test_mcp_server_connectivity(self) -> bool:
        """Test MCP server configurations"""
        print("\n🔌 Testing MCP Server Connectivity:")
        
        mcp_configs = [
            "../../mcp-servers/financial-data-server.json",
            "../../mcp-servers/broker-api-server.json", 
            "../../mcp-servers/risk-management-server.json"
        ]
        
        all_valid = True
        
        for config_path in mcp_configs:
            try:
                with open(config_path, 'r') as f:
                    config = json.load(f)
                    
                # Validate configuration structure
                if 'mcpServers' in config:
                    servers = config['mcpServers']
                    print(f"✓ {config_path}: {len(servers)} servers configured")
                else:
                    print(f"✗ {config_path}: Invalid configuration structure")
                    all_valid = False
                    
            except Exception as e:
                print(f"✗ {config_path}: Error reading config - {e}")
                all_valid = False
        
        return all_valid
    
    def test_risk_parameters(self) -> bool:
        """Test risk management parameter validation"""
        print("\n⚖️ Testing Risk Parameters:")
        
        workflow = self.load_workflow()
        
        # Find global variables node
        global_vars_node = None
        for node in workflow['nodes']:
            if node['name'] == 'Set Global Variables':
                global_vars_node = node
                break
        
        if not global_vars_node:
            print("✗ Global variables node not found")
            return False
        
        assignments = global_vars_node['parameters']['assignments']['assignments']
        
        # Check risk parameters
        risk_params = {
            'risk_tolerance': 0.02,
            'max_position_size': 1000,
            'target_delta': 0.0
        }
        
        all_valid = True
        for param_name, expected_value in risk_params.items():
            param = next((a for a in assignments if a['name'] == param_name), None)
            if param and param['value'] == expected_value:
                print(f"✓ {param_name}: {param['value']}")
            else:
                print(f"✗ {param_name}: Invalid or missing")
                all_valid = False
        
        return all_valid
    
    def run_all_tests(self) -> bool:
        """Run complete integration test suite"""
        print("🧪 Starting Integration Test Suite")
        print("=" * 50)
        
        tests = [
            ("MCP Server Connectivity", self.test_mcp_server_connectivity),
            ("Risk Parameters", self.test_risk_parameters),
            ("Workflow Import", self.test_workflow_import),
            ("Manual Execution", self.test_manual_execution)
        ]
        
        results = []
        
        for test_name, test_func in tests:
            print(f"\n🔧 Running {test_name} Test...")
            try:
                result = test_func()
                results.append((test_name, result))
                status = "PASS" if result else "FAIL"
                print(f"📋 {test_name}: {status}")
            except Exception as e:
                print(f"📋 {test_name}: ERROR - {e}")
                results.append((test_name, False))
        
        # Summary
        print("\n" + "=" * 50)
        print("📊 Integration Test Summary:")
        
        passed = sum(1 for _, result in results if result)
        total = len(results)
        
        for test_name, result in results:
            status = "✓ PASS" if result else "✗ FAIL"
            print(f"{status}: {test_name}")
        
        print(f"\nTests Passed: {passed}/{total}")
        
        if passed == total:
            print("🎉 All integration tests passed!")
            return True
        else:
            print("❌ Some integration tests failed!")
            return False

def main():
    """Main test execution function"""
    tester = WorkflowIntegrationTest()
    success = tester.run_all_tests()
    exit(0 if success else 1)

if __name__ == "__main__":
    main()