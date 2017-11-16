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

#read json file for access_key_id and secret access key
function readFromFile(){
 local fname=$1
  #parse access key id
  access_key_id=$(jq .access_key_id $fname)
  access_key_id=$(echo $access_key_id | sed 's/","/,/g; s/^"\|"$//g')
  #parse  secret_access_key
  secret_access_key=$(jq .secret_access_key $fname)
  secret_access_key=$(echo $secret_access_key | sed 's/","/,/g; s/^"\|"$//g')
}

#read json file [ All remaining parameters for creating instance]
function readFromJsonFile(){
    #first argument is a json file name
      filename=$1
      # parese port number
      port=$(jq .port $filename)
       #parse instance type
       instance_type=$(jq .instance_type $filename)
       #remove double qoutes from word
       instance_type=$(echo $instance_type | sed 's/","/,/g; s/^"\|"$//g')
      #parse region name
      region=$(jq .region[] $filename)

      set -f
        regionArray=(${region//,/ })
        for i in "${!regionArray[@]}"
        do
            regionArray[$i]=$(echo ${regionArray[i]} | sed 's/","/,/g; s/^"\|"$//g')
            echo ${regionArray[i]}
        done
        #end of region name

        #parse image name
        image_id=$(jq .image_id[] $filename)

        set -f
          imageIdArray=(${image_id//,/ })
          for i in "${!imageIdArray[@]}"
          do
              imageIdArray[$i]=$(echo ${imageIdArray[i]} | sed 's/","/,/g; s/^"\|"$//g')
              echo ${imageIdArray[i]}
          done
          #end of image name

          #parse count for number of instances in particular region
          count=$(jq .count[] $filename)

          set -f
            countArray=(${count//,/ })
            for i in "${!countArray[@]}"
            do
                echo ${countArray[i]}
            done
            #end of count

            #This for loop will create VPC id , security group id, Key value pair file, Subnet id in each region specified
            for i in "${!imageIdArray[@]}"
            do
              #configure region ID
              if aws configure set region ${regionArray[$i]}
                then
                echo "Configured successfully"
              else
                echo "Problem in Configuration2"
              fi
              #create VPC in region
             vpcId=$(aws ec2 describe-vpcs | grep -m 1 "VpcId" |  awk -F ":" '{print $2}' | sed 's/[",]//g' || aws ec2 create-vpc --cidr-block 10.0.0.0/24 | grep 'VpcId' | awk -F ":" '{print $2}' | sed 's/[",]//g')
             vpcId=$(echo $vpcId | sed 's/","/,/g; s/^"\|"$//g')
             #parse subnet id name
             subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpcId | grep -m 1 'SubnetId' |  awk -F ":" '{print $2}' || aws ec2 create-subnet --vpc-id $vpcId --cidr-block 100.0.0.128/25 |  grep 'SubnetId' | awk -F ":" '{print $2}' | sed 's/[",]//g')
             #remove double qoutes from word
             subnet_id=$(echo $subnet_id | sed 's/,*$//g' | sed 's/","/,/g; s/^"\|"$//g')

             security_group_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcId | grep -m 1 'GroupId' | awk -F ":" '{print $2}' | sed 's/[",]//g' || aws ec2 create-security-group --group-name MySecurityGroup3 --description "My security group" --vpc-id $vpcId | grep 'GroupId' | awk -F ":" '{print $2}' | sed 's/[",]//g')
             #remove double qoutes from word
             security_group_id=$(echo $security_group_id | sed 's/","/,/g; s/^"\|"$//g')

             #parse aws security group id name
             if [ -f blockpool_sample_${regionArray[$i]}.pem ]
              then echo
            else
                if aws ec2 create-key-pair --key-name blockpool_sample_${regionArray[$i]} --query 'KeyMaterial' --output text > blockpool_sample_${regionArray[$i]}.pem
                 then
                    echo "Key Value pair file created"
                 else
                    echo "Fail to create key value pair file"
                 fi
            fi
                 key_value_pair_name=blockpool_sample_${regionArray[$i]}

                 #create required instances
                 createInstance ${regionArray[$i]} ${imageIdArray[$i]} ${countArray[$i]} $subnet_id $security_group_id $key_value_pair_name
                 #wait for 5 second
                 sleep 2
                 #save public IP's of all created instances
                 saveIpInFile ${regionArray[$i]}
                 #set inbound rule for created IP (port number)
                 setInboundRulePort $security_group_id
           done

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

         #AWS configuration

         if aws configure set aws_secret_access_key $secret_access_key
           then
           echo "Configured successfully"
         else
           echo "Problem in Configuration1"
         fi
         if aws configure set aws_access_key_id $access_key_id
           then
           echo "Configured successfully"
         else
           echo "Problem in Configuration2"
         fi
     else
       echo "Good to proceed further"
  fi
}

#save all instances IP in text file
function saveIpInFile()
{
  ipList=$(aws ec2 describe-instances | grep PublicIpAddress | awk -F ":" '{print $2}' | sed 's/[",]//g')
  publicDnsList=$(aws ec2 describe-instances | grep PublicDnsName | awk -F ":" '{print $2}' | sed 's/[",]//g')
  echo $publicDnsList > publicDnsList_$1.txt
  echo -ne $publicDnsList >> publicDnsList.txt
  echo -ne " " >> publicDnsList.txt
  echo $ipList > ipList_$1.txt
  echo -ne $ipList >> ipList.txt
  echo -ne " " >> ipList.txt
}


#This function Will set inbound rule for port in security group
function setInboundRulePort() {
  set_security_group=$1
    if aws ec2 authorize-security-group-ingress --group-id $set_security_group --protocol tcp --port $port --cidr 0.0.0.0/0
    then
      echo "successfully added new inbound rule"
    else
      echo "Fail to add new Inbound rule"
    fi
    if aws ec2 authorize-security-group-ingress --group-id $set_security_group --protocol tcp --port 22 --cidr 0.0.0.0/0
    then
      echo "successfully added new inbound rule"
    else
      echo "Fail to add new Inbound rule"
    fi
}

#Aws instance create
function createInstance()
{
  temp_region=$1
  temp_image_id=$2
  temp_count=$3
  temp_subnet_id=$4
  temp_security_group_id=$5
  temp_key_value=$6
  echo "Do you want to create aws instance? (y)es or (n)o"
  read userInputForCreatingInstance
   if [ $userInputForCreatingInstance == "y" ] || [ $userInputForCreatingInstance == "Y" ]
     then
       if [ $temp_count -gt 20 ]
       then
         echo "You cannot create more than 20 instance or Increase limit on No. of instances per region from AWS EC2 console"
       else
          if aws ec2 run-instances --image-id $temp_image_id --count $temp_count --instance-type $instance_type --key-name $temp_key_value --security-group-ids $temp_security_group_id --subnet-id $temp_subnet_id --region $temp_region
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
#install aws cli
installAwsCli
readFromFile $1
#configure aws IAM user to aws cli
configureAwsAccount
#read all required parameter from json file
readFromJsonFile $1
 # createOneIPAndPublicDNSFile
