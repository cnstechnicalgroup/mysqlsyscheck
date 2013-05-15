#!/bin/bash
# cnssyscheck.sh, ver 0.0.1
# 
# Summary
# 
# This script collects performance stats from a GNU/Linux server 
#	running MySQL. The output is exported to a gzip archive.
#
# Copyright (c) 2013 CNS Technical Group, Inc.
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the Free 
# Software Foundation, either version 3 of the License, or (at your option) 
# any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
# more details.
# 
# You should have received a copy of the GNU General Public License along 
# with this program. If not, see http://www.gnu.org/licenses/.

#############
# Settinigs #
#############

LC_ORIG=$LC_ALL
export LC_ALL=C 

# Max number of arguments, empty vaule = unlimited arguments
SCRIPT_MAX_ARGS=0

#########################
# Common Initialization #
#########################

SCRIPT_NAME="$(basename "$0")"
# Stores arguments
SCRIPT_ARGS=()
# Stores option flags
SCRIPT_OPTS=()
# For returning value after calling SCRIPT_OPT
SCRIPT_OPT_VALUE=

############
# Greeting #
############

GREETING="
Welcome to the CNS MySQL System Check.

This script will gather sar and MySQL data and prepare
a gzip file for you to email to our system administrators.

We will analyize the data and determine if performance
issues on this system are a result of a MySQL configuration, 
an underlying system configuration, or both.
"

#############
# Functions #
#############

usage () {
  echo "$GREETING
	
Usage: $SCRIPT_NAME [options] [arguments]

Options:
  --no-color   do not use colors
  -h, --help   display this help and exit
"  
}

# Check if file exists
function file_exists {
  if ( [ -e $1 ] ) then 
    true
  else
    false
  fi
}

