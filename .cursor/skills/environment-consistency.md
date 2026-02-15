---
description: >
  Ensures development, staging, and production environments are consistent to prevent
  "works on my machine" issues. Validates configuration, dependencies, environment
  variables, and deployment processes across all environments. Essential for reliable
  deployments and reducing production surprises.
  Use when: (1) setting up new environments, (2) debugging environment-specific issues,
  (3) preparing for deployment, (4) configuring CI/CD pipelines, (5) onboarding team members.
globs: ["**/package.json", "**/requirements.txt", "**/Dockerfile", "**/.env*", "**/docker-compose*", "**/.github/**", "**/vercel.json", "**/netlify.toml"]
alwaysApply: false
---

# Environment Consistency

## Purpose

Eliminate "works on my machine" problems by ensuring all environments (development, staging, production) behave identically. Catch configuration drift before it causes production issues.

## Activation

This skill activates when you mention:
- "environment", "env", "dev vs prod", "staging"
- "deployment", "deploy", "CI/CD", "pipeline"
- "works on my machine", "environment specific", "config drift"
- "docker", "container", "dockerfile"
- "package.json", "dependencies", "versions"

Also activates when working on:
- Environment configuration files
- Deployment scripts
- CI/CD pipeline setup
- Docker containers

## The Consistency Stack

### 1. Language & Runtime Versions

```json
// package.json - Lock Node.js version
{
  "name": "my-app",
  "engines": {
    "node": ">=18.18.0 <19.0.0",
    "npm": ">=9.0.0"
  },
  "volta": {
    "node": "18.18.2",
    "npm": "9.8.1"
  }
}
```

```yaml
# .github/workflows/ci.yml - Match in CI
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18.18.2]  # Exact version from package.json
```

```dockerfile
# Dockerfile - Pin exact versions
FROM node:18.18.2-alpine

# Not this - can drift over time:
# FROM node:18-alpine
```

### 2. Dependency Locking

```bash
# Always commit lock files
git add package-lock.json
git add yarn.lock
git add pnpm-lock.yaml

# Python equivalent
git add requirements.lock
git add poetry.lock
git add Pipfile.lock
```

```json
// .npmrc - Ensure consistent installs
save-exact=true
engine-strict=true
```

### 3. Environment Variable Templates

```bash
# .env.example - Template with all required vars (commit this)
NODE_ENV=development
DATABASE_URL=postgresql://username:password@localhost:5432/dbname
API_KEY=your-api-key-here
SECRET_KEY=generate-with-openssl-rand-base64-32
REDIS_URL=redis://localhost:6379
STRIPE_PUBLIC_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...

# Feature flags
FEATURE_BETA_DASHBOARD=false
FEATURE_ADVANCED_SEARCH=true

# External service URLs
WEBHOOK_URL=https://yourapp.com/webhooks
```

```typescript
// Environment validation script
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'staging', 'production']),
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(10),
  SECRET_KEY: z.string().min(32),
  REDIS_URL: z.string().url(),
  
  // Feature flags with defaults
  FEATURE_BETA_DASHBOARD: z.string().transform(val => val === 'true').default('false'),
  FEATURE_ADVANCED_SEARCH: z.string().transform(val => val === 'true').default('true'),
  
  // Optional in development, required in production
  WEBHOOK_URL: z.string().url().optional().refine(
    (val) => process.env.NODE_ENV === 'development' || val !== undefined,
    'WEBHOOK_URL required in production'
  ),
});

// Validate on startup
export const env = envSchema.parse(process.env);

// Runtime environment check
export function validateEnvironment(): EnvironmentReport {
  const issues: string[] = [];
  
  // Check database connectivity
  try {
    await db.raw('SELECT 1');
  } catch (error) {
    issues.push(`Database unreachable: ${error.message}`);
  }
  
  // Check external services
  try {
    const response = await fetch(`${env.API_BASE_URL}/health`);
    if (!response.ok) {
      issues.push(`API service unhealthy: ${response.status}`);
    }
  } catch (error) {
    issues.push(`API service unreachable: ${error.message}`);
  }
  
  // Check file system permissions
  try {
    await fs.access('./uploads', fs.constants.W_OK);
  } catch (error) {
    issues.push('Upload directory not writable');
  }
  
  return {
    healthy: issues.length === 0,
    issues,
    timestamp: new Date().toISOString()
  };
}
```

## Container Strategy

