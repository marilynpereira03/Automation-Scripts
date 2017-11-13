#! /bin/bash
#Constants String needed
configFileFirstPart="/config.BPL-testnet."
configFileLastPart=".json"
#We will place these files on remote server and then installed it on script folder
#download file using curl command
#Now these is manual steps to give path of developerInstallation and start node file path
# devloperInstallationSteps=/home/marilyn/Documents/BLOCKPOOL/MARILYN/Sidechain/AutomatedScripts/developerInstallation.sh
# startNodeScriptPath=/home/marilyn/Documents/BLOCKPOOL/MARILYN/Sidechain/AutomatedScripts/mainnet_start.sh
#Aws instance are ubuntu so user is ubuntu
  address1="ubuntu@"

#install jq command
if sudo apt install -y jq
then
echo "jq installed Successfully"
   if [ $# -eq 6 ] #check if enough command line arguments are passed
   then
      ipFilePath=$1
      pemFilePath=$2
      configFilePath=$3
      genesisFilePath=$4
      devloperInstallationSteps=$5
      startNodeScriptPath=$6
      echo "$ipFilePath and $pemFilePath "
      #Copy file content into variable
      chmod 400 $pemFilePath
      ipList="$(<$ipFilePath)"
      #Stored IP list in Array
      arr=($ipList)
      for i in ${!arr[*]};
      do
        #String concatenation to form ubuntu@IPAddress
        address=$address1${arr[$i]}
        ssh -oStrictHostKeyChecking=no -i $pemFilePath $address "bash -s" -- < $devloperInstallationSteps 1
        scp -oStrictHostKeyChecking=no -i $pemFilePath $configFilePath$configFileFirstPart${arr[$i]}$configFileLastPart $address:/home/ubuntu/BPL-node/
        scp -oStrictHostKeyChecking=no -i $pemFilePath $genesisFilePath $address:/home/ubuntu/BPL-node/genesisBlock.testnet.json
        #install developer instalation on AWS instance
        #Run a node
        ssh -oStrictHostKeyChecking=no -i $pemFilePath $address "bash -s" -- < $startNodeScriptPath
        # ssh -oStrictHostKeyChecking=no -i $pemFilePath $address

      done
   else
     echo -e "Invalid Number of argument. \n First argument should be a path of a file containing All IP's
     2.Path of pem file
     3. Config File Path
     4. GenesisFile path "
   fi
else
echo "Failed to installed "
fi
