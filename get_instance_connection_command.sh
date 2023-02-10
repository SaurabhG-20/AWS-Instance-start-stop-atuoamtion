#!/bin/sh
clear
echo -e "\n=======================================================\n"
echo "Script for Automated start/stop action for AWS EC2 Machine"
echo -e "\n=======================================================\n"

read -p "> Enter Instance Id ? " instance_id

while true; do
    if [[ -z "$instance_id" ]]   # If both instance name ond instance id is empty
    then
        echo -e "\nInstance Id must be provided."
        read -p "Enter Instance Id ? " instance_id
    else
        break
    fi
done

echo -e "\n> Fetching EC2 Instance State for Instance ID : $instance_id"
instance_state=$(aws ec2 describe-instance-status --instance-id $instance_id --query 'InstanceStatuses[*].InstanceState.Name' --output text)
if [[ -z "$instance_state" ]]
then
    echo -e "\n> Instance is in stopped state. Starting the instance"
    # on first execution start-instances command returns "pending" state.
    # we can run small while loop to check if instance started successfully or not
    instance_start_invoke=$(aws ec2 start-instances --instance-ids $instance_id --query 'StartingInstances[*].CurrentState.Name' --output text)
    echo -e "\n> Start instance command execution result : $instance_start_invoke"
    if [ "$instance_start_invoke" = "pending" ]
    then
        fetch_instance_start=$instance_start_invoke
        while [ "$fetch_instance_start" = "pending" ]
        do
            fetch_instance_start=$(aws ec2 start-instances --instance-ids $instance_id --query 'StartingInstances[*].CurrentState.Name' --output text)
            echo "  -->  Instance state : $fetch_instance_start"
            sleep 5
        done
        echo "  --> -------------------------------------------"
        echo "  -->  Instance state : $fetch_instance_start"
        echo -e "\n> Chekcing Instance Health status"
        fetch_instance_health="initializing"
        while [ "$fetch_instance_health" = "initializing" ]
        do
            fetch_instance_health=$(aws ec2 describe-instance-status --instance-id $instance_id --query 'InstanceStatuses[*].InstanceStatus.Status' --output text)
            echo "  -->  Instance health check : $fetch_instance_health"
            sleep 10
        done
        echo "  --> -------------------------------------------"
        echo "  --> Instance health : $fetch_instance_health"
        echo -e "\n> Getting instance connection command"
        instance_data=$(aws ec2 describe-instances --filters Name=instance-id,Values=$instance_id --query 'Reservations[*].Instances[*].{KeyName:KeyName,PublicDnsname:PublicDnsName}' --output text)
        if [[ ! -z "$instance_data" ]]
        then
            instance_key=$(echo $instance_data | head -n1 | awk '{print $1;}')".pem"
            instance_dns="ubuntu@"$(echo $instance_data | head -n1 | awk '{print $2;}')
            if [[ ! -z "$instance_key" ]]  &&  [[ ! -z "$instance_dns" ]]
            then
                command_text="ssh -i "'"'$instance_key'"'" $instance_dns"
                echo -e "\n> EC2 VM SSH Connection command is:\n\n> $command_text"
                echo -e "\n> Connecting EC2 VM $instance_id"
                echo -e "\n--------------------------------------\n"
                eval $command_text # To execute command with in shell script
            fi
        fi
    fi
elif [[ "$instance_state" = "running" ]]
then
    echo -e "\n> Instance is in running state, Do you want to stop the instance?\n"
    read -p "> Enter Option Y for yes / N for No ? " option
    # keeping while loop for oprtion selection
    while true; do
        if [[ -z "$option" ]]   # If both instance name ond instance id is empty
        then
            echo -e "\n> Option must be provided!\n"
            read -p "> Enter Option Y for yes / N for No  ? " option
        else
            break
        fi
    done
    # swicth case to handler if instance to be stop or get ssh connection command
    case $option in
      "Y")
        echo -e "\n> Selected Opion is Yes. Stopping the instance"
        instnace_stop_invoke=$(aws ec2 stop-instances --instance-ids $instance_id --query 'StoppingInstances[*].CurrentState.Name' --output text)
        echo -e "\n> Instance state : $instnace_stop_invoke"
        echo -e "\n> Instance will be stopped after sometime.\n"
		read -s -n 1 -p "Press any key to continue . . ."
        ;;
      "N")
        echo -e "\n> Selected Opion is No. Keeping the instance ON"
        echo -e "\n> Getting instance connection command"
        instance_data=$(aws ec2 describe-instances --filters Name=instance-id,Values=$instance_id --query 'Reservations[*].Instances[*].{KeyName:KeyName,PublicDnsname:PublicDnsName}' --output text)
        if [[ ! -z "$instance_data" ]]
        then
            instance_key=$(echo $instance_data | head -n1 | awk '{print $1;}')".pem"
            instance_dns="ubuntu@"$(echo $instance_data | head -n1 | awk '{print $2;}')
            if [[ ! -z "$instance_key" ]]  &&  [[ ! -z "$instance_dns" ]]
            then
                command_text="ssh -i "'"'$instance_key'"'" $instance_dns"
                echo -e "\n> EC2 VM SSH Connection command is:\n\n> $command_text"
                echo -e "\n> Connecting EC2 VM $instance_id"
                echo -e "\n--------------------------------------\n"
                eval $command_text # To execute command with in shell script
            fi
        fi
        ;;
      *)
        echo "Not a valid argument"
        echo
        ;;
    esac

fi