### Multi-Stage Dockerfile

```dockerfile
# Dockerfile - Consistent across all environments
FROM node:18.18.2-alpine AS base
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache git python3 make g++

# Copy package files
COPY package.json package-lock.json ./

# Development stage
FROM base AS development
ENV NODE_ENV=development
RUN npm ci --include=dev
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Build stage
FROM base AS build
ENV NODE_ENV=production
RUN npm ci --only=production && npm cache clean --force
COPY . .
RUN npm run build

# Production stage
FROM node:18.18.2-alpine AS production
WORKDIR /app
ENV NODE_ENV=production

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Copy built application
COPY --from=build --chown=nextjs:nodejs /app ./

USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

### Docker Compose for Local Development

```yaml
# docker-compose.yml - Mirrors production services locally
version: '3.8'

services:
  app:
    build:
      context: .
      target: development
    volumes:
      - .:/app
      - /app/node_modules  # Persist node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    env_file:
      - .env.local
    depends_on:
      - db
      - redis

  db:
    image: postgres:15.4  # Pin exact version
    environment:
      POSTGRES_DB: myapp_development
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7.2.1-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## Configuration Management

### Environment-Specific Config

```typescript
// config/environments.ts
interface AppConfig {
  database: {
    host: string;
    port: number;
    ssl: boolean;
  };
  cache: {
    ttl: number;
    maxSize: number;
  };
  features: {
    betaDashboard: boolean;
    advancedSearch: boolean;
  };
  monitoring: {
    sampleRate: number;
    enableTracing: boolean;
  };
}

const baseConfig: Partial<AppConfig> = {
  cache: {
    maxSize: 1000,
  },
};

const environments: Record<string, AppConfig> = {
  development: {
    ...baseConfig,
    database: {
      host: 'localhost',
      port: 5432,
      ssl: false,
    },
    cache: {
      ...baseConfig.cache!,
      ttl: 60, // Short TTL for development
    },
    features: {
      betaDashboard: true,  // Enable all features in dev
      advancedSearch: true,
    },
    monitoring: {
      sampleRate: 1.0,     // 100% sampling in dev
      enableTracing: true,
    },
  },

  staging: {
    ...baseConfig,
    database: {
      host: env.DATABASE_HOST,
      port: 5432,
      ssl: true,
    },
    cache: {
      ...baseConfig.cache!,
      ttl: 300, // 5 minutes
    },
    features: {
      betaDashboard: true,  // Test new features in staging
      advancedSearch: true,
    },
    monitoring: {
      sampleRate: 0.1,     // 10% sampling
      enableTracing: true,
    },
  },

  production: {
    ...baseConfig,
    database: {
      host: env.DATABASE_HOST,
      port: 5432,
      ssl: true,
    },
    cache: {
      ...baseConfig.cache!,
      ttl: 3600, // 1 hour
    },
    features: {
      betaDashboard: env.FEATURE_BETA_DASHBOARD,
      advancedSearch: env.FEATURE_ADVANCED_SEARCH,
    },
    monitoring: {
      sampleRate: 0.01,    // 1% sampling in prod
      enableTracing: false,
    },
  },
};

export const config = environments[env.NODE_ENV] || environments.development;
```

## Deployment Parity Checks

### Pre-Deploy Validation

