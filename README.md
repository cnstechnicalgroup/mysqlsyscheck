# CNS MySQL System Check
## Introduction
This script collects performance stats from a GNU/Linux server running MySQL. The output is exported to a gzip archive.

## Prerequisites
In addition to a few standard Linux commands, this script has the following 
prerequisites:

* **sar / iostat** -	These commands are available in the sysstat package on most modern Linux distributions. We require that both are correctly installed and the system has been collecting data for at least seven days (not including today).

* **mysql** -	This is the standard MySQL command line client.

* **mysqldump** -	This is the default MySQL backup program.

## Running cnssyscheck.sh
The script, cnssyscheck.sh, must run as the root user or using sudo. It will notify you if any of the prerequisits are missing.

Once the script has collected the required data it will prompt you for your full name, company name, email address and a few details about the system. Upon completion, the script will present instructions explaining how to email the output to us.

### Run as root
<code>./cnssyscheck.sh</code>

### Run using sudo
<code>sudo ./cnssyscheck.sh</code>

## Files

* **cnssyscheck.sh** - The script. When run as root, it gathers sar and MySQL output and writes it to a gzip archive.

* **README.md** - This file.

* **LICENSE.txt** - The GNU General Public License, Version 3.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

## Support
Please email <support@cnstechgroup.com> if you have any questions or need any help running cnssyscheck.sh

Thanks,

~CNS Technical Group, Inc.
