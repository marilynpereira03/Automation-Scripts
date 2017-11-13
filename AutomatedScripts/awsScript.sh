#! /bin/bash
#https://linuxacademy.com/howtoguides/posts/show/topic/14209-automating-aws-with-python-and-boto3
#install Python 3.6.2
#aws-cli installation
#ubutu unzip package installation

function installAwsCli()
{
  if aws configure get region # This will check whether aws cli is installed or not
  then
      echo "aws-cli is already installed"
  else
          if sudo apt-get install python3 #python installation
          then
             if python3 --version
             then
               echo "Python Installed successfully"
                 if curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" #aws-cli code
                  then
                       if sudo apt-get install -y unzip #install unxip package
                       then
                          if unzip awscli-bundle.zip #unzip aws-cli bundle
                          then
                            if sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws #install aws-cli
                            then echo "AWS Cli is installed Sucessfully"
                            else
                            echo "Unable to install Scripts"
                            fi
                          else
                          echo "Unable to unzip awscli-bundle.zip"
                          fi
                      else
                      echo "Unable to install unzip package"
                      fi
                  else
                  echo "Unable to download aws-cli code"
                  fi
             else
             echo "Python is not installed"
             fi
          else
            echo "Failed to installed python"
          fi
  fi
}

#if number of argument passed is less than 1
function numberOfArguments(){
  echo  $#;
  if [ $# -eq 1 ]
  then
      echo
    else
      echo "Please provide json file as argument which contents
       (region, aws secret key, access key id, instance type, count
        for number of instances,security group id, subnet id , image id  ))"
      exit
    fi
}

#read json file
function readFromJsonFile(){
     #first argument is a json file name
      filename=$1
      #parse region name
      region=$(jq .region $filename)
      #remove double qoutes from word
      region=$(echo $region | sed 's/","/,/g; s/^"\|"$//g')
      #parse aws instance image id name
      image_id=$(jq .image_id $filename)
      #remove double qoutes from word
      image_id=$(echo $image_id | sed 's/","/,/g; s/^"\|"$//g')
      #parse aws security group id name
      security_group_id=$(jq .security_group_id $filename)
      #remove double qoutes from word
      security_group_id=$(echo $security_group_id | sed 's/","/,/g; s/^"\|"$//g')
      #parse subnet id name
      subnet_id=$(jq .subnet_id $filename)
      #remove double qoutes from word
      subnet_id=$(echo $subnet_id | sed 's/","/,/g; s/^"\|"$//g')
      #Number of aws instance
      count=$(jq .count $filename)
      port=$(jq .port $filename)
      #parse aws security group id name
      key_value_pair_name=$(jq .key_value_pair_name $filename)
      #remove double qoutes from word
      key_value_pair_name=$(echo $key_value_pair_name | sed 's/","/,/g; s/^"\|"$//g')
      #parse instance type
      instance_type=$(jq .instance_type $filename)
      #remove double qoutes from word
      instance_type=$(echo $instance_type | sed 's/","/,/g; s/^"\|"$//g')
      #parse access key id
      access_key_id=$(jq .access_key_id $filename)
      #remove double qoutes from word
      access_key_id=$(echo $access_key_id | sed 's/","/,/g; s/^"\|"$//g')
      #parse  secret_access_key
      secret_access_key=$(jq .secret_access_key $filename)
      #remove double qoutes from word
      secret_access_key=$(echo $secret_access_key | sed 's/","/,/g; s/^"\|"$//g')
}

#Configuration Part
function configureAwsAccount()
{
  echo "If you are doing this process first time then this is a mandatory process.
        OR Do you want to reconfigure aws cli.
        (y)es or (n)o"
  read userInput

  if [ $userInput == "y" ] || [ $userInput == "Y" ]
   then
         echo "1.Open the IAM console.
         2.In the navigation panel of the console, chooseUsers.
         3.Choose your IAM user name (not the check box).
         4.Choose the Security credentials tab and then choose Create access key.
         5.To see the new access key, choose Show. Your credentials will look something like this:
         •Access key ID: AKIAIOSFODNN7EXAMPLE
         •Secret access key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
         6.To download the key pair, choose Download .csv file. Store the keys in a secure location"

         # #AWS configuration
         if aws configure
           then
           echo "Configured successfully"
         else
           echo "Problem in Configuration"
         fi
     else
       echo "Good to proceed further"
  fi
}

#save all instances IP in text file
#aws autoscaling update-auto-scaling-group --auto-scaling-group-name launch-wizard-5 --max-size 15

function saveIpInFile()
{
  ipList=$(aws ec2 describe-instances | grep PublicIpAddress | awk -F ":" '{print $2}' | sed 's/[",]//g')
  publicDnsList=$(aws ec2 describe-instances | grep PublicDnsName | awk -F ":" '{print $2}' | sed 's/[",]//g')
  echo $publicDnsList > publicDnsList.txt
  echo $ipList > ipList.txt
}

#This function Will set inbound rule
function setInboundRulePort() {
    if aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port $port --cidr 0.0.0.0/0
    then
      echo "successfully added new inbound rule"
    else
      echo "Fail to add new Inbound rule"
    fi
}

#Aws instance create
function createInstance()
{
  echo "Do you want to create aws instance? (y)es or (n)o"
  read userInputForCreatingInstance
   if [ $userInputForCreatingInstance == "y" ] || [ $userInputForCreatingInstance == "Y" ]
     then
       if [ $count -gt 20 ]
       then
         echo "You cannot create more than 20 instance or Increase limit on No. of instances per region from AWS EC2 console"
       else
          if aws ec2 run-instances --image-id $image_id --count $count --instance-type $instance_type --key-name $key_value_pair_name --security-group-ids $security_group_id --subnet-id $subnet_id --region $region
          then
            echo "successfully created $count instances"
          else
            echo "Fail to create instances"
          fi
        fi
    fi
}

#All functions are executed sequentially
#check numberOfArguments are correct or not
numberOfArguments $1
#read all required parameter from json file
readFromJsonFile $1
#install aws cli
installAwsCli
#configure aws IAM user to aws cli
configureAwsAccount
#create required instances
createInstance
#wait for 5 second
# sleep 5
#save public IP's of all created instances
saveIpInFile
#set inbound rule for created IP (port number)
setInboundRulePort