```bash
#!/bin/bash
# scripts/validate-environment.sh

set -e

echo "🔍 Validating environment consistency..."

# Check Node.js version
REQUIRED_NODE=$(node -p "require('./package.json').engines.node")
CURRENT_NODE=$(node --version)
echo "Node.js: Required $REQUIRED_NODE, Current $CURRENT_NODE"

# Check environment variables
echo "🔑 Checking environment variables..."
node -e "
const { env } = require('./config/environment');
console.log('✅ All required environment variables present');
"

# Check database connectivity
echo "🗄️ Checking database connection..."
node -e "
const db = require('./lib/database');
db.raw('SELECT 1').then(() => {
  console.log('✅ Database connection successful');
  process.exit(0);
}).catch(error => {
  console.error('❌ Database connection failed:', error.message);
  process.exit(1);
});
"

# Check external service health
echo "🌐 Checking external services..."
node -e "
const fetch = require('node-fetch');
Promise.all([
  fetch(process.env.API_BASE_URL + '/health'),
  fetch(process.env.STRIPE_BASE_URL + '/v1/ping')
]).then(responses => {
  const allHealthy = responses.every(r => r.ok);
  if (allHealthy) {
    console.log('✅ All external services healthy');
  } else {
    console.error('❌ Some external services are unhealthy');
    process.exit(1);
  }
}).catch(error => {
  console.error('❌ Failed to check external services:', error.message);
  process.exit(1);
});
"

echo "✅ Environment validation complete!"
```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15.4  # Same version as production
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version-file: '.nvmrc'  # Use same version as local
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci  # Use exact versions from package-lock.json
      
      - name: Validate environment
        run: ./scripts/validate-environment.sh
        env:
          NODE_ENV: staging
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
      
      - name: Run tests
        run: npm test
        env:
          NODE_ENV: test

  deploy-staging:
    needs: test
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
      - name: Deploy to staging
        run: |
          echo "Deploying to staging..."
          # Use same container image that will go to production
          
      - name: Smoke test staging
        run: |
          # Test critical paths after deployment
          curl -f ${{ secrets.STAGING_URL }}/health
          curl -f ${{ secrets.STAGING_URL }}/api/users/me

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Deploy to production
        run: |
          echo "Deploying same image to production..."
          
      - name: Smoke test production
        run: |
          curl -f ${{ secrets.PRODUCTION_URL }}/health
```

## Database Migration Strategy

```typescript
// migrations/utils.ts
export async function safelyApplyMigration(
  migration: () => Promise<void>,
  rollback: () => Promise<void>
) {
  const backupTable = `backup_${Date.now()}`;
  
  try {
    // Create backup (in case rollback needed)
    await db.raw(`CREATE TABLE ${backupTable} AS SELECT * FROM users`);
    
    // Apply migration
    await migration();
    
    // Test migration worked
    await db.raw('SELECT COUNT(*) FROM users');
    
    console.log('✅ Migration applied successfully');
    
    // Clean up backup after success
    await db.raw(`DROP TABLE ${backupTable}`);
    
  } catch (error) {
    console.error('❌ Migration failed, rolling back:', error);
    
    try {
      await rollback();
      console.log('✅ Rollback completed');
    } catch (rollbackError) {
      console.error('❌ Rollback also failed:', rollbackError);
      console.log(`Backup table ${backupTable} preserved for manual recovery`);
      throw rollbackError;
    }
    
    throw error;
  }
}

// Example migration
export async function up() {
  await safelyApplyMigration(
    async () => {
      await db.schema.alterTable('users', table => {
        table.string('new_column').defaultTo('default_value');
      });
    },
    async () => {
      await db.schema.alterTable('users', table => {
        table.dropColumn('new_column');
      });
    }
  );
}
```

## Monitoring Environment Drift

```typescript
// monitoring/environment-drift.ts
interface EnvironmentSnapshot {
  timestamp: string;
  nodeVersion: string;
  dependencies: Record<string, string>;
  envVars: string[];  // Keys only, not values
  dbSchema: string;
  serviceHealth: Record<string, boolean>;
}

export class EnvironmentMonitor {
  async takeSnapshot(): Promise<EnvironmentSnapshot> {
    const packageJson = require('../package.json');
    
    return {
      timestamp: new Date().toISOString(),
      nodeVersion: process.version,
      dependencies: packageJson.dependencies,
      envVars: Object.keys(process.env).sort(),
      dbSchema: await this.getSchemaHash(),
      serviceHealth: await this.checkServiceHealth(),
    };
  }
  
  async compareEnvironments(
    dev: EnvironmentSnapshot,
    prod: EnvironmentSnapshot
  ): Promise<DriftReport> {
    const issues: string[] = [];
    
    // Version drift
    if (dev.nodeVersion !== prod.nodeVersion) {
      issues.push(`Node version mismatch: dev=${dev.nodeVersion}, prod=${prod.nodeVersion}`);
    }
    
    // Dependency drift
    for (const [pkg, devVersion] of Object.entries(dev.dependencies)) {
      const prodVersion = prod.dependencies[pkg];
      if (prodVersion && devVersion !== prodVersion) {
        issues.push(`${pkg} version drift: dev=${devVersion}, prod=${prodVersion}`);
      }
    }
    
    // Missing environment variables
    const devEnvVars = new Set(dev.envVars);
    const prodEnvVars = new Set(prod.envVars);
    
    const missingInProd = dev.envVars.filter(v => !prodEnvVars.has(v));
    const missingInDev = prod.envVars.filter(v => !devEnvVars.has(v));
    
    if (missingInProd.length > 0) {
      issues.push(`Environment variables missing in prod: ${missingInProd.join(', ')}`);
    }
    
    if (missingInDev.length > 0) {
      issues.push(`Environment variables missing in dev: ${missingInDev.join(', ')}`);
    }
    
    // Schema drift
    if (dev.dbSchema !== prod.dbSchema) {
      issues.push('Database schema mismatch between environments');
    }
    
    return {
      healthy: issues.length === 0,
      issues,
      timestamp: new Date().toISOString(),
    };
  }
  
