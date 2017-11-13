#! bin/bash
chmod +x *
if bash awsScript.sh credential.json
   then
    echo "Instances are created successfully"
  else
    echo "Fail to create instances"
fi
path=/home/marilyn/Documents/BLOCKPOOL/MARILYN/Sidechain/Automation-Scripts/AutomatedScripts/
pathOfPemFile=/home/marilyn/Downloads/harbinger_instance.pem

#need to provide this information first time
pathForConfigFile=$path/BPL-node/private
pathForGenesisBlockFile=$path/BPL-node/private/genesisBlock.private.json
pathToCreateConfigFile=$path//BPL-node/tasks/
ipListFilePath=$path/ipList.txt
publicDNSFilePath=$path/publicDnsList.txt
devloperInstallationSteps=$path/developerInstallation.sh
startNodeScriptPath=$path/mainnet_start.sh

rm -rf BPL-node

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
if cd && cd $pathToCreateConfigFile && node createGenesisBlockSample.js -p 4001 -d "sidechain" -u "ubuntu" -c "blockpool123" -n 31 --networkName "BPL-testnet" -a 3 -i $ipListFilePath -k $publicDNSFilePath && cd && cd $path
 then
    echo "Files are generated successfully"
     if bash automatedScript.sh $ipListFilePath $pathOfPemFile $pathForConfigFile $pathForGenesisBlockFile $devloperInstallationSteps $startNodeScriptPath
       then
          echo "Network is up"
       else
         echo "Problem in script"
    fi
 else
  echo "Fail to create config files";
fi
