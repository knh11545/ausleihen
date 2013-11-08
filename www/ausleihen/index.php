<h2>Ausleihzahlen der Lehrbuchsammlung</h2>

<?php

#
# Copyright (C) 2008 Gernot Deinzer
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


if (!$conn=mysql_connect('localhost','user','password')) 
  {
  echo("Datenbankfehler");
  echo("Verbindung zur DB kann nicht hergestellt werden!");
  echo("");
  exit;
  }
  
$res = mysql_select_db("bestand");

if (isset($_REQUEST['shelf']))
{

$beg_signatur = $_REQUEST['shelf'];;

echo '<h3>Daten für Exemplare mit dem Signaturenmuster: '.$beg_signatur.'</h3>';	

$query = "SELECT MAX(date) FROM loan_status";
$result = mysql_query( $query );
$row = mysql_fetch_array($result);
$current_date = $row[0];

$query = "SELECT  MIN(date) FROM loan_status WHERE d01ort LIKE \"$beg_signatur\"";
$query = "SELECT DATE_FORMAT( MIN(date), GET_FORMAT( DATE, \"EUR\") ) FROM loan_status WHERE d01ort LIKE \"$beg_signatur\"";
$result = mysql_query( $query );
$row = mysql_fetch_array($result);
$min_date = $row[0];

echo '<p>Beginn der Statistik: ' . $min_date . '</p>';

$query = " SELECT DISTINCT d01katkey from loan_status where d01ort like \"$beg_signatur\" order by d01ort";


$result = mysql_query( $query );

echo '<table>';
echo '<tr>';
echo '<th>Signatur</th>';
echo '<th>Ausgel.</th>';
echo '<th>n. ausgel.</th>';
echo '<th>Proz. ausgel.</th>';
echo '<th></th>';
echo '</tr>';


while ($row = mysql_fetch_array($result) )
{
   echo '<tr>';

   $query_old_title = "SELECT COUNT(*) FROM loan_status WHERE d01katkey =\"$row[0]\" AND date=\"$current_date\"";
   $result_old_title = mysql_query( $query_old_title );
   $row_old= mysql_fetch_array($result_old_title);

   $query_sig = "SELECT min(d01ort) from loan_status where d01katkey =\"$row[0]\" AND d01ort like \"$beg_signatur\"";
   $result_sig = mysql_query( $query_sig);
   if ($res_sig = mysql_fetch_array($result_sig))
   {
	   $signatur = $res_sig[0];
   }

   echo '<td style="border-bottom-style:dashed;border-bottom-width:1px;border-color:black">';
   if ( $row_old[0] > 0 )
   {
	   echo '<a href ="https://www.regensburger-katalog.de/InfoGuideClient.ubrsis/start.do?Login=igubr&Language=De&SearchMode=2&combinationOperator[0]=&searchCategories[0]=9902&searchString[0]='.$signatur.'">';
	   echo $signatur;
	   echo '</a>';
   } else {
	  echo "* ".$signatur;
   }
   echo '</td><td style="border-bottom-style:dashed;border-bottom-width:1px;border-color:black">';

   $query_stat = "SELECT count(*) from loan_status where d01status=4 and d01katkey =\"$row[0]\"  AND d01ort like \"$beg_signatur\"";
   $result_stat = mysql_query( $query_stat);
   if ($res_stat = mysql_fetch_array($result_stat))
   {
   $ausl = $res_stat[0];	
   }

   $query_stat_not = "SELECT count(*) from loan_status where d01status!=4 and d01katkey =\"$row[0]\"  AND d01ort like \"$beg_signatur\"";
   $result_stat_not = mysql_query( $query_stat_not);
   if ($res_stat_not = mysql_fetch_array($result_stat_not))
   {
   $ausl_not = $res_stat_not[0];	
   }
   $proz = $ausl / ($ausl+$ausl_not) *100.0;

   echo '<a href="details.php?katkey='.$row[0].'" target="details">'.$ausl.'</a></td><td style="border-bottom-style:dashed;border-bottom-width:1px;border-color:black">'.$ausl_not.'</td><td style="border-bottom-style:dashed;border-bottom-width:1px;border-color:black">'.$proz;
  

   echo '</td><td style="border-bottom-style:dashed;border-bottom-width:1px;border-color:black">';

   echo '<img src="balken.php?proz='.$proz.'">';

   echo '</td>';


   echo '</tr>';


}

echo '</table>';
}
else
{


echo '<form action="'.$_SERVER['php_self'].'" method="post">';
echo '<select name="shelf">';

$query_shelf = "SELECT shelfmark, description from locations where details=1 order by description";
$result_shelf = mysql_query( $query_shelf );


while ($res_shelf=mysql_fetch_array($result_shelf))
{
echo '<option value="'.$res_shelf[0].'">'.$res_shelf[1].'</option>';

}
echo '</select>';
echo '<input type="submit" value="Abschicken">';
echo '</form>';

}


?>