parse_options() {
  while (( $#>0 )); do
    opt="$1"
    arg="$2"
    
    case "$opt" in
      -o|--option-with-arg)
        SCRIPT_OPT_SET "opt1" "$arg" 1
        shift
        ;;
      -O|--option-without-arg)
        SCRIPT_OPT_SET "opt2"
        ;;
      -e|--option-needs-do-something-right-away)
        do_something
        ;;
      --no-color)
        SCRIPT_OPT_SET "no-color"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        echo "$SCRIPT_NAME: invalid option -- '$opt'" >&2
        echo "Try \`$SCRIPT_NAME --help' for more information." >&2
        exit 1
        ;;
      *)
        if [[ ! -z $SCRIPT_MAX_ARGS ]] && (( ${#SCRIPT_ARGS[@]} == $SCRIPT_MAX_ARGS )); then
          echo "$SCRIPT_NAME: cannot accept any more arguments -- '$opt'" >&2
          echo "Try \`$SCRIPT_NAME --help' for more information." >&2
          exit 1
        else
          SCRIPT_ARGS=("${SCRIPT_ARGS[@]}" "$opt")
        fi
        ;;
    esac
    shift
  done
}

##################
# Handle options #
##################

SCRIPT_OPT_SET () {
  if [[ ! -z "$3" ]] && [[ -z "$2" ]]; then
    echo "$SCRIPT_NAME: missing option value -- '$opt'" >&2
    echo "Try \`$SCRIPT_NAME --help' for more information." >&2
    exit 1
  fi
  # check duplication
  SCRIPT_OPTS=("${SCRIPT_OPTS[@]}" "$1" "$2")
}

SCRIPT_OPT () {
  local i opt needle="$1"
  for (( i=0; i<${#SCRIPT_OPTS[@]}; i+=2 )); do
    opt="${SCRIPT_OPTS[i]}"
    if [[ "$opt" == "$needle" ]]; then
      SCRIPT_OPT_VALUE="${SCRIPT_OPTS[i+1]}"
      return 0
    fi
  done
  SCRIPT_OPT_VALUE=
  return 1
}

SCRIPT_SET_COLOR_VARS () {
  local COLORS=(BLK RED GRN YLW BLU MAG CYN WHT)
  local i SGRS=(RST BLD ___ ITA ___ BLK ___ INV)
  for (( i=0; i<8; i++ )); do
    eval "F${COLORS[i]}=\"\e[3${i}m\""
    eval "B${COLORS[i]}=\"\e[4${i}m\""
    eval   "T${SGRS[i]}=\"\e[${i}m\""
  done
}

########
# Main #
########

parse_options "$@"

if ! SCRIPT_OPT "no-color"; then
  SCRIPT_SET_COLOR_VARS
fi

##############################################
#
# Confirm we are running as root.
#
##############################################

if [ `whoami` != root ]; then
  echo "
Please run this script as root or using sudo.
"
  exit
fi

echo "$GREETING"

##############################################
#
# Required commands.
#
##############################################

tar="$(which tar)"
gzip="$(which gzip)"
ps="$(which ps)"
sar="$(which sar)"
iostat="$(which iostat)"
mysql="$(which mysql)"
mysqldump="$(which mysqldump)"
awk="$(which awk)"
lsb_release="$(which lsb_release)"

##############################################
#
# Confirm that tar is installed...
#
##############################################

if [[ ! -f $tar && -z $tar ]]; then
  printf "Cannot continue:\n\ntar is not installed. Please install the tar package.\n\n"
  exit 
fi

##############################################
#
# Confirm that gzip is installed...
#
##############################################

if [[ ! -f $gzip && -z $gzip ]]; then
  printf "Cannot continue:\n\ngzip is not installed. Please install the gzip package.\n\n"
  exit 
fi

##############################################
#
# Confirm that ps is installed...
#
##############################################

if [[ ! -f $ps && -z $ps ]]; then
  printf "Cannot continue:\n\nps is not installed. Please install the procps package.\n\n"
  exit 
fi

##############################################
#
# Confirm that sar is installed...
#
##############################################

if [[ ! -f $sar && -z $sar ]]; then
  printf "Cannot continue:\n\nsar is not installed. Please install the sysstat package and enable data collection.\n\n"
  exit 
fi

##############################################
#
# Confirm that iostat is installed...
#
##############################################

if [[ ! -f $iostat && -z $iostat ]]; then
  printf "Cannot continue:\n\niostat is not installed. Please install the sysstat package and enable data collection.\n\n"
  exit 
fi

##############################################
#
# Confirm that MySQL client is installed...
#
##############################################

if [[ ! -f $mysql && -z $mysql ]]; then
  printf "Cannot continue:\n\nmysql is not installed. Please install mysql-client and try again.\n\n"
  exit 
fi

##############################################
#
# Confirm that mysqldump is installed...
#
##############################################

if [[ ! -f $mysqldump && -z $mysqldump ]] ; then
  printf "Cannot continue:\n\nmysqldump is not installed. Please install mysql-client and try again.\n\n"
  exit 
fi

##############################################
#
# Confirm that lsb_release is installed...
#
##############################################

if [[ ! -f $lsb_release && -z $lsb_release ]] ; then
  printf "Cannot continue:\n\nlsb_release is not installed. Please install lsb-release and try again.\n\n"
  exit 
fi

##############################################
#
# Various variables.
#
##############################################

# OS

os_dist=$($lsb_release -si)
os_ver=$($lsb_release -sr)
os_arch=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
os_kernel=$(uname -r)

# Header

header="### BEGIN HEADER\n
CNS MySQL System Check ($(date +"%Y-%m-%d %H:%M:%S"))\n
Hostname: $HOSTNAME ($OSTYPE)\n
System: $os_dist $os_ver $os_arch / $os_kernel"

# CPU

sar_cpu=$($sar)
sar_io=$($sar -b)
iostat_all=$($iostat ALL)

# Disk

disk_partitions=$(df -lh)
sar_disk=$($sar -dp)
sar_paging=$($sar -B)

# Memory

sar_memory=$($sar -r)
sar_swap=$($sar -S)
sar_hugepage=$($sar -H)

# Network

sar_network=$($sar -n DEV)

# Top Processes

top_processes=$(ps aux| sort -nrk +4 | head)

##############################################
#                                            #
# Capture raw MySQL data for processing...   #
#                                            #
##############################################

mysql_query="USE information_schema; 
	     SELECT ' ' AS '### BEGIN LMYS00001';
	     SHOW GLOBAL STATUS;
	     SELECT ' ' AS '### BEGIN LMYS00002';
	     SELECT * FROM INFORMATION_SCHEMA.TABLES;
	     SELECT ' ' AS '### BEGIN LMYS00003';
	     SHOW VARIABLES;"

read -s -p "Enter MYSQL root password: " mysql_pwd

while ! mysql_results=$($mysql -u root -p$mysql_pwd -e "$mysql_query" && 
            printf "\n### BEGIN LMYS00004\n" &&
			      $mysqldump -u root -p$mysql_pwd --all-databases --no-data); do
  read -p "Can't connect, please retry: " mysql_pwd
done

######################################
#                                    #
# Request a few details from client. #
#                                    #
######################################

echo "

Please enter the following information:
"

read -p "Full Name: " full_name
read -p "Company Name: " company_name
read -p "Email: " email


# System's primary function?
systypemenu() {
				echo "
What is this system's primary function?:

1) Dedicated DB Server
2) Web/Application + DB Server
3) Other"

}
while [ 1 ]; do
	systypemenu
	read prime_function
	case $prime_function in
		"1")
			prime_function="Dedicated DB Server"
			printf "You selected 'Dedicated DB Server'.\n\n"; break;;
		"2")
			prime_function="App/Web + DB Server"
			printf "You selected 'Web/Application + DB Server'.\n\n"; break;;
		"3")
			prime_function="Other"
			printf "You selected 'Other'.\n\n"; break;;
		* ) 
			printf "Please answer 1-3\n";;
	esac
done

# Is this a VM?
while true; do
	read -p "Is this system virtualized? [Y/N]:" virtualized
	case $virtualized in
		[Yy]*	)	
			virtualized="Yes"
			printf "This system is a VM.\n\n"; break;;
		[Nn]*	)	
			virtualized="No"
			printf "This system is not a VM.\n\n"; break;;
		esac
done

#########################
#                       #
# Prepare final output. #
#                       #
#########################

final_output="$header
### BEGIN CLIENTINFO
Full Name: $full_name
Company Name: $company_name
Email: $email
Primary Function: $prime_function
Virtualized: $virtualized
### BEGIN LDSK00002\n$disk_partitions
### BEGIN LPRC00001\n$top_processes
### BEGIN LCPU00002\n$sar_cpu
### BEGIN LIOU00004\n$sar_io
### BEGIN LDKS00003\n$iostat_all
### BEGIN LDSK00001\n$sar_disk
### BEGIN LMEM00002\n$sar_paging
### BEGIN LMEM00003\n$sar_memory
### BEGIN LMEM00004\n$sar_swap
### BEGIN LMEM00005\n$sar_hugepage
### BEGIN LNET00001\n$sar_network
$mysql_results"

date=$(LC_ALL=C date +"%Y%M%d%H%M%S")

# write to gzip file
gzipfile=cns-$HOSTNAME-$date.gz
echo -e "$final_output" | gzip --stdout > $gzipfile

#############
#           #
# All done. #
#           #
#############

echo "Process complete. 

Please email the $gzipfile file to support@cnstechgroup.com
with 'MySQL System Check' in the subject line.

Thank you,

~CNS Technical Group, Inc.

"
