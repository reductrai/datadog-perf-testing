# ReductrAI Docker + Datadog Integration

Complete Docker deployment of ReductrAI proxy with Datadog integration for performance testing and monitoring.

## Overview

This setup deploys ReductrAI as a compression proxy between your applications and Datadog, automatically reducing metric payload sizes while maintaining 100% data fidelity.

## Architecture

```
Your Apps → ReductrAI Proxy (localhost:8080) → Datadog API
                    ↓
              Dashboard UI (localhost:5173)
```

## Prerequisites

- Docker and Docker Compose installed
- Internet connection (to pull images from Docker Hub)
- Datadog API key (free trial available at https://www.datadoghq.com)
- ReductrAI license key (use `RF-DEMO-2025` for demo/testing)

## Quick Start

### 1. Configure Environment Variables

Create or update `.env` file in this directory:

```bash
# ReductrAI License (Required)
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025

# Datadog (Required for Datadog integration)
DATADOG_API_KEY=your_datadog_api_key_here
DATADOG_ENDPOINT=https://api.datadoghq.com

# Other backends (Optional)
NEW_RELIC_API_KEY=
PROMETHEUS_ENDPOINT=
OTLP_ENDPOINT=
```

### 2. Start the Services

**Start proxy only** (recommended for testing):
```bash
docker-compose up -d proxy
```

**Start all services** (proxy + dashboard + ai-query):
```bash
docker-compose up -d
```

### 3. Verify Proxy is Running

Check health status:
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{"status":"healthy","mode":"sample","compression":"universal-patterns","timestamp":"2025-10-16T01:05:37.258Z"}
```

View metrics:
```bash
curl http://localhost:8080/metrics
```

## Sending Metrics Through the Proxy

Replace your Datadog endpoint (`https://api.datadoghq.com`) with `http://localhost:8080` in your application configuration.

### Example: Send Test Metric

```bash
curl -X POST http://localhost:8080/api/v2/series \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: your_datadog_api_key_here" \
  -d '{
    "series": [{
      "metric": "reductrai.test.metric",
      "type": 0,
      "points": [{
        "timestamp": '$(date +%s)',
        "value": 42.5
      }],
      "tags": ["test:docker"]
    }]
  }'
```

Expected response: `HTTP 202 Accepted` with `{"errors":[]}`

## Monitoring and Verification

### Check Proxy Logs

```bash
docker-compose logs -f proxy
```

Look for:
- `[Format Detection] Detected: datadog, URL: /api/v2/series`
- `[DEBUG] Stored data with ID: ...`
- `[AdaptiveSampler] New endpoint discovered: ...`

### View Proxy Statistics

```bash
curl http://localhost:8080/metrics | jq
```

Key metrics:
- `requestsProcessed`: Total requests received
- `requestsForwarded`: Total requests sent to Datadog
- `forwardRate`: Percentage of requests forwarded
- `avgLatency`: Average proxy latency
- `storage.items`: Number of stored metrics

### Check Datadog Dashboard

1. Log into your Datadog account at https://app.datadoghq.com
2. Navigate to Metrics Explorer
3. Search for your metric name (e.g., `reductrai.test.metric`)
4. Metrics should appear within 1-2 minutes

## Docker Services

### Proxy Service
- **Port**: 8080
- **Image**: `reductrai/proxy:latest` (from Docker Hub)
- **Status**: Running and healthy
- **Health Check**: `curl http://localhost:8080/health`

### Dashboard Service
- **Port**: 5173 (nginx serving React app)
- **Image**: `reductrai/dashboard:latest` (from Docker Hub)
- **Status**: ✅ Running and healthy
- **Features**: Real-time metrics visualization, system resource monitoring
- **Access**: http://localhost:5173

### AI Query Service
- **Port**: 8081
- **Image**: `reductrai/ai-query:latest` (from Docker Hub)
- **Status**: ✅ Running and healthy
- **Features**: Natural language queries against compressed metrics
- **LLM**: Configured for Ollama/Mistral integration

### Ollama Service
- **Port**: 11434
- **Image**: `ollama/ollama:latest` (from Docker Hub)
- **Status**: ✅ Running and healthy
- **Features**: Local LLM service for AI queries

## Configuration Files

### docker-compose.yml
Located at: `/Users/jessiehermosillo/Apiflow/reductrai-datadog-perf-testing/docker-compose.yml`

Key configuration:
```yaml
services:
  proxy:
    image: reductrai/proxy:latest
    ports:
      - "8080:8080"
    environment:
      - REDUCTRAI_LICENSE_KEY=${REDUCTRAI_LICENSE_KEY}
      - DATADOG_API_KEY=${DATADOG_API_KEY}
      - FORWARD_TO=https://api.datadoghq.com

  dashboard:
    image: reductrai/dashboard:latest
    ports:
      - "5173:80"

  ai-query:
    image: reductrai/ai-query:latest
    ports:
      - "8081:8081"

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
```

All images are automatically pulled from Docker Hub - no local build required!

## Performance Metrics

Based on successful test run (6 requests):
- **Forward Rate**: 100%
- **Average Latency**: 92.83ms
- **Error Rate**: 0%
- **Bytes Processed**: 1,512 bytes
- **Pattern Detection**: Automatic (Datadog format detected)

## Troubleshooting

### Proxy Not Starting

Check logs:
```bash
docker-compose logs proxy
```

Common issues:
- Missing REDUCTRAI_LICENSE_KEY in .env
- Missing DATADOG_API_KEY in .env
- Port 8080 already in use

### Metrics Not Appearing in Datadog

1. Verify API key is correct
2. Check proxy logs for forwarding confirmation
3. Ensure metrics format matches Datadog API v2 specification
4. Wait 1-2 minutes for Datadog to process metrics
5. Check for error responses from Datadog

### Images Not Found

If you see "image not found" errors, ensure you have internet connectivity to pull from Docker Hub:
```bash
docker pull reductrai/proxy:latest
docker pull reductrai/dashboard:latest
docker pull reductrai/ai-query:latest
docker pull ollama/ollama:latest
```

## Project Structure

```
reductrai-datadog-perf-testing/
├── docker-compose.yml      # Service orchestration (uses published images)
├── .env                    # Environment variables (not in git)
├── .env.example            # Example environment configuration
├── README.md              # This file
├── INTEGRATION-GUIDE.md    # Detailed integration instructions
├── CASE-STUDY-NASA-TELEMETRY.md  # NASA ISS telemetry case study
├── datadog-iss-dashboard.json    # Datadog dashboard configuration
├── import-dashboard.sh     # Script to import dashboard to Datadog
└── Dockerfile.nasa         # NASA telemetry simulator

All Docker images are pulled from Docker Hub:
- reductrai/proxy:latest
- reductrai/dashboard:latest
- reductrai/ai-query:latest
- ollama/ollama:latest
```

## Next Steps

1. ✅ Proxy running in Docker on port 8080
2. ✅ Dashboard TypeScript build fixed and running on port 5173
3. ✅ AI-Query ES module issues resolved and running on port 11434
4. ✅ All JavaScript errors in dashboard fixed
5. ✅ Inter-service communication verified
6. ✅ Datadog integration verified with test metrics
7. ⏭️ Configure your applications to use the proxy at http://localhost:8080

## Support

- **ReductrAI Issues**: Contact sales@reductrai.com
- **Datadog Support**: https://docs.datadoghq.com
- **License**: Demo license `RF-DEMO-2025` is for testing only

## Verified Working Configuration

Last tested: 2025-10-17

- ✅ Docker Compose version 3.8
- ✅ Node.js 20-alpine base image
- ✅ Datadog API v2 metrics endpoint
- ✅ 100% forward rate to Datadog
- ✅ Automatic format detection
- ✅ All health checks passing
- ✅ Zero errors on test metrics
- ✅ Dashboard UI fully functional (TypeScript build fixed)
- ✅ AI-Query service operational (ES modules fixed)
- ✅ Inter-service communication verified
- ✅ All JavaScript errors resolved
