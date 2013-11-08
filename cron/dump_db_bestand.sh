#!/bin/sh
#
# Create a mysqldump of a database and optionally save to version control system
#
# Author: Helge Knüttel
# Last modified: 2010-07-09
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

DB=bestand
DBUSER=user
PATH=/home/user/ausleihen
DAY=`/bin/date +'%A'` 
LOGFILE="${PATH}/cron/dump_db_${DB}_${DAY}.log"
SQLPATH=${PATH}/sql
DB_DUMP=${PATH}/backup/mysqldump/${DB}_${DAY}.sql.gz
TABLE_STRUCTURE_DUMP=${SQLPATH}/struktur_${DB}_${DAY}.sql
SKIP_SVN_COMMIT=1

EMAILADDR="user@some.library.domain"

if [ -f $LOGFILE ] ; then
	/bin/mv $LOGFILE $LOGFILE.old
fi
/bin/date > $LOGFILE 2>&1
echo "Skript: $HOSTNAME:`pwd`/$0" >> $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1


echo "Dumping table structures to ${TABLE_STRUCTURE_DUMP} ..." >> $LOGFILE 2>&1
/usr/bin/mysqldump -u $DBUSER --no-data $DB > $TABLE_STRUCTURE_DUMP 2>>$LOGFILE

status=$?

if [ $status -ne 0 ] ; then

	echo "" >> $LOGFILE 2>&1
	echo "Aufruf von " >> $LOGFILE 2>&1
	echo "	'/usr/bin/mysqldump -u $DBUSER --no-data $DB > $TABLE_STRUCTURE_DUMP'" >> $LOGFILE 2>&1
	echo "schlug fehl!" >> $LOGFILE 2>&1
	echo "" >> $LOGFILE 2>&1
	echo "Ich beende jetzt das Skript!" >> $LOGFILE 2>&1	
	echo `/bin/date` >> $LOGFILE 2>&1
    /usr/bin/mail $EMAILADDR -s "Fehler bei Sicherung der Datenbank $DB" <$LOGFILE

	exit 1

fi
echo "Done." >> $LOGFILE 2>&1



echo "" >> $LOGFILE 2>&1
echo "Dumping whole database to ${DB_DUMP} ..." >> $LOGFILE 2>&1
/usr/bin/mysqldump -u $DBUSER --skip-extended-insert $DB | /bin/gzip > $DB_DUMP 2>>$LOGFILE

status=$?

if [ $status -ne 0 ] ; then

	echo "" >> $LOGFILE 2>&1
	echo "Aufruf von " >> $LOGFILE 2>&1
	echo "	'/usr/bin/mysqldump -u $DBUSER --skip-extended-insert $DB > $DB_DUM'" >> $LOGFILE 2>&1
	echo "schlug fehl!" >> $LOGFILE 2>&1
	echo "" >> $LOGFILE 2>&1
	echo "Ich beende jetzt das Skript!" >> $LOGFILE 2>&1	
	echo `/bin/date` >> $LOGFILE 2>&1
    /usr/bin/mail $EMAILADDR -s "Fehler bei Sicherung der Datenbank $DB" <$LOGFILE

	exit 1

fi
echo "Done." >> $LOGFILE 2>&1


# subversion commit

if [ $SKIP_SVN_COMMIT -ne 0 ] ; then
	echo "" >> $LOGFILE 2>&1
	echo "subversion commit ist ausgeschaltet!" >> $LOGFILE 2>&1	
	echo "Ich beende jetzt das Skript!" >> $LOGFILE 2>&1	
	echo `/bin/date` >> $LOGFILE 2>&1

	exit 0

fi

/usr/bin/svn commit --non-interactive -m "Tagessicherung `/bin/date`" $TABLE_STRUCTURE_DUMP $DB_DUMP  >>$LOGFILE 2>&1

status=$?

if [ $status -ne 0 ] ; then

	echo "" >> $LOGFILE 2>&1
	echo "commit in subversion schlug fehl!" >> $LOGFILE 2>&1
	echo "" >> $LOGFILE 2>&1
	echo "Ich beende jetzt das Skript!" >> $LOGFILE 2>&1	
	echo `/bin/date` >> $LOGFILE 2>&1
    /usr/bin/mail $EMAILADDR -s "Fehler bei Sicherung der Datenbank $DB" <$LOGFILE

	exit 1

fi

echo "" >> $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1
echo "Alles erfolgreich abgeschlossen!" >> $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1
echo "" >> $LOGFILE 2>&1
/bin/date >> $LOGFILE 2>&1
