var moment = require('moment');
var fs = require('fs');
var path = require('path');
var bpljs = require('bpljs');
var crypto = require('crypto');
var bip39 = require('bip39');
var ByteBuffer = require('bytebuffer');
var bignum = require('../helpers/bignum.js');
var ed = require('../helpers/ed.js');
var networks = require('../networks.json');
var linear = require('linear-solve');
//Change made by avinash
//required packages
var program = require('commander');
var packageJson = require('../package.json');
//Change made by avinash
//added to get different config files
var seed_peers = [];

/**************************************/
//temporarily pre-configured: database, user, password
var config = {
    "port": 4000,
    "address": "127.0.0.1",
    "version": "0.3.0",
    "fileLogLevel": "info",
    "logFileName": "logs/bpl.log",
    "consoleLogLevel": "debug",
    "trustProxy": false,
    "db": {
        "host": "localhost",
        "port": 5432,
        "database": "bpl_devnet",
        "user": "ubuntu",
        "password": "blockpool123",
        "poolSize": 20,
        "poolIdleTimeout": 30000,
        "reapIntervalMillis": 1000,
        "logEvents": [
            "error"
        ]
    },
    "api": {
        "mount": true,
        "access": {
            "whiteList": []
        },
        "options": {
            "limits": {
                "max": 0,
                "delayMs": 0,
                "delayAfter": 0,
                "windowMs": 60000
            }
        }
    },
    "peers": {
        "minimumNetworkReach": 1,
        "list": [

        ], //Since each IP was getting copied in the generated files, however we want only a single IP and that too of the current instance.
        "blackList": [],
        "options": {
            "limits": {
                "max": 0,
                "delayMs": 0,
                "delayAfter": 0,
                "windowMs": 60000
            },
            "maxUpdatePeers": 20,
            "timeout": 5000
        }
    },
    "forging": {
        "coldstart": 6,
        "force": true,
        "secret": [],
        "access": {
            "whiteList": [
                "127.0.0.1"
            ]
        }
    },
    "loading": {
        "verifyOnLoading": false,
        "loadPerIteration": 5000
    },
    "ssl": {
        "enabled": false,
        "options": {
            "port": 443,
            "address": "0.0.0.0",
            "key": "./ssl/bpl.key",
            "cert": "./ssl/bpl.crt"
        }
    },
    "network": "BPL-testnet"
};
//Argument accepted from user
//Configuration changes made by Avinash
// -p 4000 -d "sidechain" -u "avinash" -c "India@1234" -n 20 -net "BPL-sidechain"
var numberOfDelegate;
var awsCount;

program
    .version(packageJson.version)
    .option('-p, --port <port>', 'Node port number')
    .option('-d, --database <database>', 'Database name')
    .option('-u, --user <user>', 'Database username')
    .option('-c, --password <password>', 'Database password')
    .option('-n, --noOfDelegate <noOfDelegate>', 'No of delegate')
    .option('-m, --networkName <networkName>', 'Network name')
    .option('-a, --awsCount <awsCount>', 'AWS instances count')
    .option('-i, --ipPath <ipPath>', 'File which contents all ip list')
    .option('-k, --publicDnsPath <publicDnsPath>', 'fi;e which contants all public dns list')
    .parse(process.argv)

var ipFilePath;
var publicDnsPath;
if (program.port) {
    config.port = program.port;
}
if(program.ipPath) {
 ipFilePath = program.ipPath;
}
if(program.publicDnsPath) {
 publicDnsPath = program.publicDnsPath;
}
if (program.database) {
    config.db.database = program.database;
}
if (program.user) {
    config.db.user = program.user;
}
if (program.password) {
    config.db.password = program.password;
}
if (program.noOfDelegate) {
    noOfDelegate = program.noOfDelegate;
}
if (program.database) {
    config.network = program.networkName;
}
if (program.awsCount) {
    awsCount = program.awsCount;
}

var ipList = fs.readFileSync(ipFilePath);
ipList = ipList.toString();
ipList = ipList.replace(/\n$/, '');
var ipListArray = ipList.split(" ");

var publicDnsList = fs.readFileSync(publicDnsPath);
//console.log("Ip list " + publicDnsList);
publicDnsList = publicDnsList.toString();
publicDnsList = publicDnsList.replace(/\n$/, '');
publicDnsList = publicDnsList.split(" ");
var uniquePublicDnsList = [];
for (var i = 0; i < publicDnsList.length; i = i + 3) {
    uniquePublicDnsList.push(publicDnsList[i]);
}

for (var i = 0; i < uniquePublicDnsList.length; i++) {
    let data = {};
    data.ip = ipListArray[i];
    data.publicDNS = uniquePublicDnsList[i];
    data.port = 4001;
    seed_peers.push(data);
}
//Logic for deviding passphrases accross aws instances
console.log("numberOfDelegate", noOfDelegate, typeof(noOfDelegate));
console.log("awsCount", awsCount, typeof(awsCount));
let x = Math.ceil(noOfDelegate / awsCount);
console.log("x is" + x);
let y = Math.floor(noOfDelegate / awsCount);
console.log(x, y)
var coefficient = [];
coefficient.push([1, 1]);
coefficient.push([x, y]);
console.log(coefficient);
var rightSide = [];
awsCount = parseInt(awsCount);
noOfDelegate = parseInt(noOfDelegate);

