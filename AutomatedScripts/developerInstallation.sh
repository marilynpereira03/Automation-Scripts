#Each script starts with a shebang and the path to the shell that you want to use. shebang is '#!'
#!/bin/bash

GIT_CLONE_PATH=https://github.com/marilynpereira03/BPL-node.git
if sudo apt install -y jq
   then
   echo "Installed JQ successfully"
 else
   echo "Fail To install jq"
   sudo apt install -y jq
 fi
sudo apt install -y jq
function readArgumentsFromFile()
{
  fname=$1
  activeDelegates=$(jq .activeDelegates $fname)
  #Remove double quotes
  activeDelegates=$(echo $activeDelegates | sed 's/","/,/g; s/^"\|"$//g')
  blockTime=$(jq .blockTime $fname)
  blockTime=$(echo $blockTime | sed 's/","/,/g; s/^"\|"$//g')
  distance=$(jq .distance $fname)
  distance=$(echo $distance | sed 's/","/,/g; s/^"\|"$//g')
  logo=$(jq .logo $fname)
  milestones=$(jq .milestones[] $fname)
  echo "milestones In developerInstallation $milestones"
  offset=$(jq .offset $fname)
  offset=$(echo $offset | sed 's/","/,/g; s/^"\|"$//g')
  rewardType=$(jq .rewardType $fname)
  fixedLastReward=$(jq .fixedLastReward $fname)
  fixedLastReward=$(echo $fixedLastReward | sed 's/","/,/g; s/^"\|"$//g')
  blockSize=$(jq .blockSize $fname)
  blockSize=$(echo $blockSize | sed 's/","/,/g; s/^"\|"$//g')
  token=$(jq .token $fname)
}

readArgumentsFromFile /home/ubuntu/credential.json
#Basic installations
if sudo apt-get install git
 then
   #kill  a node process
   pkill -9 node
   if [ -d "BPL-node" ]
   then
     #remove BPL
     rm -rf BPL-node
   else
     echo "No BPL directoty"
   fi
   echo -e "Clonning the repository $GIT_CLONE_PATH\n"
   rm -rf BPL-node

   #Clones the repository
   if git clone $GIT_CLONE_PATH
    then
      #Change directory to BPL-node
      cd BPL-node
      #Change the git branch
      git checkout test-sidechain
      echo -e "Change directory to BPL-node\n"
      #Install it to avoid error
      echo -e "Avoiding future errors by installing libpq-dev\n"
      sudo apt-get -y update
      sudo apt-get install -y libpq-dev
      #Developer installations
      #Install essentials:
      echo -e "Install essentials:\n"
      sudo apt-get install -y curl build-essential python git
      #Install PostgreSQL (min version: 9.5.2)
      echo -r "Install PostgreSQL (min version: 9.5.2)\n"
      sudo apt-get install -y postgresql-9.5
      sudo -u postgres createuser --createdb $USER

      #Since the AWS instances do not have npm installed already thus we are installing it as further installations are done using npm
      echo -e "Since the AWS instances do not have npm installed already thus we are installing it as further installations are done using npm\n"
      sudo apt-get -y install npm
      #Install Node.js (tested with version 6.9.2, but any recent LTS release should do):
      echo -e "Install Node.js (tested with version 6.9.2, but any recent LTS release should do):\n"
      sudo apt-get install -y nodejs
      sudo npm install -g n
      sudo n 6.9.2
      #Install grunt-cli (globally):
      echo -e "#Install grunt-cli (globally):\n"
      sudo npm install grunt-cli -g
      #Install node modules:
      echo -e "#Install node modules:\n"
      npm install libpq secp256k1
      npm install
      npm install linear-solve --save
      cd scripts
      #Modify BPL-node parameters like BLocktime, reward, blocksize, offset, distance
      node modifyConfiguration.js --activedelegates $activeDelegates --blocktime $blockTime --distance $distance --fixedLastReward $fixedLastReward --logo $logo --milestones [3000000000,2000000000,1000000000] --offset $offset --rewardType $rewardType --blockSize $blockSize --token $token
      choice=$1
      if [ $choice -eq 1 ]
       then
        echo -e "Dropping database"
        dropdb sidechain
        echo -e "Creating database"
        createdb sidechain
        psql sidechain -c "alter user ubuntu with password 'sidechain123'"
      else
        echo
      fi
    fi
 fi
