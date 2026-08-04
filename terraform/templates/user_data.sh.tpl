#!/bin/bash
dnf install -y httpd amazon-cloudwatch-agent
systemctl enable httpd
systemctl start httpd
echo "<h1>${project_name} web tier - $(hostname)</h1>" > /var/www/html/index.html
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c ssm:${cw_agent_param_name} -s