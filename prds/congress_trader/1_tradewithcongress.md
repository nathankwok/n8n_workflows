# PRD: Congress Trade Tracker - @tradewithcongress Threads Integration

## Executive Summary

This PRD outlines the integration of Threads social media monitoring into the existing Congress Trade Tracker n8n workflow. The enhancement will add real-time social media alerts from @tradewithcongress to complement the existing QuiverQuant data source, providing comprehensive monitoring of congressional trading activity.

## Current State Analysis

### Existing Workflow Structure
**File:** `/root/repo/workflows/Congress_Trade_Tracker.json`

**Current Flow:**
1. **Schedule Trigger** → Daily at 6 PM (18:00)
2. **HTTP Request (Extract)** → Firecrawl API to scrape QuiverQuant congress trading data
3. **Wait 30 Secs** → Processing delay for Firecrawl
4. **HTTP Request (Get Results)** → Retrieve Firecrawl extraction results
5. **Code Node** → Parse and structure trade data
6. **If Node** → Check if trades data exists
7. **Edit Fields** → Format data for LLM processing
8. **Basic LLM Chain** → Format trades into readable text using Google Gemini
9. **Gmail Send** → Email formatted results to stocks@mailrelayer.xyz

**Key Components:**
- Uses Firecrawl API for web scraping (credentials: "Firecrawl Auth Header")
- Google Gemini LLM for text formatting (credentials: "Google Gemini(PaLM) Api account")
- Gmail integration for notifications (credentials: "Gmail - ngrok")
- Filters for trades >$50,000 from past month

## Project Objectives

### Primary Goals
1. **Real-time Social Media Monitoring**: Monitor @tradewithcongress Threads account for breaking news and urgent alerts
2. **Same-day Filtering**: Process only posts from the current execution date
3. **Intelligent Content Analysis**: Distinguish between breaking news about recent filings vs. historical trade discussions
4. **Integrated Reporting**: Combine Threads alerts with existing QuiverQuant data in unified email notifications

### Success Metrics
- Detection of urgent congressional trading alerts within same day
- Reduced false positives from historical trade discussions
- Enhanced notification quality with social media context
- Maintained system reliability and performance

## Technical Requirements

### Core Technologies
- **n8n Workflow Platform**: Version with LangChain nodes support
- **Firecrawl API**: For consistent web scraping across both data sources
- **Google Gemini LLM**: For natural language analysis and formatting
- **Gmail API**: For notification delivery

### Required n8n Nodes

#### 1. HTTP Request Node (`nodes-base.httpRequest` v4.2)
**Purpose**: Scrape @tradewithcongress Threads profile
```json
{
  "method": "POST",
  "url": "https://api.firecrawl.dev/v1/extract",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "sendBody": true,
  "specifyBody": "json",
  "jsonBody": {
    "urls": ["https://www.threads.com/@tradewithcongress"],
    "prompt": "Extract the latest 10 posts from this Threads profile. Include the post content, timestamp, engagement metrics, and any mentioned stock tickers or congress member names.",
    "schema": {
      "type": "object",
      "properties": {
        "threads_posts": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "content": {"type": "string"},
              "timestamp": {"type": "string"},
              "author": {"type": "string"},
              "likes_count": {"type": "number"},
              "replies_count": {"type": "number"},
              "reposts_count": {"type": "number"}
            },
            "required": ["content", "timestamp", "author"]
          }
        }
      }
    }
  }
}
```

#### 2. Code Node (`nodes-base.code` v2)
**Purpose**: Filter posts to same-day only
```javascript
// Filter Threads posts to same day only
const today = new Date();
const todayDateString = today.toISOString().split('T')[0]; // YYYY-MM-DD format

if (!$json.data || !$json.data.threads_posts) {
  return [{ json: { threads_posts: [] } }];
}

const todayPosts = $json.data.threads_posts.filter(post => {
  try {
    const postDate = new Date(post.timestamp);
    const postDateString = postDate.toISOString().split('T')[0];
    return postDateString === todayDateString;
  } catch (error) {
    console.log('Error parsing date:', post.timestamp);
    return false;
  }
});

return [{ json: { threads_posts: todayPosts, execution_date: todayDateString } }];
```

