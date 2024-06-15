#!/bin/bash

function log_error() {
	echo "<3> ${*}" 1>&2
}

function get_bt_mac() {
	local bt_device_num="$1"
	if [ -z "${bt_device_num}" ]; then
		log_error "get_bt_mac: Unknown device num"
		return 1
	fi

	local hw_addr_base=$(ubnteeprom -board -key "hwaddrbbase")
	local eth_count=$(ubnteeprom -board -key "EthMACAddrCount")
	local wifi_count=$(ubnteeprom -board -key "WiFiMACAddrCount")
	local bt_count=$(ubnteeprom -board -key "BtMACAddrCount")

	if [ -z "${hw_addr_base}" ] || [ -z "${eth_count}" ] || [ -z "${wifi_count}" ] || [ -z "${bt_count}" ]; then
		log_error "Unexpected contents in $UBNTHAL_BOARD"
		return 2
	fi

	if [ ${bt_device_num} -ge ${bt_count} ]; then
		log_error "Unsupported device number (bt_device_num[${bt_device_num}] >= bt_count[${bt_count}])"
		return 3
	fi

	local mac=$(echo "${hw_addr_base}" | sed s/":"//g)
	local mac_dec=$(printf '%d\n' 0x${mac})
	local bt_mac_dec=$(expr ${mac_dec} + ${eth_count} + ${wifi_count} + ${bt_device_num})

	printf '%012X\n' "${bt_mac_dec}" | tr A-Z a-z
}

function main(){
	BT_DEVICE="$1"
	[ -z "$BT_DEVICE" ] && return 2

	BT_DEVICE_NUM=$(echo "${BT_DEVICE}" | sed s/"hci"//g)
	if [[ ! "${BT_DEVICE_NUM}" =~ ^[0-9]+$ ]]; then
		log_error "Invalid bluetooth device number [${BT_DEVICE_NUM}]"
		return 3
	fi

	BT_MAC=$(get_bt_mac "${BT_DEVICE_NUM}")
	[ $? -eq 0 ] || return 4

	local board_id=$(ubnteeprom -board -key "boardid")
	case ${board_id} in
		ea16)
			# unvr: nothing to do here
			;;
		ea1a)
			# unvr
			usb_based_init
			;;
		ea20)
			# unvr-pro
			gpio_num=$(find_gpio_on_expander 0 0020 8)
			if [ $gpio_num -lt 0 ]; then
				return 5
			fi
			gpio_reset $gpio_num
			uart_based_init /dev/ttyS3 "/lib/firmware/csr8x11/csr8x11-a12-bt4.2-patch-2018_uart.psr"
			;;
		*)
			return 4
			;;
	esac
}

function find_gpio_on_expander() {
	local bus=$1
	local addr=$2
	local pin=$3
	local gpiochip_dir="/sys/bus/i2c/devices/$bus-$addr/gpio"
	local base

	for chip in $(find $gpiochip_dir -maxdepth 1 -name 'gpiochip*' -printf "%f\n"); do
		base=$(echo $chip | sed 's/gpiochip//g')
		echo $((base + pin))
		return
	done

	echo -1
}

function gpio_reset(){
	local gpio=$1

	if [ ! -d /sys/class/gpio/gpio${gpio} ]; then
		echo ${gpio} > /sys/class/gpio/export
	fi
	echo out > /sys/class/gpio/gpio${gpio}/direction
	echo 1 > /sys/class/gpio/gpio${gpio}/value
	sleep 1
	echo 0 > /sys/class/gpio/gpio${gpio}/value
	sleep 1
	echo 1 > /sys/class/gpio/gpio${gpio}/value
	sleep 1
	echo ${gpio} > /sys/class/gpio/unexport
}

function uart_based_init(){
	local bt_serial_dev="$1"
	local bt_serial_speed="115200"
	local bt_fw="$2"
	local bt_option="$3"
	local bt_proto="bcsp"
	local loop_no=10
	local i=0

	for i in $(seq 0 ${loop_no}); do
		if [ ${i} -gt 0 ]; then
			if [ ${i} -eq ${loop_no} ]; then
				log_error "Failed to initialize bluetooth (BT is not operational)"
				break
			fi
			log_error "Unable to initialize bluetooth. Give it another try (${i})"
		fi

		#load psr file
		bccmd -t "${bt_proto}" -b "${bt_serial_speed}" -d "${bt_serial_dev}" psload -r ${bt_fw} || continue

		#set bt address: <device index> <mac byte 4> 0x00 <mac byte 6> <mac byte 5> <mac byte 3> 0x00 <mac byte 2> <mac byte 1>
		bccmd -t "${bt_proto}" -d "${bt_serial_dev}" -b "${bt_serial_speed}" psset -r \
			0x$((BT_DEVICE_NUM+1)) \
			0x${BT_MAC:6:2} \
			0x00 \
			0x${BT_MAC:10:2} \
			0x${BT_MAC:8:2} \
			0x${BT_MAC:4:2} \
			0x00 \
			0x${BT_MAC:2:2} \
			0x${BT_MAC:0:2} \
			2>&1

		# attach UART interface
		hciattach -s "${bt_serial_speed}" "${bt_serial_dev}" "${bt_proto}" "${bt_serial_speed}" "${bt_option}"
		sleep 0.5

		# check if the device exists
		[ -d "/sys/class/bluetooth/${BT_DEVICE}" ] && break

	done

	hciconfig ${BT_DEVICE} up
}

main "$@"
