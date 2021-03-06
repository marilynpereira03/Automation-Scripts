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

#read json file for accessKeyId and secret access key
function readFromFile(){
 local fname=$1
 #parse key pair file name
 keyPairName=$(jq .keyPairName $fname)
 keyPairName=$(echo $keyPairName | sed 's/","/,/g; s/^"\|"$//g')
  #parse access key id
  accessKeyId=$(jq .accessKeyId $fname)
  accessKeyId=$(echo $accessKeyId | sed 's/","/,/g; s/^"\|"$//g')
  #parse  secretAccessKey
  secretAccessKey=$(jq .secretAccessKey $fname)
  secretAccessKey=$(echo $secretAccessKey | sed 's/","/,/g; s/^"\|"$//g')
}

#read json file [ All remaining parameters for creating instance]
function readFromJsonFile(){
    #first argument is a json file name
      filename=$1
      # parese port number
      port=$(jq .port $filename)


      #parse region name
      region=$(jq ".region | .[] | .region" $filename)

      set -f
        regionArray=(${region})
        for i in "${!regionArray[@]}"
        do
            regionArray[$i]=$(echo ${regionArray[$i]} | sed 's/","/,/g; s/^"\|"$//g')
        done
        #end of region name
        #parse image name
        imageId=$(jq ".region | .[] | .imageId" $filename)

        set -f
          imageIdArray=(${imageId})
          for i in "${!imageIdArray[@]}"
          do
              imageIdArray[$i]=$(echo ${imageIdArray[i]} | sed 's/","/,/g; s/^"\|"$//g')
          done
          #end of image name

          #parse count for number of instances in particular region
          count=$(jq ".region | .[] | .count" $filename)
          set -f
            countArray=(${count})
            for i in "${!countArray[@]}"
            do
              countArray[$i]=$(echo ${countArray[$i]} | sed 's/","/,/g; s/^"\|"$//g')
            done
            #end of count

            instanceType=$(jq ".region | .[] | .instanceType" $filename)
            set -f
              instanceTypeArray=(${instanceType})
              for i in "${!instanceTypeArray[@]}"
              do
                #remove double qoutes from word
                instanceTypeArray[$i]=$(echo ${instanceTypeArray[$i]} | sed 's/","/,/g; s/^"\|"$//g')
              done


            #This for loop will create VPC id , security group id, Key value pair file, Subnet id in each region specified
            for i in "${!imageIdArray[@]}"
            do
              #configure region ID aws configure set region us-east-1

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

             security_group_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcId | grep -m 1 'GroupId' | awk -F ":" '{print $2}' | sed 's/[",]//g' || aws ec2 create-security-group --group-name MySecurityGroup3 --description "My security group" --vpc-id $vpcId | grep 'GroupId' | awk -F ":" '{print $2}' | sed 's/[",]//g')
             #remove double qoutes from word
             security_group_id=$(echo $security_group_id | sed 's/","/,/g; s/^"\|"$//g')

             #parse aws security group id name
             importPublicKey $publicKey
             key_value_pair_name=$keyPairName

          avalabilityZone=$(aws ec2 describe-availability-zones | grep ZoneName | awk -F ":" '{print $2}' | sed 's/[",]//g' |  wc -l)
          remainder=$(( ${countArray[$i]} % $avalabilityZone ))
          distribute=$(( ${countArray[$i]}/$avalabilityZone ))
          ListAZ=$(aws ec2 describe-availability-zones | grep ZoneName | awk -F ":" '{print $2}' | sed 's/[",]//g')
          arrayListAZ=($ListAZ)
            for j in "${!arrayListAZ[@]}"
                  do
              	    if [[ $j -eq 0 ]]
                     then
                      		distribute=$(( $distribute + $remainder ))
                     fi
                     if [[ $j -eq 1 ]]
                       then
                      		distribute=$(( $distribute - $remainder ))
                     fi
                          arrayListAZ[$j]=$(echo ${arrayListAZ[$j]} | sed 's/","/,/g; s/^"\|"$//g')
                          subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpcId,Name="availability-zone",Values=${arrayListAZ[$j]} | grep -m 1 'SubnetId' |  awk -F ":" '{print $2}' || aws ec2 create-subnet --vpc-id $vpcId --availability-zone ${arrayListAZ[$j]} --cidr-block 100.0.0.128/25 |  grep 'SubnetId' | awk -F ":" '{print $2}' | sed 's/[",]//g')
                          #remove double qoutes from word
                          subnet_id=$(echo $subnet_id | sed 's/,*$//g' | sed 's/","/,/g; s/^"\|"$//g')
                          createInstance ${regionArray[$i]} ${imageIdArray[$i]} $distribute $subnet_id $security_group_id $key_value_pair_name ${arrayListAZ[$j]} ${instanceTypeArray[$i]}
                  done
                 #create required instances
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

         if aws configure set aws_secretAccessKey $secretAccessKey
           then
           echo "Configured successfully"
         else
           echo "Problem in Configuration1"
         fi
         if aws configure set aws_accessKeyId $accessKeyId
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
  ipList=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$vpcId" "Name=key-name,Values=$key_value_pair_name" | grep PublicIpAddress | awk -F ":" '{print $2}' | sed 's/[",]//g')
  publicDnsList=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$vpcId" "Name=key-name,Values=$key_value_pair_name" | grep PublicDnsName | awk -F ":" '{print $2}' | sed 's/[",]//g')
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
  temp_imageId=$2
  temp_count=$3
  temp_subnet_id=$4
  temp_security_group_id=$5
  temp_key_value=$6
  temp_availability_zone=$7
  temp_instanse_type=$8
  echo "Do you want to create aws instance? (y)es or (n)o"
  read userInputForCreatingInstance
   if [ $userInputForCreatingInstance == "y" ] || [ $userInputForCreatingInstance == "Y" ]
     then
       if [ $temp_count -gt 20 ]
       then
         echo "You cannot create more than 20 instance or Increase limit on No. of instances per region from AWS EC2 console"
       else
            if aws ec2 run-instances --image-id $temp_imageId --count $temp_count --instance-type $temp_instanse_type --key-name $temp_key_value --security-group-ids $temp_security_group_id --subnet-id $temp_subnet_id --region $temp_region --placement AvailabilityZone=$temp_availability_zone
          then
            echo "successfully created $temp_count instances"
          else
            echo "Fail to create instances"
          fi
        fi
    fi
}
function importPublicKey()
{
  if aws ec2 import-key-pair --key-name $keyPairName --public-key-material $1
    then
      echo "Sucesss"
    else
     echo "Fail"
  fi
}

