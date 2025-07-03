/**
 * Unit Tests for Stock Options Trading Workflow Components
 * Tests individual node configurations and data flow
 */

const fs = require('fs');
const path = require('path');

// Load workflow JSON
const workflowPath = path.join(__dirname, '../../workflows/stock-options-trading-workflow.json');
const workflow = JSON.parse(fs.readFileSync(workflowPath, 'utf8'));

describe('Stock Options Trading Workflow', () => {
  
  describe('Schedule Trigger Configuration', () => {
    test('should have correct cron expression for market hours', () => {
      const scheduleTrigger = workflow.nodes.find(node => 
        node.type === 'n8n-nodes-base.scheduleTrigger'
      );
      
      expect(scheduleTrigger).toBeDefined();
      expect(scheduleTrigger.parameters.rule.interval[0].expression)
        .toBe('0 9,15 * * 1-5');
    });
    
    test('should have proper trigger configuration', () => {
      const scheduleTrigger = workflow.nodes.find(node => 
        node.type === 'n8n-nodes-base.scheduleTrigger'
      );
      
      expect(scheduleTrigger.typeVersion).toBe(1.2);
      expect(scheduleTrigger.position).toEqual([0, 0]);
    });
  });

  describe('Global Variables Configuration', () => {
    test('should configure all required global variables', () => {
      const globalVars = workflow.nodes.find(node => 
        node.name === 'Set Global Variables'
      );
      
      expect(globalVars).toBeDefined();
      expect(globalVars.type).toBe('n8n-nodes-base.set');
      
      const assignments = globalVars.parameters.assignments.assignments;
      const varNames = assignments.map(a => a.name);
      
      expect(varNames).toContain('max_symbols_per_batch');
      expect(varNames).toContain('max_parallel_agents');
      expect(varNames).toContain('risk_tolerance');
      expect(varNames).toContain('max_position_size');
      expect(varNames).toContain('target_delta');
    });
    
    test('should have correct default values', () => {
      const globalVars = workflow.nodes.find(node => 
        node.name === 'Set Global Variables'
      );
      
      const assignments = globalVars.parameters.assignments.assignments;
      
      const riskTolerance = assignments.find(a => a.name === 'risk_tolerance');
      expect(riskTolerance.value).toBe(0.02);
      
      const maxPositionSize = assignments.find(a => a.name === 'max_position_size');
      expect(maxPositionSize.value).toBe(1000);
      
      const targetDelta = assignments.find(a => a.name === 'target_delta');
      expect(targetDelta.value).toBe(0.0);
    });
  });

  describe('Agent Configurations', () => {
    test('should have orchestrator agent configured', () => {
      const orchestrator = workflow.nodes.find(node => 
        node.name === 'Orchestrator Agent'
      );
      
      expect(orchestrator).toBeDefined();
      expect(orchestrator.type).toBe('@n8n/n8n-nodes-langchain.agent');
      expect(orchestrator.parameters.options.temperature).toBe(0.2);
    });
    
    test('should have three analysis subagents', () => {
      const subagents = workflow.nodes.filter(node => 
        node.name.includes('Options Analysis Subagent')
      );
      
      expect(subagents).toHaveLength(3);
      subagents.forEach(agent => {
        expect(agent.type).toBe('@n8n/n8n-nodes-langchain.agent');
        expect(agent.parameters.options.temperature).toBe(0.3);
      });
    });
    
    test('should have validator agent configured', () => {
      const validator = workflow.nodes.find(node => 
        node.name === 'Risk Validator Agent'
      );
      
      expect(validator).toBeDefined();
      expect(validator.type).toBe('@n8n/n8n-nodes-langchain.agent');
      expect(validator.parameters.options.temperature).toBe(0.2);
    });
    
    test('should have trade execution agent', () => {
      const executor = workflow.nodes.find(node => 
        node.name === 'Trade Execution Agent'
      );
      
      expect(executor).toBeDefined();
      expect(executor.type).toBe('@n8n/n8n-nodes-langchain.agent');
      expect(executor.parameters.options.temperature).toBe(0.1);
    });
  });

  describe('Data Processing Nodes', () => {
    test('should have symbol list processor', () => {
      const processor = workflow.nodes.find(node => 
        node.name === 'Process Symbol List'
      );
      
      expect(processor).toBeDefined();
      expect(processor.type).toBe('n8n-nodes-base.set');
    });
    
    test('should have batch splitter configured', () => {
      const splitter = workflow.nodes.find(node => 
        node.name === 'Split Symbol Batches'
      );
      
      expect(splitter).toBeDefined();
      expect(splitter.type).toBe('n8n-nodes-base.splitInBatches');
      expect(splitter.executeOnce).toBe(false);
    });
    
    test('should have merge node for analysis results', () => {
      const merger = workflow.nodes.find(node => 
        node.name === 'Merge Analysis Results'
      );
      
      expect(merger).toBeDefined();
      expect(merger.type).toBe('n8n-nodes-base.merge');
      expect(merger.parameters.mode).toBe('append');
    });
  });

  describe('Conditional Logic', () => {
    test('should have opportunity check conditional', () => {
      const conditional = workflow.nodes.find(node => 
        node.name === 'Check Approved Opportunities'
      );
      
      expect(conditional).toBeDefined();
      expect(conditional.type).toBe('n8n-nodes-base.if');
      
      const condition = conditional.parameters.conditions.conditions[0];
      expect(condition.operator.operation).toBe('gt');
      expect(condition.rightValue).toBe(0);
    });
  });

  describe('Logging Configuration', () => {
    test('should have execution logger', () => {
      const logger = workflow.nodes.find(node => 
        node.name === 'Execution Logger'
      );
      
      expect(logger).toBeDefined();
      expect(logger.type).toBe('n8n-nodes-base.set');
    });
    
    test('should have no opportunities logger', () => {
      const logger = workflow.nodes.find(node => 
        node.name === 'No Opportunities Logger'
      );
      
      expect(logger).toBeDefined();
      expect(logger.type).toBe('n8n-nodes-base.set');
    });
  });

  describe('Error Handling', () => {
    test('should have retry configuration on critical nodes', () => {
      const criticalNodes = workflow.nodes.filter(node => 
        node.type === '@n8n/n8n-nodes-langchain.agent'
      );
      
      criticalNodes.forEach(node => {
        if (node.name !== 'Trade Execution Agent') {
          expect(node.retryOnFail).toBe(true);
          expect(node.maxTries).toBeGreaterThan(1);
        }
      });
    });
    
    test('should have continue on fail for non-critical operations', () => {
      const analysisAgents = workflow.nodes.filter(node => 
        node.name.includes('Analysis Subagent')
      );
      
      analysisAgents.forEach(agent => {
        expect(agent.continueOnFail).toBe(true);
      });
    });
  });

  describe('Workflow Connections', () => {
    test('should have proper node connections defined', () => {
      expect(workflow.connections).toBeDefined();
      expect(Object.keys(workflow.connections).length).toBeGreaterThan(5);
    });
    
    test('should connect schedule trigger to global variables', () => {
      const triggerConnections = workflow.connections['Market Hours Trigger'];
      expect(triggerConnections).toBeDefined();
      expect(triggerConnections.main[0][0].node).toBe('Set Global Variables');
    });
    
    test('should connect split batches to all subagents', () => {
      const splitConnections = workflow.connections['Split Symbol Batches'];
      expect(splitConnections).toBeDefined();
      expect(splitConnections.main[0].length).toBe(3);
    });
  });

  describe('Workflow Metadata', () => {
    test('should have correct workflow metadata', () => {
      expect(workflow.name).toBe('Stock Options Trading - Delta Neutral Strategy');
      expect(workflow.active).toBe(false);
      expect(workflow.tags).toContain('trading');
      expect(workflow.tags).toContain('options');
      expect(workflow.tags).toContain('delta-neutral');
    });
  });
});

