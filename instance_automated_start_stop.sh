#!/bin/bash
echo "   -------------------------------- "
echo "   Automation Script for instance start/stop"
echo "   -------------------------------- "
#read -p "   Enter Instance Id : " instance_id
echo "   "
instance_id="<Enter your Instance Id>"
if [ -z "$instance_id" ]
then
    echo "   Exiting from script. Please enter instance Id."
    exit -1
else
    echo "  --> Fethcing Instance $instance_id status."
fi
instance_state=$(aws ec2 describe-instance-status --instance-id $instance_id --query 'InstanceStatuses[*].InstanceState.Name' --output text)
size=${#instance_state}
if [ -z "$instance_state" ]
then
    echo "  --> Instance $instance_id is not in running state. Starting the instance"
    # on first execution start-instances command returns "pending" state.
    # we can run small while loop to check if instance started successfully or not
    instance_start_invoke=$(aws ec2 start-instances --instance-ids $instance_id --query 'StartingInstances[*].CurrentState.Name' --output text)
    echo "  --> start instance command execution result : $instance_start_invoke"
    if [ "$instance_start_invoke" = "pending" ]
    then
        fetch_instance_start=$instance_start_invoke
        while [ "$fetch_instance_start" = "pending" ]
        do
            fetch_instance_start=$(aws ec2 start-instances --instance-ids $instance_id --query 'StartingInstances[*].CurrentState.Name' --output text)
            echo "  --> Instance state : $fetch_instance_start"
            sleep 5
        done
        echo "  --> -------------------------------------------"
        echo "  --> Instance state : $fetch_instance_start"
        echo "  --> Chekcing Instance Health status"
        fetch_instance_health="initializing"
        while [ "$fetch_instance_health" = "initializing" ]
        do
            fetch_instance_health=$(aws ec2 describe-instance-status --instance-id $instance_id --query 'InstanceStatuses[*].InstanceStatus.Status' --output text)
            echo "  --> Instance health check : $fetch_instance_health"
            sleep 10
        done
        echo "  --> -------------------------------------------"
        echo "  --> Instance health : $fetch_instance_health"
        echo "Fetching Instance Ip and DNS"
        instance_ip=$(aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)
		instance_dns=$(aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].PublicDnsName" --output=text)
        echo "  --> Launching Instance $instance_id with instance's public IP $instance_ip"
        file_path="<Enter File path of pem key>"
        echo "Launch Instance using command copy that : \n ssh -i "'$file_path'" ubuntu@$instance_ip"
		echo "Launch Instance using command copy that : \n ssh -i "'$file_path'" ubuntu@$instance_dns"
		read -s -n 1 -p "Press any key to continue . . ."
    fi
else
    if [ "$instance_state" = "running" ]
    then
        instnace_stop_invoke=$(aws ec2 stop-instances --instance-ids $instance_id --query 'StoppingInstances[*].CurrentState.Name' --output text)
        echo "  --> Instance state : $instnace_stop_invoke"
        echo "  --> Instance will be stopped after sometime."
		read -s -n 1 -p "Press any key to continue . . ."
    fi
fi