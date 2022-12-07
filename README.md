# cryto-generator
Use fabric-ca to generate, extend certificates, like crypto-gen


## generate org's cryto material
```
# create orderer org1 with domain org1.example.com and 2 orderer nodes
./network.sh createOrg -o org1 -t orderer -d org1.example.com -c 2
```

## extend org's node cryto material
```
# add one node cryto material, like crypto-gen extend
 ./network.sh extendOrg -o org1 -t orderer -d org1.example.com -c 3
```

## delete org's cryto material
```
./network.sh cleanOrg -o org1 -d org1.example.com
```

## delete all materials
```
./network.sh cleanAll
```

