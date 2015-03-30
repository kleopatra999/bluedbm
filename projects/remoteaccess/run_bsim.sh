#!/bin/bash

rm -rf bsimall
mkdir bsimall

cd bsimall


cp -r ../bluesim bluesim1
cp -r ../bluesim bluesim2
cp -r ../bluesim bluesim3

cd bluesim1
./bin/bsim | tee ../bsim1.txt & bsim1=$!
BDBM_ID=5 ./bin/bsim_exe | tee ../bsim_exe1.txt & bsimexe1=$1
cd ..


cd bluesim2
./bin/bsim | tee ../bsim2.txt & bsim2=$!
BDBM_ID=6 ./bin/bsim_exe | tee ../bsim_exe2 & bsimexe2=$1
cd ..

cd bluesim3
./bin/bsim | tee ../bsim3.txt & bsim3=$!
BDBM_ID=7 ./bin/bsim_exe | tee ../bsim_exe3 & bsimexe3=$1
cd ..

wait $bsimexe1 $bsimexe2 $bsimexe3
kill $bsim1 $bsim2 $bsim3
