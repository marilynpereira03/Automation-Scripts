#!/bin/bash

#move to BPL-node directory
cd BPL-node
cp config.BPL-testnet.*.json config.testnet.json
#command to start node
npm run start:bpltestnet > logs/bpl_node.log 2>&1 &
