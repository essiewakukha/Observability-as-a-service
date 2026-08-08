
# Observability-as-a-Service: Report

## 1. Observability Design

The system monitors a three-tier application on AWS: an EC2 Auto Scaling
Group behind an Application Load Balancer (web tier), an ECS Fargate
service reached via `/api/*` on the same ALB (app tier), and an RDS MySQL
instance in private subnets (data tier).

Each tier reaches CloudWatch through a different mechanism, deliberately:

- **EC2** requires an installed **CloudWatch Agent** (pushed via user data,
  configured through SSM Parameter Store) to report CPU/memory/disk and
  Apache access/error logs, since AWS has no visibility into a self-managed
  operating system unless something is installed to report out.
- **ECS Fargate** and the **ALB** publish CPU, memory, request count, and
  HTTP status code metrics **automatically**, with zero agent required,
  since AWS operates the underlying compute. Container Insights was
  enabled on the ECS cluster for finer per-task granularity.
- **RDS** was configured with **Performance Insights** (query-level load
  analysis) and **Enhanced Monitoring** (OS-level metrics at 60-second
  granularity), both requiring an IAM role scoped specifically to the RDS
  monitoring service.

Logs are centralized in CloudWatch Logs, then streamed continuously via a
**Kinesis Firehose delivery stream into S3** for durable, long-term storage
independent of CloudWatch's 14-day retention window. An X-Ray daemon runs
as a sidecar container alongside the app tier's main container, sharing a
network namespace so the application can send trace data over localhost.

Security is layered: private subnets have no route to the internet except
outbound-only via a NAT Gateway, and every security group references
*another security group* as its allowed source (ALB → web/ECS → RDS)
rather than IP ranges, so the chain of trust holds regardless of how
instances scale or change addresses.

## 2. Example Logs Insights Query
`fields @timestamp, @message
| filter @message like /ERROR/
| stats count(*) as errorCount by bin(5m)
| sort errorCount desc`

This query, saved as `app-error-spike-detection` against the app tier's
log group, buckets matching log lines into 5-minute windows and sorts by
volume — so a genuine spike (e.g. 40+ errors in one window against a
baseline of 0-2) is immediately visible rather than buried in a scroll of
raw text. A companion query, `app-recent-error-detail`, drops the
aggregation to show the 50 most recent matching lines once a spike is
identified, so the actual error content can be read.

Tested by manually injecting synthetic `ERROR` log lines via
`aws logs put-log-events`: the query correctly surfaced a 3-count bucket
at the expected timestamp (see `screenshots/log-insight-query.png`).

## 3. Alarms and Automated Actions Tested

| Alarm | Metric watched | Threshold | Automated action |
|---|---|---|---|
| ECS CPU high | `AWS/ECS CPUUtilization` | > 80%, 2×5min | Lambda forces a new ECS deployment |
| ALB 5xx rate high | Metric math: `HTTPCode_Target_5XX_Count / RequestCount * 100` | > 5%, 2×5min | EventBridge → SNS → on-call email |
| App error count high | Custom metric from a log metric filter matching `"ERROR"` | > 10/5min | Lambda tags web tier EC2 instances `investigate=true` |

CloudWatch Alarms emit a state-change event to EventBridge automatically;
each alarm has a dedicated EventBridge rule filtering for its own alarm
name entering `ALARM` state, routed to its remediation target.

**Testing method**: rather than engineering real load or failure
conditions, each alarm was forced into `ALARM` state directly via
`aws cloudwatch set-alarm-state` — a genuine state transition that fires
the identical EventBridge event a real breach would.

**Results, all three confirmed working end-to-end:**

- **ECS CPU alarm**: Lambda invocation confirmed via CloudWatch Logs
  (`Forced new deployment for service '...' in cluster '...'`), and the
  ECS service's Deployments tab showed the new deployment actually start.
- **ALB 5xx alarm**: EventBridge invocation confirmed via the
  `AWS/Events Invocations` metric (Sum: 1), and the on-call notification
  email arrived with the full alarm payload, including the metric math
  expression and human-readable failure reason.
- **ErrorCount alarm**: Lambda log confirmed both the event received and
  the resulting action (`Tagged instances for investigation: [...]`), and
  the EC2 console confirmed the `investigate=true` tag landed on both
  instances.

Screenshots of each alarm's state-transition history, both Lambda log
entries, the SNS email, and the resulting infrastructure changes are in
`screenshots/`.

## 4. Lessons Learned

**Automatic vs. agent-based metrics is a real distinction, not a detail.**
Early in the build it wasn't obvious why EC2 needed a CloudWatch Agent
while ECS and the ALB didn't — the underlying reason (AWS operates the
compute for the latter two, so it already has the data) shaped the whole
alarm design, since the three required alarms all end up watching
automatically-published metrics, not agent-pushed ones.

**A namespace typo silently breaks an alarm without erroring.** The ECS
CPU alarm was initially configured with `namespace = "AWS/EC2"` instead
of `AWS/ECS` (introduced during manual file editing). Terraform applied it
without complaint — CloudWatch happily creates an alarm watching a metric
combination that will simply never report data. It sat in
`INSUFFICIENT_DATA` state indefinitely rather than failing loudly. This
was only caught by checking the alarm's Details panel in the console
directly, not from any error message. **Takeaway: a "healthy-looking"
alarm state (no ALARM firing) is not proof the alarm is correctly wired
— it can just as easily mean it isn't watching anything real.**

**A misconfigured target group port produced a completely silent
failure.** The app tier's target group and task definition were both set
to port 8080, but the placeholder container image actually listens on
port 80 — so the app tier's health checks had been failing since initial
deployment, invisibly, because the web tier and ALB overall appeared
healthy and nothing else surfaced the mismatch. It was only caught while
checking target group health directly during the screenshot-collection
phase, well after the alarms and automation had already been built and
tested against the same broken tier. **Takeaway: per-tier health must be
verified directly and explicitly — overall system availability is not a
reliable proxy for every tier being individually correct**, and this is
precisely the kind of gap centralized observability is supposed to catch,
which made fixing it feel like validation of the project's premise rather
than just a bug.

**Not every configured feature is actually active.** RDS was configured
to export `general` and `slowquery` logs to CloudWatch, but MySQL doesn't
generate either log unless explicitly turned on at the engine level via a
parameter group — so telling RDS to *export* a log that MySQL never
*writes* results in nothing arriving, silently. Performance Insights
(which uses a different, always-on sampling mechanism) ended up carrying
the "identify slow queries" requirement instead. **Takeaway: exporting a
log and generating a log are two separate configuration steps.**

**What would be improved with more time**: deploying a real application
container (instead of a placeholder) to generate genuine traffic, errors,
and traces — this would populate the X-Ray service map and produce
non-empty Logs Insights results without needing synthetic test data;
enabling the RDS slow-query log via a custom parameter group to fully
close the log-export gap; and moving the database password from a
Terraform variable to AWS Secrets Manager for production-appropriate
secret handling.