function createKeyPair()
{
  extension=.pem
  extension1=.pub
  keyPairNamePrivate=$keyPairName$extension
  keyPairPubName=$keyPairName$extension1
  if [[ -f $keyPairName.pem ]]
      then
      echo "File Exist private key"
  else
      if openssl genrsa -out $keyPairNamePrivate 2048
      then
        echo
      fi
  fi
}

function extractPublicKey()
{
  if [[ -f $keyPairPubName ]]
      then
      echo "File Exist public key"
  else
        echo "In else"
        if openssl rsa -in $keyPairNamePrivate -pubout > $keyPairPubName
        then
          echo "successfully created public file"
        else
          echo "Fail to create"
        fi
   fi
   publicKey=$(cat $keyPairPubName)
   prefix="-----BEGIN PUBLIC KEY-----"
   suffix="-----END PUBLIC KEY-----"
   publicKey=$(echo "$publicKey" | sed -e "s/^$prefix//" -e "s/$suffix$//")
   publicKey=$(echo $publicKey | sed 's/ //g')
}
#All functions are executed sequentially
#check numberOfArguments are correct or not
numberOfArguments $1
#install aws cli
installAwsCli
#read only AWS cli configuration paramwter
readFromFile $1
#configure aws IAM user to aws cli
configureAwsAccount
createKeyPair
extractPublicKey
#read all required parameter from json file
readFromJsonFile $1
 # createOneIPAndPublicDNSFile
