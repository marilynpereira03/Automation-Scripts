#!/bin/bash

#move to BPL-node directory
cd BPL-node
cp config.sidechain.*.json config.sidechain.json
#command to start node
npm run start:sidechain > logs/bpl_node.log 2>&1 &