rightSide[0] = awsCount;
rightSide[1] = noOfDelegate;
console.log(rightSide);
var solve = linear.solve(coefficient, rightSide);
console.log(solve);
solve[0] = Math.ceil(solve[0]);
solve[1] = Math.floor(solve[1]);
console.log(solve);
//Divide secret


//sets the networkVersion
//setting the network version inside node_modules/bpljs/lib/transactions/crypto.js
bpljs.crypto.setNetworkVersion(networks[config.network].pubKeyHash);
//console.log(networks[config.network]);
sign = function(block, keypair) {
    var hash = getHash(block);
    return ed.sign(hash, keypair).toString('hex');
};


getId = function(block) {
    var hash = crypto.createHash('sha256').update(getBytes(block)).digest();
    var temp = new Buffer(8);
    for (var i = 0; i < 8; i++) {
        temp[i] = hash[7 - i];
    }

    var id = bignum.fromBuffer(temp).toString();
    return id;
};

getHash = function(block) {
    return crypto.createHash('sha256').update(getBytes(block)).digest();
};


getBytes = function(block) {
    var size = 4 + 4 + 4 + 8 + 4 + 4 + 8 + 8 + 4 + 4 + 4 + 32 + 32 + 66;
    var b, i;

    try {
        var bb = new ByteBuffer(size, true);
        bb.writeInt(block.version);
        bb.writeInt(block.timestamp);
        bb.writeInt(block.height);

        if (block.previousBlock) {
            var pb = bignum(block.previousBlock).toBuffer({
                size: '8'
            });

            for (i = 0; i < 8; i++) {
                bb.writeByte(pb[i]);
            }
        } else {
            for (i = 0; i < 8; i++) {
                bb.writeByte(0);
            }
        }

        bb.writeInt(block.numberOfTransactions);
        bb.writeLong(block.totalAmount);
        bb.writeLong(block.totalFee);
        bb.writeLong(block.reward);

        bb.writeInt(block.payloadLength);

        var payloadHashBuffer = new Buffer(block.payloadHash, 'hex');
        for (i = 0; i < payloadHashBuffer.length; i++) {
            bb.writeByte(payloadHashBuffer[i]);
        }

        var generatorPublicKeyBuffer = new Buffer(block.generatorPublicKey, 'hex');
        for (i = 0; i < generatorPublicKeyBuffer.length; i++) {
            bb.writeByte(generatorPublicKeyBuffer[i]);
        }

        if (block.blockSignature) {
            var blockSignatureBuffer = new Buffer(block.blockSignature, 'hex');
            for (i = 0; i < blockSignatureBuffer.length; i++) {
                bb.writeByte(blockSignatureBuffer[i]);
            }
        }

        bb.flip();
        b = bb.toBuffer();
    } catch (e) {
        throw e;
    }

    return b;
};

create = function(data) {
    var transactions = data.transactions.sort(function compare(a, b) {
        if (a.type < b.type) {
            return -1;
        }
        if (a.type > b.type) {
            return 1;
        }
        if (a.amount < b.amount) {
            return -1;
        }
        if (a.amount > b.amount) {
            return 1;
        }
        return 0;
    });

    var nextHeight = 1;

    var reward = 0,
        totalFee = 0,
        totalAmount = 0,
        size = 0;

    var blockTransactions = [];
    var payloadHash = crypto.createHash('sha256');

    for (var i = 0; i < transactions.length; i++) {
        var transaction = transactions[i];
        var bytes = bpljs.crypto.getBytes(transaction);

        size += bytes.length;

        totalFee += transaction.fee;
        totalAmount += transaction.amount;

        blockTransactions.push(transaction);
        payloadHash.update(bytes);
    }

    var block = {
        version: 0,
        totalAmount: totalAmount,
        totalFee: totalFee,
        reward: reward,
        payloadHash: payloadHash.digest().toString('hex'),
        timestamp: data.timestamp,
        numberOfTransactions: blockTransactions.length,
        payloadLength: size,
        previousBlock: null,
        generatorPublicKey: data.keypair.publicKey.toString('hex'),
        transactions: blockTransactions,
        height: 1
    };

    block.id = getId(block);


    try {
        block.blockSignature = sign(block, data.keypair);
    } catch (e) {
        throw e;
    }

    return block;
}

var delegates = [];
var transactions = [];

var genesis = {
    passphrase: bip39.generateMnemonic(),
    balance: 2500000000000000 //25 million tokens
}

var premine = {
    passphrase: bip39.generateMnemonic()
}