// Helper function to run tests
function runTests() {
  console.log('🧪 Running unit tests for workflow components...');
  
  try {
    // Simple test runner (in real scenario, use Jest or Mocha)
    const tests = [
      () => testScheduleTrigger(),
      () => testGlobalVariables(), 
      () => testAgentConfigurations(),
      () => testDataProcessing(),
      () => testErrorHandling()
    ];
    
    let passed = 0;
    let failed = 0;
    
    tests.forEach((test, index) => {
      try {
        test();
        console.log(`✓ Test ${index + 1} passed`);
        passed++;
      } catch (error) {
        console.log(`✗ Test ${index + 1} failed:`, error.message);
        failed++;
      }
    });
    
    console.log(`\n📊 Test Summary: ${passed} passed, ${failed} failed`);
    return failed === 0;
    
  } catch (error) {
    console.error('❌ Test execution failed:', error);
    return false;
  }
}

// Individual test functions
function testScheduleTrigger() {
  const trigger = workflow.nodes.find(n => n.type === 'n8n-nodes-base.scheduleTrigger');
  if (!trigger) throw new Error('Schedule trigger not found');
  if (trigger.parameters.rule.interval[0].expression !== '0 9,15 * * 1-5') {
    throw new Error('Incorrect cron expression');
  }
}

function testGlobalVariables() {
  const globalVars = workflow.nodes.find(n => n.name === 'Set Global Variables');
  if (!globalVars) throw new Error('Global variables node not found');
  
  const assignments = globalVars.parameters.assignments.assignments;
  const requiredVars = ['max_symbols_per_batch', 'risk_tolerance', 'max_position_size'];
  
  requiredVars.forEach(varName => {
    if (!assignments.find(a => a.name === varName)) {
      throw new Error(`Required variable ${varName} not found`);
    }
  });
}

function testAgentConfigurations() {
  const agents = workflow.nodes.filter(n => n.type === '@n8n/n8n-nodes-langchain.agent');
  if (agents.length < 5) throw new Error('Insufficient agents configured');
  
  const orchestrator = agents.find(a => a.name === 'Orchestrator Agent');
  if (!orchestrator) throw new Error('Orchestrator agent not found');
}

function testDataProcessing() {
  const splitter = workflow.nodes.find(n => n.type === 'n8n-nodes-base.splitInBatches');
  if (!splitter) throw new Error('Batch splitter not found');
  
  const merger = workflow.nodes.find(n => n.type === 'n8n-nodes-base.merge');
  if (!merger) throw new Error('Merge node not found');
}

function testErrorHandling() {
  const agents = workflow.nodes.filter(n => n.type === '@n8n/n8n-nodes-langchain.agent');
  const retryEnabled = agents.filter(a => a.retryOnFail === true);
  if (retryEnabled.length === 0) throw new Error('No retry logic configured');
}

// Export for use in test frameworks
module.exports = {
  runTests,
  testScheduleTrigger,
  testGlobalVariables,
  testAgentConfigurations,
  testDataProcessing,
  testErrorHandling
};

// Run tests if executed directly
if (require.main === module) {
  const success = runTests();
  process.exit(success ? 0 : 1);
}