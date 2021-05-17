#!/bin/bash

SPEED_MIN=6.0
SPEED_HIGH=40.0
TEMP_MIN=75.0
TEMP_MAX=86.0
SCALAR=1.0
DELAYMAX=10

function to_int() {
  echo $1 | cut -f1 -d '.'
}

ipmitool raw 0x30 0x30 0x01 0x00

TEMP_MIN_INT=$(to_int $TEMP_MIN)

auto=255
lastspeed=0

echo $TEMP_MAX_INT
while [ 1 ]; do
T1=$(sensors | grep "Package id 0" | awk '{ print $4 }' | awk '{print ($0+0)}')
T2=$(sensors | grep "Package id 1" | awk '{ print $4 }' | awk '{print ($0+0)}')
echo $T1 deg
echo $T2 deg

if [ -z $T1 ]; then
  T1=100
fi

if [ -z $T2 ]; then
  T2=$T1
fi


#SPEED_MAX=a(x-TEMP_MIN)^2 + speed_low

A=$(python3 -c "print(($SPEED_HIGH - $SPEED_MIN) / pow($TEMP_MAX - $TEMP_MIN, $SCALAR))")

if [[ $T1 -ge $TEMP_MIN_INT ]] || [[ $T2 -ge $TEMP_MIN_INT ]]; then

   speed=$(python3 -c "print(int(min($SPEED_HIGH,$A * pow(max($T1,$T2) - $TEMP_MIN,$SCALAR)) + $SPEED_MIN))")

   if [ $speed -lt $lastspeed ]; then
      #delay_max=$(python3 -c "print(int(($DELAYMAX / ($lastspeed - $speed))))")
      delay_max=$DELAYMAX
      echo "here" $(($(date +%s) - $last_time))
      if [ $(($(date +%s) - $last_time)) -lt $delay_max ]; then
	echo "wait $delay_max"
      else
	ipmitool raw 0x30 0x30 0x02 0xFF $speed
        lastspeed=$speed
	last_time=$(date +%s)
      fi
   else
   echo Setting speed $speed
     ipmitool raw 0x30 0x30 0x02 0xFF $speed
     lastspeed=$speed
     last_time=$(date +%s)
   fi
else
  echo "Setting lowest speed"
  ipmitool raw 0x30 0x30 0x02 0xFF $(to_int $SPEED_MIN)
fi

done

ipmitool raw 0x30 0x30 0x01 0x01