premine.publicKey = bpljs.crypto.getKeys(premine.passphrase).publicKey;
premine.address = bpljs.crypto.getAddress(premine.publicKey, networks[config.network].pubKeyHash);

genesis.publicKey = bpljs.crypto.getKeys(genesis.passphrase).publicKey;
genesis.address = bpljs.crypto.getAddress(genesis.publicKey, networks[config.network].pubKeyHash);
genesis.wif = bpljs.crypto.getKeys(genesis.passphrase).toWIF();

var premineTx = bpljs.transaction.createTransaction(genesis.address, genesis.balance, null, premine.passphrase)

premineTx.fee = 0;
premineTx.timestamp = 0;
premineTx.senderId = premine.address;
premineTx.signature = bpljs.crypto.sign(premineTx, bpljs.crypto.getKeys(genesis.passphrase));
premineTx.id = bpljs.crypto.getId(premineTx);

transactions.push(premineTx);

for (var i = 1; i < noOfDelegate + 1; i++) { //201 delegates
    var delegate = {
        'passphrase': bip39.generateMnemonic(),
        'username': "genesis_" + i
    };

    var createDelegateTx = bpljs.delegate.createDelegate(delegate.passphrase, delegate.username);
    createDelegateTx.fee = 0;
    createDelegateTx.timestamp = 0;
    createDelegateTx.senderId = genesis.address;
    createDelegateTx.signature = bpljs.crypto.sign(createDelegateTx, bpljs.crypto.getKeys(delegate.passphrase));
    createDelegateTx.id = bpljs.crypto.getId(createDelegateTx);


    delegate.publicKey = createDelegateTx.senderPublicKey;
    delegate.address = bpljs.crypto.getAddress(createDelegateTx.senderPublicKey, networks[config.network].pubKeyHash);

    transactions.push(createDelegateTx);

    delegates.push(delegate);
}

var genesisBlock = create({
    keypair: bpljs.crypto.getKeys(genesis.passphrase),
    transactions: transactions,
    timestamp: 0
});
//replace "for(var i=0;i<201;i++)" "for(var i=0;i<numberOfDelegate;i++)"  createGenesisBlockSample.js
// for(var i=0;i<noOfDelegate;i++){ //201 delegates
// 	config.forging.secret.push(delegates[i].passphrase);
// }
var delegate_array = [];
/*Splits all delegates accross all seed_peers*/
for (var i = 0; i < noOfDelegate; i++) { //201 delegates
    var seed_index = i % noOfDelegate;
    console.log(i);
    // if(!delegate_array[seed_index]){
    //   console.log(seed_index);
    //
    //   delegate_array[seed_index] = "";
    // }
    delegate_array.push(delegates[i].passphrase);
    console.log(delegate_array[seed_index]);
}

seed_peers.forEach(function(ilist) {
    config.peers.list.push({
        "ip": ilist.ip,
        "port": ilist.port
    });
});


/*
Generates the different config file for all peers that we have added in seed_peers.
*/
var count_solve = 0;
var countForAwsSecretKey = 0;
seed_peers.forEach(function(peer) {
    if (count_solve < solve[0]) {
        console.log("In IF/////////////////////count solve",count_solve);
        for (let k = 0; k < x; k++) {
            let temp = delegate_array[count_solve * x + k];
            console.log("Temp",temp);
            config.forging.secret.push(temp);
        }
        console.log("If Count" + config.forging.secret.length);

        console.log("*********************************************************");
        console.log(config.forging.secret.length + "config.forging.secret");
        count_solve++;
    } else {
        if (countForAwsSecretKey < solve[1]) {
            for (let k = 0; k < y; k++) {
                console.log("In Else/////////////////////countForAwsSecretKey",countForAwsSecretKey);
let index =(solve[0] * x) + (countForAwsSecretKey * y) + k;
                config.forging.secret.push(delegate_array[index]);


            }
            console.log("Remaining",config.forging.secret);
            console.log("else"+config.forging.secret.length + "config.forging.secret");

            countForAwsSecretKey++;


        }
    }
    //config.forging.secret = peer.secret;
    config.nethash = genesisBlock.payloadHash; //set the nethash in config file
    //to customize the address and peers list field in config.json file , we have included the below piece of code
    config.address = peer.publicDNS; // setting up Public DNS(IPv4) of AWS in the generated config file, to avoid manually entering the same.
    fs.writeFile("../private/config." + config.network + "." + peer.ip + ".json", JSON.stringify(config, null, 2));
    for (let k = 0; k < x; k++) {
        console.log("In POP");
        config.forging.secret.pop();
          }
});


fs.writeFile("../private/genesisBlock.private.json", JSON.stringify(genesisBlock, null, 2));
fs.writeFile("../private/config.private.json", JSON.stringify(config, null, 2));
fs.writeFile("../private/delegatesPassphrases.private.json", JSON.stringify(delegates, null, 2));
fs.writeFile("../private/genesisPassphrase.private.json", JSON.stringify(genesis, null, 2));