#### 3. Basic LLM Chain Node (`nodes-langchain.chainLlm` v1.7)
**Purpose**: Analyze posts for breaking news and urgency
```json
{
  "promptType": "define",
  "text": "={{ $json.threads_posts }}",
  "messages": {
    "messageValues": [
      {
        "message": "You are a financial news analyst specializing in congressional trading. Analyze the provided Threads posts and identify which ones contain BREAKING NEWS or URGENT ALERTS about RECENT congressional trade filings (today or yesterday).\n\nFocus on:\n- Posts with words like 'BREAKING', 'URGENT', 'ALERT', 'JUST FILED', 'TODAY'\n- Recent trade filings (not historical performance)\n- New insider trading disclosures\n- Immediate market-moving information\n\nIGNORE:\n- Historical trade performance discussions\n- General market commentary\n- Posts about trades from weeks/months ago\n- Educational content about past trades\n\nReturn only the urgent/breaking posts with a urgency score (1-10) and brief analysis of why each is urgent."
      }
    ]
  }
}
```

#### 4. Code Node (`nodes-base.code` v2)
**Purpose**: Merge Threads alerts with QuiverQuant data
```javascript
// Merge Threads urgent alerts with QuiverQuant trades data
const threadsData = $input.first(); // From Threads analysis
const quiverData = $input.last();   // From existing QuiverQuant flow

const mergedData = {
  quiver_trades: quiverData?.json?.trades || [],
  threads_alerts: threadsData?.json?.urgent_posts || [],
  analysis_date: new Date().toISOString().split('T')[0],
  has_urgent_alerts: (threadsData?.json?.urgent_posts || []).length > 0,
  total_quiver_trades: (quiverData?.json?.trades || []).length
};

// Add context flag for email formatting
mergedData.send_notification = mergedData.has_urgent_alerts || mergedData.total_quiver_trades > 0;

return [{ json: mergedData }];
```

#### 5. If Node (`nodes-base.if` v2.2)
**Purpose**: Only send notifications if urgent content or trades found
```json
{
  "conditions": {
    "options": {
      "version": 2,
      "leftValue": "",
      "caseSensitive": true,
      "typeValidation": "strict"
    },
    "combinator": "or",
    "conditions": [
      {
        "operator": {
          "type": "boolean",
          "operation": "true"
        },
        "leftValue": "={{ $json.send_notification }}",
        "rightValue": ""
      }
    ]
  }
}
```

#### 6. Basic LLM Chain Node (`nodes-langchain.chainLlm` v1.7)
**Purpose**: Format combined data for email
```json
{
  "promptType": "define",
  "text": "={{ $json }}",
  "messages": {
    "messageValues": [
      {
        "message": "Format this congressional trading data into a professional email report. Structure it as:\n\n1. URGENT ALERTS (if any Threads alerts exist)\n   - List each urgent alert with timestamp and summary\n   - Highlight key details (congress member, stock, amount, urgency reason)\n\n2. DAILY TRADE SUMMARY (QuiverQuant data)\n   - List significant trades >$50k\n   - Include congress member, party, stock/asset, amount, date\n\n3. SUMMARY\n   - Brief overview of total alerts and trades\n   - Key takeaways for the day\n\nUse clear formatting with bullet points and highlight urgent items with ** markers."
      }
    ]
  }
}
```

## Implementation Phases

### Phase 1: Threads Data Collection (Week 1)
**Tasks:**
1. Create new HTTP Request node for Threads scraping
2. Configure Firecrawl extraction with Threads-specific schema
3. Add error handling for failed Threads requests
4. Test data extraction with sample @tradewithcongress posts

**Deliverables:**
- Functional Threads scraping node
- Validated data extraction schema
- Error handling implementation

**Testing Criteria:**
- Successfully extract 10 most recent posts
- Handle API rate limits gracefully
- Parse timestamps and content correctly

### Phase 2: Same-Day Filtering Logic (Week 1)
**Tasks:**
1. Implement date filtering in Code node
2. Handle timezone considerations (EST for US markets)
3. Add validation for date parsing edge cases
4. Test with various timestamp formats

**Deliverables:**
- Date filtering Code node
- Timezone handling logic
- Edge case validation

**Testing Criteria:**
- Correctly filter posts to execution date only
- Handle various timestamp formats
- Maintain data integrity through filtering

### Phase 3: Breaking News Analysis (Week 2)
**Tasks:**
1. Design LLM prompt for urgency detection
2. Implement scoring system (1-10 urgency scale)
3. Create keyword detection patterns
4. Test with historical urgent vs. non-urgent posts

**Deliverables:**
- LLM analysis node with optimized prompts
- Urgency scoring system
- Validation against test cases

