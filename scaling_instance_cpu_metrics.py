# Python script that will identify the instances with the lowest CPU utilization and terminate them, while ensuring that at least 4 instances are always available. The script should use the AWS SDK for Python (Boto3) to interact with the EC2 API.

#You have access to the following AWS resources:

#An IAM role with the necessary permissions to terminate EC2 instances

import boto3
import sys

# Function to get the average CPU utilization of instances
def get_cpu_utilization(ec2_client, instance_ids):
    cloudwatch_client = boto3.client('cloudwatch')
    metrics = {}
    for instance_id in instance_ids:
        response = cloudwatch_client.get_metric_statistics(
            Namespace='AWS/EC2',
            MetricName='CPUUtilization',
            Dimensions=[
                {
                    'Name': 'InstanceId',
                    'Value': instance_id
                },
            ],
            StartTime=datetime.utcnow() - timedelta(minutes=60),
            EndTime=datetime.utcnow(),
            Period=300,
            Statistics=['Average'],
        )
        datapoints = response['Datapoints']
        # Take the average of all data points if available
        if datapoints:
            avg_cpu = sum([point['Average'] for point in datapoints]) / len(datapoints)
            metrics[instance_id] = avg_cpu
        else:
            metrics[instance_id] = 0.0  # Assuming 0% if no data is available
    return metrics

# Function to terminate instances with lowest CPU utilization
def terminate_lowest_cpu_instances(instance_ids_file, ec2_client):
    with open(instance_ids_file, 'r') as file:
        instance_ids = [line.strip() for line in file.readlines()]

    # Ensure at least 4 instances are present
    if len(instance_ids) <= 4:
        print("Cannot terminate instances. Only 4 or fewer instances are available.")
        return
    
    # Get CPU utilization metrics
    cpu_utilization = get_cpu_utilization(ec2_client, instance_ids)
    
    # Sort instances by CPU utilization in ascending order
    sorted_instances = sorted(cpu_utilization, key=cpu_utilization.get)
    
    # Calculate the number of instances that can be safely terminated
    instances_to_terminate = len(instance_ids) - 4
    
    # Terminate the instances with the lowest CPU utilization
    for i in range(instances_to_terminate):
        instance_id = sorted_instances[i]
        print(f"Terminating instance: {instance_id} with CPU utilization: {cpu_utilization[instance_id]}%")
        ec2_client.terminate_instances(InstanceIds=[instance_id])

# Main execution
if __name__ == "__main__":
    ec2_client = boto3.client('ec2')
    instance_ids_file = 'instance_ids.txt'
    terminate_lowest_cpu_instances(instance_ids_file, ec2_client)
