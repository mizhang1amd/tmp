#!/bin/bash
#
# Script for removing 11_E32 Vout offset
#
# Version: v01
# Author : Nick Campion
# Date: 06/26/2024
#
#

#Dict of OAM slot and corresponding OAM selector payload for I2C command
declare -A OAM_no=( [0]="0x01" [1]="0x02" [2]="0x04" [3]="0x08" [4]="0x10" [5]="0x20" [6]="0x40" [7]="0x80")
OAM_PRSNT=`i2cget -f -y 3 0x56 0x63`

for i in {0..7}; do
  
  if [[ $(( $((1<<$i)) & $(($OAM_PRSNT)) )) -eq 0 ]]; then
    
    echo "============================================== OAM $i (${OAM_no[$i]}) =="
    i2cset -f -y 2 0x70 "${OAM_no[$i]}"
    
    vr_addr=( "0x43" )
      
    for addr in "${vr_addr[@]}"; do
      if [[ $1 == "no_offset" ]]; then
		echo "0" > /var/lib/power-sequence/enable_vrupdate
		
		# Set customer rev to FFFF for tracking
		# Set vout offset to 0
		i2cset -f -y 2 $addr 0x00 0x00 bp
        i2cset -f -y 2 $addr 0xb1 0x02 0xff 0xff i
		i2cset -f -y 2 $addr 0x00 0x01 bp
		i2cset -f -y 2 $addr 0xb1 0x02 0xff 0xff i
		i2cset -f -y 2 $addr 0x23 0x0000 wp
		
		# save to device
		i2cset -f -y 2 $addr 0x15 cp
        echo "set 11_E32 Vout to no offset"
      elif [[ $1 == "default" ]]; then
		echo "1" > /var/lib/power-sequence/enable_vrupdate
		
		# Set customer rev to FFFF for tracking
		# Set vout offset to default
		i2cset -f -y 2 $addr 0x00 0x00 bp
        i2cset -f -y 2 $addr 0xb1 0x02 0x01 0x00 i
		i2cset -f -y 2 $addr 0x00 0x01 bp
        i2cset -f -y 2 $addr 0xb1 0x02 0x01 0x00 i
		i2cset -f -y 2 $addr 0x23 0x0009 wp
		
		# save to device
		i2cset -f -y 2 $addr 0x15 cp
        echo "set 11_E32 Vout to default offset"
      elif [[ $1 == "check" ]]; then
        # check 11_E32
		i2cset -f -y 2 $addr 0x00 0x01 bp
        offset_r1=`i2cget -f -y 2 $addr 0x023 wp`
		
		if [[ $offset_r1 == "0x0000" ]]; then
			echo "11_E32 Vout reads as no offset"
		elif [[ $offset_r1 == "0x0009" ]]; then
			echo "11_E32 Vout reads as default offset"
		fi
        
      else
        echo "Please enter"
        echo "no_offset to set 11_E32 Vout to no offset"
        echo "default to set 11_E32 Vout offset to default"
        echo "check to read current 11_E32 Vout offset"
        exit -1
      fi
    done
  fi
done

exit 0