**Testing Criteria:**
- Accurate identification of urgent vs. historical content
- Consistent urgency scoring
- Low false positive rate (<10%)

### Phase 4: Data Integration & Output (Week 2)
**Tasks:**
1. Merge Threads alerts with QuiverQuant data
2. Update email formatting with combined content
3. Implement conditional notification logic
4. Test end-to-end workflow

**Deliverables:**
- Data merging logic
- Enhanced email template
- Conditional notification system

**Testing Criteria:**
- Seamless data integration
- Professional email formatting
- Appropriate notification triggers

### Phase 5: Error Handling & Optimization (Week 3)
**Tasks:**
1. Add retry logic for Threads scraping failures
2. Implement fallback to QuiverQuant-only mode
3. Add monitoring and alerting for component failures
4. Performance optimization and rate limiting

**Deliverables:**
- Comprehensive error handling
- Fallback mechanisms
- Monitoring system
- Performance optimizations

**Testing Criteria:**
- Graceful degradation on Threads API failures
- Maintained functionality with partial data
- Optimal performance within rate limits

## Enhanced Workflow Architecture

### New Workflow Structure
```
Schedule Trigger (6 PM Daily)
├── QuiverQuant Branch (Existing)
│   ├── HTTP Request (Extract QuiverQuant)
│   ├── Wait 30 Secs
│   ├── HTTP Request (Get Results)
│   └── Code (Parse Trades)
└── Threads Branch (New)
    ├── HTTP Request (Extract Threads)
    ├── Wait 30 Secs  
    ├── HTTP Request (Get Threads Results)
    ├── Code (Filter Same-Day Posts)
    └── LLM Chain (Analyze Urgency)

Merge Point
├── Code (Merge Data Sources)
├── If (Check Send Conditions)
├── LLM Chain (Format Email)
└── Gmail (Send Notification)
```

### Node Connections Schema
```json
{
  "Schedule Trigger": {
    "main": [
      ["Extract QuiverQuant", 0],
      ["Extract Threads", 0]
    ]
  },
  "Extract QuiverQuant": {
    "main": [["Wait 30 Secs (QuiverQuant)", 0]]
  },
  "Extract Threads": {
    "main": [["Wait 30 Secs (Threads)", 0]]
  },
  "Parse Trades": {
    "main": [["Merge Data Sources", 0]]
  },
  "Analyze Urgency": {
    "main": [["Merge Data Sources", 1]]
  },
  "Merge Data Sources": {
    "main": [["Check Send Conditions", 0]]
  },
  "Check Send Conditions": {
    "main": [
      ["Format Email", 0],
      ["No Action", 0]
    ]
  }
}
```

## Data Schemas

### Threads Posts Schema
```json
{
  "type": "object",
  "properties": {
    "threads_posts": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "content": {
            "type": "string",
            "description": "Full text content of the post"
          },
          "timestamp": {
            "type": "string",
            "description": "ISO timestamp of post creation"
          },
          "author": {
            "type": "string", 
            "description": "Post author username"
          },
          "likes_count": {
            "type": "number",
            "description": "Number of likes on the post"
          },
          "replies_count": {
            "type": "number",
            "description": "Number of replies to the post"
          },
          "reposts_count": {
            "type": "number",
            "description": "Number of reposts/shares"
          },
          "mentioned_tickers": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Stock tickers mentioned in post"
          },
          "mentioned_members": {
            "type": "array", 
            "items": {"type": "string"},
            "description": "Congress members mentioned"
          }
        },
        "required": ["content", "timestamp", "author"]
      }
    }
  }
}
```

### Urgent Analysis Schema
```json
{
  "type": "object",
  "properties": {
    "urgent_posts": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "original_content": {"type": "string"},
          "urgency_score": {
            "type": "number",
            "minimum": 1,
            "maximum": 10
          },
          "urgency_reason": {"type": "string"},
          "mentioned_member": {"type": "string"},
          "mentioned_stock": {"type": "string"},
          "trade_amount": {"type": "string"},
          "filing_type": {"type": "string"},
          "timestamp": {"type": "string"},
          "market_impact": {
            "type": "string",
            "enum": ["HIGH", "MEDIUM", "LOW"]
          }
        },
        "required": ["original_content", "urgency_score", "urgency_reason"]
      }
    }
  }
}
```

