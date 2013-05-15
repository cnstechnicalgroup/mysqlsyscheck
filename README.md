# CNS MySQL System Check
## Introduction
This script collects performance stats from a GNU/Linux server running MySQL. The output is exported to a gzip archive.

## Prerequisites
In addition to a few standard Linux commands, this script has the following prerequisites:

* **sar / iostat** -	These commands are available in the sysstat package on most modern Linux distributions. We require that both are correctly installed and the system has been collecting data for at least seven days.

* **mysql** -	This is the standard MySQL command line client.

* **mysqldump** -	This is the default MySQL backup program.

## Running cnssyscheck.sh
The script, cnssyscheck.sh, must run as the root user or using sudo. It will notify you if any of the prerequisits are missing.

Once the script has collected the required data it will prompt you for your full name, company name, email address and a few details about the system. Upon completion, the script will present instructions explaining how to email the output to us.

## Support
Please email <support@cnstechgroup.com> if you have any questions or need any help running cnssyscheck.sh

Thanks,

~CNS Technical Group, Inc.