  private async getSchemaHash(): Promise<string> {
    // Generate hash of database schema structure
    const tables = await db.raw(`
      SELECT table_name, column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public'
      ORDER BY table_name, ordinal_position
    `);
    
    const schemaString = JSON.stringify(tables.rows);
    return crypto.createHash('md5').update(schemaString).digest('hex');
  }
  
  private async checkServiceHealth(): Promise<Record<string, boolean>> {
    const services = {
      database: () => db.raw('SELECT 1'),
      redis: () => redis.ping(),
      api: () => fetch(`${env.API_BASE_URL}/health`),
    };
    
    const results: Record<string, boolean> = {};
    
    for (const [name, check] of Object.entries(services)) {
      try {
        await check();
        results[name] = true;
      } catch (error) {
        results[name] = false;
      }
    }
    
    return results;
  }
}

// Cron job to check for drift
const monitor = new EnvironmentMonitor();

setInterval(async () => {
  if (env.NODE_ENV === 'production') {
    const snapshot = await monitor.takeSnapshot();
    
    // Compare with last known dev snapshot
    const devSnapshot = await redis.get('dev:environment:snapshot');
    if (devSnapshot) {
      const driftReport = await monitor.compareEnvironments(
        JSON.parse(devSnapshot),
        snapshot
      );
      
      if (!driftReport.healthy) {
        console.warn('Environment drift detected:', driftReport.issues);
        
        // Alert the team
        await sendAlert({
          title: 'Environment Drift Detected',
          message: driftReport.issues.join('\n'),
          severity: 'warning',
        });
      }
    }
  }
}, 24 * 60 * 60 * 1000); // Daily check
```

## Quick Start Template

### Setup Script

```bash
#!/bin/bash
# scripts/setup-environment.sh

echo "🚀 Setting up development environment..."

# Check system requirements
if ! command -v node &> /dev/null; then
  echo "❌ Node.js not found. Please install Node.js 18+"
  exit 1
fi

# Install specific Node version if using volta/nvm
if [ -f .nvmrc ]; then
  if command -v nvm &> /dev/null; then
    nvm use
  elif command -v volta &> /dev/null; then
    volta install node@$(cat .nvmrc)
  fi
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm ci

# Copy environment template
if [ ! -f .env.local ]; then
  echo "🔧 Creating .env.local from template..."
  cp .env.example .env.local
  echo "⚠️  Please update .env.local with your actual values"
fi

# Set up database
echo "🗄️ Setting up database..."
npm run db:setup

# Run environment validation
echo "✅ Validating environment..."
npm run validate:env

echo "🎉 Environment setup complete!"
echo "👉 Run 'npm run dev' to start development server"
```

## Checklist

Before deploying to a new environment:

- [ ] **Runtime versions pinned** - Node.js, Python, etc. exact versions specified
- [ ] **Dependencies locked** - package-lock.json/yarn.lock committed and up-to-date
- [ ] **Environment template** - .env.example with all required variables documented
- [ ] **Environment validation** - Startup checks for required config and connectivity
- [ ] **Container consistency** - Same Dockerfile across all environments
- [ ] **Database migrations** - Safe migration strategy with rollback capability
- [ ] **Configuration management** - Environment-specific config without duplication
- [ ] **Health checks** - Endpoints for monitoring and load balancer health checks
- [ ] **Smoke tests** - Automated tests that run after deployment
- [ ] **Drift monitoring** - Automated checks for environment consistency over time

## Integration

### With Security Gate
- Environment consistency is part of security review
- Configuration drift can introduce vulnerabilities
- Secrets management validated across environments

### With Human Approval
- Environment changes require review
- Production deployments need approval
- Configuration modifications need sign-off

### With Documentation
- Environment setup instructions documented
- Configuration differences explained
- Deployment procedures documented for each environment