### Merged Data Schema
```json
{
  "type": "object",
  "properties": {
    "quiver_trades": {
      "type": "array",
      "description": "Trades from QuiverQuant (existing schema)"
    },
    "threads_alerts": {
      "type": "array", 
      "description": "Urgent posts from Threads analysis"
    },
    "analysis_date": {
      "type": "string",
      "description": "Date of analysis (YYYY-MM-DD)"
    },
    "has_urgent_alerts": {
      "type": "boolean",
      "description": "Whether urgent Threads alerts were found"
    },
    "total_quiver_trades": {
      "type": "number",
      "description": "Count of QuiverQuant trades found"
    },
    "send_notification": {
      "type": "boolean",
      "description": "Whether to send email notification"
    }
  }
}
```

## LLM Prompt Engineering

### Threads Analysis Prompt (Critical)
```
You are a financial news analyst specializing in congressional trading alerts. Analyze the provided Threads posts from @tradewithcongress and identify which contain BREAKING NEWS or URGENT ALERTS about RECENT congressional trade filings.

CRITERIA FOR URGENT POSTS:
1. Contains urgency indicators: "BREAKING", "URGENT", "ALERT", "🚨", "JUST FILED", "TODAY", "YESTERDAY"
2. References RECENT trade filings (today/yesterday/this week)
3. Mentions specific dollar amounts and congress members
4. Indicates NEW insider trading disclosures
5. Contains immediate market-moving information

IGNORE THESE POST TYPES:
- Historical trade performance discussions
- General market commentary  
- Educational content about past trades (>1 week old)
- Posts about trade results/gains/losses
- Routine congressional calendar updates

ANALYSIS REQUIREMENTS:
- Urgency Score: 1-10 (10 = immediate market impact)
- Extract: Congress member name, stock ticker, trade amount, filing type
- Reason: Why this post qualifies as urgent
- Market Impact: HIGH/MEDIUM/LOW based on trade size and member prominence

Return JSON with urgent posts only. If no urgent posts found, return empty array.
```

### Email Formatting Prompt
```
Format this congressional trading intelligence into a professional email report.

STRUCTURE:
1. URGENT SOCIAL MEDIA ALERTS (if any)
   - **BREAKING**: [Timestamp] - [Congress Member] filed [Trade Type] 
   - Amount: [Dollar Amount]
   - Stock: [Ticker/Company]
   - Urgency: [Reason for urgency]
   - Market Impact: [HIGH/MEDIUM/LOW]

2. DAILY QUIVERQUANT TRADES SUMMARY  
   - [Date] - [Member Name] ([Party]) - [Action] [Amount] in [Stock]
   - [Additional trades...]

3. INTELLIGENCE SUMMARY
   - Total urgent alerts: [Count]
   - Total tracked trades: [Count] 
   - Key takeaways: [Brief analysis]
   - Recommended actions: [If applicable]

FORMATTING:
- Use ** for urgent items
- Include 🚨 for high-impact alerts
- Keep bullet points concise but informative
- Add timestamp for credibility
- Professional tone suitable for financial intelligence
```

## Risk Management & Monitoring

### API Rate Limiting
- **Firecrawl API**: Respect rate limits, implement exponential backoff
- **Threads Access**: Use Firecrawl as proxy to avoid direct API issues
- **Gmail API**: Monitor send quotas

### Error Handling Scenarios
1. **Threads Scraping Fails**: Continue with QuiverQuant data only
2. **Both Sources Fail**: Send error notification to admin
3. **LLM Analysis Fails**: Send raw data with error note
4. **Email Delivery Fails**: Log error, retry once

### Data Quality Monitoring
- Track extraction success rates
- Monitor false positive rates for urgency detection
- Validate timestamp parsing accuracy
- Alert on significant data volume changes

### Security Considerations
- Store API credentials securely in n8n
- Use HTTPS for all external requests
- Implement request timeout limits
- Log access attempts without sensitive data

## Testing Strategy

### Unit Testing
1. **Threads Extraction**: Validate schema compliance and data quality
2. **Date Filtering**: Test with various timestamp formats and timezones
3. **Urgency Analysis**: Test with known urgent vs. non-urgent posts
4. **Data Merging**: Verify proper data combination and formatting

### Integration Testing  
1. **End-to-End Flow**: Complete workflow execution
2. **Error Scenarios**: API failures and data anomalies
3. **Performance**: Response times and resource usage
4. **Email Delivery**: Formatting and recipient validation

