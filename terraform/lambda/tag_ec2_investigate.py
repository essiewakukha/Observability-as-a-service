import json
import os

import boto3

autoscaling = boto3.client("autoscaling")
ec2 = boto3.client("ec2")

ASG_NAME = os.environ["ASG_NAME"]


def handler(event, context):
    """
    Triggered by EventBridge when the app ErrorCount alarm enters ALARM
    state. Tags every instance currently in the web tier's Auto Scaling
    Group with investigate=true, so an on-call engineer can immediately
    see (in the console or via a saved EC2 filter) which instances were
    live when the error spike happened.
    """
    print("Received event:", json.dumps(event))

    response = autoscaling.describe_auto_scaling_groups(
        AutoScalingGroupNames=[ASG_NAME]
    )
    instance_ids = [
        instance["InstanceId"]
        for group in response["AutoScalingGroups"]
        for instance in group["Instances"]
    ]

    if not instance_ids:
        print(f"No instances currently in ASG '{ASG_NAME}'")
        return {"status": "no_instances", "asg": ASG_NAME}

    ec2.create_tags(
        Resources=instance_ids,
        Tags=[{"Key": "investigate", "Value": "true"}],
    )

    print(f"Tagged instances for investigation: {instance_ids}")
    return {"status": "tagged", "instances": instance_ids}
