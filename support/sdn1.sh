#!/bin/bash
# start-up script for the whole unifycore topology (both forwarders and controllers)


if [[ $EUID -ne 0 ]]; then
    echo 'Dont forget to use sudo ;-)'
    exit 1
fi

FWD_ROOT="/home/tibor/ofsoftswitch13"
CNT_SCRIPT="/home/tibor/ryu/ryu/app/roaming_magic.py"
#CNT_SCRIPT="/root/ryu/ryu/app/hub.py"

CONTROLLER="tcp:127.0.0.1:6633"

#VALGRIND="valgrind --suppressions=/root/valgrind.suppress --leak-check=yes "
VALGRIND="valgrind --log-file=/tmp/valgrind.log --tool=memcheck --leak-check=yes "

function start_fwd() {
	SOCKET="unix:/tmp/dp$1.socket"
	$FWD_ROOT/udatapath/ofdatapath -i "$3" -d "$2" "p$SOCKET" -v > /tmp/dp1_$1.log 2>&1 &
	$FWD_ROOT/secchan/ofprotocol "$SOCKET" "$CONTROLLER" --fail=closed  > /tmp/of1_$1.log 2>&1 &
}

function debug_fwd() {
	SOCKET="unix:/tmp/dp$1.socket"
	$FWD_ROOT/secchan/ofprotocol "$SOCKET" "$CONTROLLER" --fail=closed  > /tmp/of1_$1.log 2>&1 &
	gdb --args $FWD_ROOT/udatapath/ofdatapath -i "$3" -d "$2" "p$SOCKET" -v 
}

function valgrind_fwd() {
	SOCKET="unix:/tmp/dp$1.socket"
	$FWD_ROOT/secchan/ofprotocol "$SOCKET" "$CONTROLLER" --fail=closed  > /tmp/of1_$1.log 2>&1 &
	$VALGRIND $FWD_ROOT/udatapath/ofdatapath -i "$3" -d "$2" "p$SOCKET" -v 
}

function start_cnt() {
	#screen -d -m -S "controller" ryu-manager $CNT_SCRIPT --observe-links --verbose > /tmp/controller.log 2>&1
	ryu-manager $CNT_SCRIPT --observe-links --verbose > /tmp/controller_1.log 2>&1 &
}

function do_start() {
  # big topology from the project documentation (and README)
	#if we use a simulator, we do not use eth2, but BSS0 <---> corea1 instead
	#start_fwd a 00000000000a 'eth2,corea2,corea3,corea4'
	start_fwd a 00000000000a 'core1a1,core1a2,core1a3,core1a4'
	start_fwd b 00000000000b 'core1b1,core1b2,core1b3'
	start_fwd c 00000000000c 'core1c1,core1c2,core1c3,core1c4'
	start_fwd d 00000000000d 'core1d1,core1d2,core1d3'
	start_fwd e 00000000000e 'core1e1,core1e2'
	#sleep 0.5

	start_cnt
	sleep 0.5

	#valgrind_fwd a 00000000000a 'eth2,corea2,corea3,corea4'
	#debug_fwd a 00000000000a 'eth2,corea2,corea3,corea4'
}

function do_stop() {
	# forwarder
	killall ofprotocol
	killall ofdatapath

	# and controller
	killall ryu-manager
}

case $1 in
	start)
		do_start
		;;
	stop)
		do_stop
		;;
	restart)
		do_stop
		do_start
		;;
esac

