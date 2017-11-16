#! bin/bash

#remove
rm -rf ipList.txt
rm -rf publicDnsList.txt
chmod +x *

# Aws Installation
##Install AWS cli
##Configure AWS cli with IAM user
##Create AWS instances
##Set inbound rule for port Number
#
if bash awsScript.sh credential.json
   then
    echo "Instances are created successfully"
  else
    echo "Fail to create instances"
fi

#Read credential.json
function readFromJsonFile(){
    #first argument is a json file name
      filename=$1
      #parse region name
      region=$(jq .region[] $filename)
      activeDelegates=$(jq .activeDelegates $filename)
      tokenShortName=$(jq .tokenShortName $filename)
      set -f
        regionArray=(${region//,/ })
        for i in "${!regionArray[@]}"
        do
            regionArray[$i]=$(echo ${regionArray[i]} | sed 's/","/,/g; s/^"\|"$//g')
            echo ${regionArray[i]}
        done
        #Calculate total number of instances
        total_instance=0
        count=$(jq .count[] $filename)
        countArray=(${count//,/ })
        for i in "${!countArray[@]}"
        do
          total_instance=$(( $total_instance + ${countArray[$i]} ))
        done
        echo "total_instance $total_instance"
}

#Path where you clone your code
readFromJsonFile credential.json
path=/home/avinash/Automation-Scripts/AutomatedScripts
#need to provide this information first time
pathForConfigFile=$path/BPL-node/private
pathForGenesisBlockFile=$path/BPL-node/private/genesisBlock.private.json
pathToCreateConfigFile=$path/BPL-node/tasks/
devloperInstallationSteps=$path/developerInstallation.sh
startNodeScriptPath=$path/mainnet_start.sh
ipListFilePath=$path/ipList.txt
publicDNSFilePath=$path/publicDnsList.txt
rm -rf BPL-node
echo "step 1"
if bash developerInstallation.sh 0
 then
    if cp createGenesisBlockSample.js BPL-node/tasks/
      then
         echo "Copied"
      else
          echo "Not copied"
    fi
  else
    echo "Failed to clone BPL-node"
  fi
#create Config and genesis files
if cd && cd $pathToCreateConfigFile && node createGenesisBlockSample.js -p 4001 -d "sidechain" -u "ubuntu" -c "sidechain123" -n $activeDelegates --networkName "sidechain" -a $total_instance -i $ipListFilePath -k $publicDNSFilePath --tokenShortName $tokenShortName && cd && cd $path
 then
    echo "Files are generated successfully"
    for i in "${!regionArray[@]}"
      do
        ipListFilePath=$path/ipList_${regionArray[$i]}.txt
        publicDNSFilePath=$path/publicDnsList_${regionArray[$i]}.txt
        pathOfPemFile=$path/blockpool_sample_${regionArray[$i]}.pem
        #Launch network
        if bash automatedScript.sh $ipListFilePath $pathOfPemFile $pathForConfigFile $pathForGenesisBlockFile $devloperInstallationSteps $startNodeScriptPath
         then
            echo "Network is up"
         else
           echo "Problem in script"
        fi
      done
   else
  echo "Fail to create config files";
fi
