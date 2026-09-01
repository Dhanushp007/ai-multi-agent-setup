---
name: performance-profiling
description: Use this skill when asked to profile an application, investigate slow queries or endpoints, diagnose high CPU or memory usage, or optimize performance bottlenecks — automatically selected for "why is this slow", "profile this code", or "reduce latency".
license: MIT
---

# Performance Profiling

## When to Use This Skill

- An endpoint, function, or query is unacceptably slow
- Memory usage grows over time (suspected leak)
- CPU usage is unexpectedly high under load
- A performance regression was introduced by a recent change
- Pre-release performance baseline needs to be established

---

## Process

### 1. Establish Baselines & Goals

Before optimizing anything, measure first:

| Metric | Typical Threshold | Critical Threshold |
|--------|------------------|--------------------|
| HTTP p95 latency | < 200 ms | > 1 s |
| HTTP p99 latency | < 500 ms | > 2 s |
| CPU (sustained) | < 70% | > 90% |
| Memory growth/hour | 0% | > 5% |
| DB query time | < 50 ms | > 500 ms |
| Bundle size (JS) | < 250 KB gzipped | > 1 MB gzipped |

Define a **target** before starting: "reduce p95 latency from 800 ms to < 200 ms".

### 2. Identify the Bottleneck Layer

Work top-down — don't optimize blindly:

```
Request → Load Balancer → App Server → Cache → Database → External API
```

Quick triage:
```bash
# Time a single request end-to-end
curl -w "\n%{time_total}s\n" -s -o /dev/null https://api.example.com/slow-endpoint

# Check if the DB is the bottleneck
# Enable slow query log (MySQL)
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 0.1;

# PostgreSQL: show running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND (now() - query_start) > interval '100ms';
```

### 3. Profile by Stack

#### Node.js

```bash
# CPU profile (built-in)
node --prof app.js
node --prof-process isolate-*.log > processed.txt

# Heap snapshot
node --inspect app.js
# Open chrome://inspect → take heap snapshot

# Clinic.js (recommended)
npx clinic doctor -- node app.js
npx clinic flame -- node app.js    # flamegraph
npx clinic bubbleprof -- node app.js  # async bottlenecks

# Autocannon load test
npx autocannon -c 100 -d 30 http://localhost:3000/api/slow
```

Key flamegraph patterns to look for:
- Wide flat bars → CPU hotspot
- Deep recursive stacks → infinite loop risk
- `(idle)` dominates → I/O bound, look at async calls

#### Python

```bash
# Built-in cProfile
python -m cProfile -s cumtime app.py

# Line-by-line profiling
pip install line_profiler
kernprof -l -v script.py

# Memory profiling
pip install memory-profiler
python -m memory_profiler script.py

# py-spy (production-safe, no code changes)
pip install py-spy
py-spy top --pid <PID>
py-spy record -o profile.svg --pid <PID>

# pytest-benchmark
pytest --benchmark-only tests/perf/
```

#### .NET

```bash
# dotnet-trace
dotnet tool install -g dotnet-trace
dotnet-trace collect --process-id <PID> --duration 00:00:30
dotnet-trace report trace.nettrace

# dotnet-counters (live metrics)
dotnet tool install -g dotnet-counters
dotnet-counters monitor --process-id <PID> System.Runtime

# BenchmarkDotNet
# Add [Benchmark] attribute to methods, run:
dotnet run -c Release --project Benchmarks/
```

### 4. Database Query Analysis

```sql
-- PostgreSQL: EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE customer_id = 42 AND status = 'pending';

-- MySQL: EXPLAIN FORMAT=JSON
EXPLAIN FORMAT=JSON SELECT ...;

-- Look for:
-- Seq Scan on large table → needs index
-- Nested Loop with large row estimates → index or query rewrite
-- Sort without index → add index on ORDER BY columns
-- Hash Join spilling to disk → work_mem too low
```

#### N+1 Detection Pattern

```typescript
// BAD: N+1 — 1 query for orders + N queries for each user
const orders = await Order.findAll();
for (const order of orders) {
  order.user = await User.findByPk(order.userId); // N queries!
}

// GOOD: eager load with JOIN
const orders = await Order.findAll({ include: [{ model: User }] });
```

### 5. Memory Leak Investigation

```bash
# Node.js: watch heap over time
node --max-old-space-size=512 app.js &
watch -n5 'kill -USR1 <PID>'  # trigger GC, observe if memory stays high

# Python: tracemalloc
import tracemalloc
tracemalloc.start()
# ... run code ...
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')
for stat in top_stats[:10]:
    print(stat)
```

Common leak patterns:
- Event listeners not removed (`emitter.off()` missing)
- Closures capturing large objects
- Global caches with no eviction policy (use LRU with size limit)
- Long-lived DB connections not returned to pool

### 6. Optimization Patterns

#### Caching
```typescript
// In-process LRU cache
import { LRUCache } from 'lru-cache';
const cache = new LRUCache<string, User>({ max: 500, ttl: 1000 * 60 * 5 });

async function getUser(id: string): Promise<User> {
  return cache.get(id) ?? cache.set(id, await db.users.findUnique({ where: { id } }), { returnValue: true })!;
}
```

#### Pagination (avoid full table scans)
```sql
-- Keyset pagination (fast at any offset)
SELECT * FROM items WHERE id > :last_id ORDER BY id LIMIT 20;
-- NOT: SELECT * FROM items LIMIT 20 OFFSET 10000; (slow for large offsets)
```

#### Batch operations
```typescript
// Batch DB writes
await db.users.createMany({ data: usersToCreate });

// Batch external API calls
const results = await Promise.all(ids.map(id => fetchUser(id)));
```

### 7. Verify Improvement

Re-run the same benchmark after each change:
```bash
# Before
npx autocannon -c 50 -d 20 http://localhost:3000/api/endpoint

# Apply fix

# After — compare results
npx autocannon -c 50 -d 20 http://localhost:3000/api/endpoint
```

Document: before p95, after p95, % improvement.

---

## Tools & Resources

- **Node.js**: `clinic`, `autocannon`, `0x`, `node --prof`
- **Python**: `py-spy`, `line_profiler`, `memory_profiler`, `pytest-benchmark`
- **.NET**: `dotnet-trace`, `dotnet-counters`, `BenchmarkDotNet`
- **Database**: `EXPLAIN ANALYZE` (PostgreSQL), `EXPLAIN FORMAT=JSON` (MySQL), `pgBadger`
- **Load testing**: `k6` (https://k6.io), `locust` (Python), `autocannon` (Node)
- **APM**: Datadog, New Relic, OpenTelemetry

---

## Checklist

- [ ] Baseline metrics captured (latency p50/p95/p99, CPU, memory)
- [ ] Performance target defined (measurable, time-boxed)
- [ ] Bottleneck layer identified (app, DB, cache, network, I/O)
- [ ] Stack-appropriate profiler run and flamegraph/report collected
- [ ] DB slow queries identified and EXPLAIN ANALYZE reviewed
- [ ] N+1 query patterns found and resolved
- [ ] Memory growth/leak investigated if applicable
- [ ] Optimization applied (cache, index, batch, pagination)
- [ ] Post-optimization benchmark run and compared to baseline
- [ ] Improvement documented (before/after numbers)
- [ ] No regressions in correctness (tests still pass)
