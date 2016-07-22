#!/bin/bash

echo '#deployer Start' >> ~/.ssh/authorized_keys
curl https://github.com/deployer-colours-minsk.keys >> ~/.ssh/authorized_keys
echo '#deployer End' >> ~/.ssh/authorized_keys
echo '#mezinster Start' >> ~/.ssh/authorized_keys
curl https://github.com/mezinster.keys >> ~/.ssh/authorized_keys
echo '#mezinster End' >> ~/.ssh/authorized_keys
echo '#akuryan Start' >> ~/.ssh/authorized_keys
curl https://github.com/akuryan.keys >> ~/.ssh/authorized_keys
echo '#akuryan End' >> ~/.ssh/authorized_keys