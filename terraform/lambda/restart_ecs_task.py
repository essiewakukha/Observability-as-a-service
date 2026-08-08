import json
import os

import boto3

ecs = boto3.client("ecs")

CLUSTER = os.environ["ECS_CLUSTER"]
SERVICE = os.environ["ECS_SERVICE"]


def handler(event, context):
    """
    Triggered by EventBridge when the ECS CPU alarm enters ALARM state.
    Forces a new deployment of the ECS service, which causes ECS to launch
    fresh tasks and drain the old ones - a simple, safe "restart" for a
    stateless service under high CPU.
    """
    print("Received event:", json.dumps(event))

    ecs.update_service(
        cluster=CLUSTER,
        service=SERVICE,
        forceNewDeployment=True,
    )

    print(f"Forced new deployment for service '{SERVICE}' in cluster '{CLUSTER}'")
    return {"status": "restarted", "cluster": CLUSTER, "service": SERVICE}
