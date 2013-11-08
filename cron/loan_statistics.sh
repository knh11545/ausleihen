#!/bin/sh
# 
# Store usage statistics in a MySQL database
#
# Author: Helge Knüttel
# Last modified: 2013-10-21
#
# Copyright (C) 2007-2013  Helge Knüttel
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

MYPATH="/home/user/ausleihen/"
DAY=`/bin/date +'%A'` 
LOGFILE="${MYPATH}/cron/loan_statistics_${DAY}.log"
CMD="${MYPATH}/cron/get_loan_statistics.pl"
EMAILADDR="user@some.library.domain"

if [ -f $LOGFILE ] ; then
	/bin/mv $LOGFILE $LOGFILE.old
fi
/bin/date > $LOGFILE 2>&1
echo "Server: $HOSTNAME" >> $LOGFILE 2>&1
echo "Pfad:   $MYPATH" >> $LOGFILE 2>&1
echo "Skript: $0" >> $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1

# run Perl script to retrieve loan statistics
$CMD >> $LOGFILE 2>&1

status=$?

if [ $status -ne 0 ] ; then

	echo "Erzeugung der Ausleihstatistiken schlug fehl!" >> $LOGFILE 2>&1
	echo "Exit-Status: $status" >> $LOGFILE 2>&1
	echo "Zeit: `/bin/date`" >> $LOGFILE 2>&1
	echo "Ich beende jetzt das Skript!" >> $LOGFILE 2>&1
	/usr/bin/mail $EMAILADDR -s "Fehler bei Erzeugung der Ausleihstatistiken" <$LOGFILE
	exit 1
fi


echo "" >> $LOGFILE 2>&1
/bin/date > $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1

# Update table with summarising statistics
/usr/bin/mysql -e 'SELECT @max_cache_date := MAX(date) FROM cache_verfuegbarkeit; REPLACE INTO cache_verfuegbarkeit SELECT date, left(d01ort, locate("/", d01ort) -1 ) as standort, d01katkey, MIN(d01ort) AS basissignatur, COUNT(DISTINCT d01ort) AS exemplare, SUM(IF(d01status=0,1,0)) AS frei, SUM(IF(d01status=4,1,0)) AS ausgeliehen, SUM(IF(d01status=2,1,0)) AS bestellt, SUM(IF(d01status=8,1,0)) AS rueckversand FROM loan_status l0 WHERE d01katkey>0  AND date > @max_cache_date GROUP BY d01katkey, date, left(d01ort, locate("/", d01ort) -1 ) with rollup having date is not null;' bestand >> $LOGFILE 2>&1




if [ $status -ne 0 ] ; then

	echo "Aktualisierung der Tabelle cache_verfuegbarkeit schlug fehl!" >> $LOGFILE 2>&1
	echo "Exit-Status: $status" >> $LOGFILE 2>&1
	echo "Zeit: `/bin/date`" >> $LOGFILE 2>&1
	echo "Ich beende jetzt das Skript!" >> $LOGFILE 2>&1
	/usr/bin/mail $EMAILADDR -s "Fehler bei Erzeugung der Ausleihstatistiken" <$LOGFILE
	exit 1
fi


echo "" >> $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1
/bin/date >> $LOGFILE 2>&1
echo "Erfolgreich abgeschlossen!" >> $LOGFILE 2>&1
exit 0