### User Acceptance Testing
1. **Content Quality**: Verify urgent alerts are actually urgent
2. **False Positive Rate**: Ensure <10% false positives for urgency
3. **Email Readability**: Professional formatting and clear information
4. **Notification Timing**: Appropriate send frequency

## Performance Specifications

### Response Time Targets
- **Threads Extraction**: <60 seconds
- **Data Processing**: <30 seconds
- **LLM Analysis**: <45 seconds  
- **Total Workflow**: <3 minutes

### Reliability Requirements
- **Uptime**: 99.5% availability
- **Error Rate**: <5% failed executions
- **Data Accuracy**: >95% correct urgency classifications

### Scalability Considerations
- **Post Volume**: Handle up to 50 posts per day
- **Peak Load**: Support during market hours
- **Future Growth**: Extensible to additional social media sources

## Deployment Instructions

### Prerequisites
- n8n instance with LangChain nodes package
- Firecrawl API credentials with sufficient quota
- Google Gemini API access
- Gmail API credentials with send permissions

### Configuration Steps
1. **Import Enhanced Workflow**: Load updated JSON configuration
2. **Update Credentials**: Configure all API credentials in n8n
3. **Test Components**: Verify each node individually
4. **Validate Email Output**: Test with sample data
5. **Monitor Initial Runs**: Watch for errors in first week

### Rollback Plan
- Keep original workflow as backup
- Document all configuration changes
- Prepare quick revert procedure
- Maintain separate test environment

## Success Metrics & KPIs

### Operational Metrics
- **Execution Success Rate**: >95%
- **Data Extraction Accuracy**: >90%
- **Email Delivery Rate**: >99%
- **Average Processing Time**: <3 minutes

### Business Value Metrics
- **Urgent Alert Detection**: Capture >80% of actual urgent news
- **False Positive Rate**: <10% non-urgent alerts marked urgent
- **Time to Notification**: <5 minutes from post publication
- **User Satisfaction**: Positive feedback on email content quality

### Monitoring Dashboard
- Daily execution status
- Error rates by component
- Data volume trends
- Email delivery metrics
- API quota utilization

## Maintenance & Support

### Regular Maintenance Tasks
- **Weekly**: Review error logs and performance metrics
- **Monthly**: Validate urgency detection accuracy
- **Quarterly**: Update LLM prompts based on performance data
- **As Needed**: Adjust for Threads platform changes

### Support Procedures
- **Monitoring**: Automated alerts for component failures
- **Escalation**: Clear procedures for urgent issues
- **Documentation**: Maintain operational runbooks
- **Updates**: Process for schema and prompt modifications

### Future Enhancement Opportunities
1. **Multi-Platform Support**: Add Twitter/X monitoring
2. **Advanced Analytics**: Pattern recognition in trading behavior
3. **Real-Time Alerts**: Push notifications for highest urgency items
4. **Machine Learning**: Improve urgency classification over time

---

## Appendix

### A. Firecrawl Configuration Examples
```json
{
  "urls": ["https://www.threads.com/@tradewithcongress"],
  "prompt": "Extract latest 10 posts with content, timestamps, and engagement metrics",
  "schema": {
    "type": "object",
    "properties": {
      "threads_posts": {
        "type": "array",
        "maxItems": 10,
        "items": {
          "type": "object",
          "properties": {
            "content": {"type": "string"},
            "timestamp": {"type": "string"},
            "author": {"type": "string"},
            "likes_count": {"type": "number"},
            "replies_count": {"type": "number"}
          },
          "required": ["content", "timestamp"]
        }
      }
    }
  },
  "pageOptions": {
    "waitFor": 3000,
    "screenshot": false
  }
}
```

### B. Node Positioning Coordinates
```json
{
  "Extract Threads": [500, 150],
  "Wait 30 Secs (Threads)": [700, 150], 
  "Get Threads Results": [900, 150],
  "Filter Same Day": [1100, 150],
  "Analyze Urgency": [1300, 150],
  "Merge Data Sources": [1500, 300],
  "Check Send Conditions": [1700, 300],
  "Format Email": [1900, 300]
}
```

### C. Credential Requirements
- **Firecrawl Auth Header**: Bearer token for Firecrawl API
- **Google Gemini(PaLM) Api**: API key for LLM access
- **Gmail - ngrok**: OAuth2 credentials for email sending

This PRD provides comprehensive implementation guidance for integrating @tradewithcongress Threads monitoring into the existing Congress Trade Tracker workflow, enabling real-time social media intelligence alongside traditional data sources.