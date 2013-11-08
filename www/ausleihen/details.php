<?php
#
# Copyright (C) 2007-2013 Helge Knüttel
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
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <title>Details zur Ausleihe</title>
	<link rel="search" type="application/opensearchdescription+xml" title="Suche nach Lehrbuchnutzung" href="./benutzung_lehrbuch.xml" />

	<!-- Load Googla Ajax API -->
	<!-- 
	<script type='text/javascript' src='http://www.google.com/jsapi'></script> 
	-->
    <script type='text/javascript'>
function chartLoaded() {

       var data = new google.visualization.DataTable();
       data.addColumn('date'  , 'Datum');
       data.addColumn('number', 'Exemplare');
       //data.addColumn('number', 'frei');
       data.addColumn('number', 'belegt');
       //data.addColumn('number', 'bestellt');
       //data.addColumn('number', 'rueckversand');
       data.addRows(json_data);

       var chart = new google.visualization.AnnotatedTimeLine(document.getElementById('chart_div'));
       chart.draw(data, {
			   displayAnnotations: false,
			   fill: 40,
			   dateFormat: 'dd.MM.yyyy',
		   }
		);
}

//
//  Alles hierunter ist nur zum Testen mit dynamic loading
//

function dataReady() {
	//alert("Data ready!");
	initLoader();

}

// load the Chart API and execute the chartLoaded callback when the API is ready
function loadVisualisations() {
	
	google.load( 'visualization', '1', 
		{
			'packages' : ['annotatedtimeline'],
			'callback' : chartLoaded,
			'language' : 'de'
		}
	);

}

// 
function initLoader() {
	var script = document.createElement("script");
	script.src = "http://www.google.com/jsapi?callback=loadVisualisations";
	script.type = "text/javascript";
	document.getElementsByTagName("head")[0].appendChild(script);
}
</script>
  </head>
  <body>
	<div style="right:0; position:absolute; padding-right:1em">TB Medizin</div>

    <h1>Details zur Ausleihe</h1>

	<form method="get" enctype="application/x-www-form-urlencoded">
	katkey <input type="text" name="katkey" size="20" /> oder Signatur <input type="text" name="signatur" size="30" />
	<input type="submit" name="Suchen" value="Suchen" />
	</form>
	<hr />

<?php	

if (!$conn=mysql_connect('localhost','user','password')) 
{
	end_html_and_exit( "Datenbankfehler: Verbindung zur DB kann nicht hergestellt werden!" );
}
  
$res = mysql_select_db("bestand");

$katkey = $_REQUEST['katkey'];
$signatur = $_REQUEST['signatur'];

if ( $katkey )
{
	echo "katkey: $katkey";
}
else if ( $signatur )
{
	echo "Signatur: $signatur";
	$query = "select distinct d01katkey from loan_status where d01ort='$signatur'";
	$result = mysql_query( $query );
	if (! $result)
	{
	    end_html_and_exit( "Anfrage ($query) konnte nicht ausgeführt werden : " . mysql_error() );
	}
	$row = mysql_fetch_row($result);
	$katkey = $row[0];
	if ( ! $katkey )
	{
		end_html_and_exit( "Signatur nicht gefunden!" );
	}
}
else
{
	end_html_and_exit( "" );
}

	if ( ! preg_match( "/^\d+$/", $katkey ) )
	{
		end_html_and_exit( "Kein gültiger katkey!" );
	}
	# Nach einer ersten Recherche gibt es in dieser PHP-Version keine prepared statements!!! Oh je.

	# Zusammenfassung:
    echo "<h2>Zusammenfassung</h2>\n";
    echo "<p><a href=\"/perl/exemplare.pl?katkey=$katkey\" target=\"exemplare\">Exemplardaten</a></p>\n";

	# Standorte wählen:
	$query = "select distinct standort from cache_verfuegbarkeit where d01katkey = $katkey order by standort";
	$standort = $_REQUEST['standort']; 
	if ($standort) {
		$display_standort = $standort;
	} else {
		$display_standort = "Alle";
	}

	$result = mysql_query( $query );
	
	if (!$result)
	{
	    end_html_and_exit( "Anfrage ($query) konnte nicht ausgeführt werden : " . mysql_error() );
	}

	echo "<strong>Gewählter Standort: $display_standort </strong><br />\n";
	echo "<form method=\"get\" enctype=\"application/x-www-form-urlencoded\">\n";
	echo "  <select name=\"standort\" size=\"1\">\n";
	$how=MYSQL_ASSOC;
	while ($row = mysql_fetch_array($result, $how))
	{
		if ($row[standort] == $standort) {
			$selected = "selected=\"selected\"";
		} else {
			$selected = "";
		}
		$standort_shown = $row[standort];
		if (! $standort_shown) { $standort_shown = "Alle"; } 
		echo "<option $selected value=\"$row[standort]\">$standort_shown</option>\n";
	}
	echo "  </select>\n";
	echo "  <input type=\"hidden\" name=\"katkey\" value=\"$katkey\" />\n";
	echo "  <input type=\"submit\" name=\"Standort wählen\" value=\"Standort wählen\" />\n";
	echo "</form>\n";

	$query = "select standort, basissignatur, d01katkey, CONCAT(MIN(exemplare), ' - ', MAX(exemplare)) AS 'Exemplare', sum(IF(frei = 0,1,0)) as 'Tage vergriffen', CONCAT( ROUND(100 * SUM(IF(frei = 0,1,0)) / COUNT(d01katkey), 1), '%') as 'Proz. Tage vergriffen', count(d01katkey) as 'Tage insgesamt', MAX(date) as 'Daten bis', avg(frei) AS 'mittl. freie Exemplare', stddev(frei), stddev(frei)/avg(frei) AS 'Variationskoeffizient' from cache_verfuegbarkeit where d01katkey = $katkey group by d01katkey, standort;";
	
	$result = mysql_query( $query );
	
	if (!$result)
	{
	    end_html_and_exit( "Anfrage ($query) konnte nicht ausgeführt werden : " . mysql_error() );
	}
	echo mysql_result2table( $result );

	
	# Die Details: 
    echo "<h2>Zeitverlauf $display_standort</h2>\n";

	#$query = "select year(date) as year, month(date) as month, day(date) as day, exemplare, frei, ausgeliehen, bestellt, rueckversand from cache_verfuegbarkeit where d01katkey = $katkey order by date;";
	if ($standort) {
		$query = "select year(date) as year, month(date) as month, day(date) as day, exemplare, (exemplare - frei) as belegt from cache_verfuegbarkeit where d01katkey = $katkey AND standort = $standort order by date;";
	} else {
		$query = "select year(date) as year, month(date) as month, day(date) as day, exemplare, (exemplare - frei) as belegt from cache_verfuegbarkeit where d01katkey = $katkey AND standort IS NULL order by date;";
	}
	$result = mysql_query( $query );
	
	# Visualisierung mit Google Chart Tools
	if (!$result)
	{
	    end_html_and_exit( "Anfrage ($query) konnte nicht ausgeführt werden : " . mysql_error() );
	}
	$json = "[\n";
	$how=MYSQL_ASSOC;
	while ($row = mysql_fetch_array($result, $how))
	{
		$javascript_month = $row[month] - 1;	# JavaScript Date object has month range 0-11!! Very strange!
		#$json .= "  [ new Date($row[year], $javascript_month, $row[day]), $row[exemplare], $row[frei], $row[ausgeliehen], $row[bestellt], $row[rueckversand] ],\n";
		$json .= "  [ new Date($row[year], $javascript_month, $row[day]), $row[exemplare], $row[belegt] ],\n";
	}
	$json .= "\n]";
	echo "<script type='text/javascript'>\n";
	echo "  var json_data = $json;\n";
	#echo "  alert(json_data);\n";
	echo "  dataReady();\n";
	echo "</script>\n";
	# Must specify the size of the container element for the annotated time line chart explicitly!
    echo "<div id='chart_div' style='width: 950px; height: 350px;'></div>\n";
	#echo "<pre>$json</pre>\n";

		

	#$query = "select date, exemplare, frei, ausgeliehen, bestellt, rueckversand, CONCAT(REPEAT('*', exemplare - frei), REPEAT('-', frei)) AS 'Exemplare genutzt(*) / frei(-)' from cache_verfuegbarkeit where d01katkey = $katkey order by date;";
	#$result = mysql_query( $query );
	#
	#if (!$result)
	#{
	#    end_html_and_exit( "Anfrage ($query) konnte nicht ausgeführt werden : " . mysql_error() );
	#}
	# echo mysql_result2table( $result );

	end_html_and_exit( "" );

function mysql_result2table( $result )
{
	$how=MYSQL_ASSOC;
	if ( !mysql_fetch_array( $result ) )
	{
		return "No records found in query result!";
	}
	mysql_data_seek( $result, 0 );
	$keys = array_keys( mysql_fetch_array( $result, $how ));
	mysql_data_seek( $result, 0 );
	$table = "<table border=\"1\">\n";
	$table .= "  <thead>\n";
	$table .= "  <tr>\n";
	foreach ($keys as $mykey)
		{
			$table .= "    <th>$mykey</th>\n";
		}
	$table .= "  </tr>\n";
	$table .= "  </thead>\n";
	$table .= "  <tbody>\n";
	while ($row = mysql_fetch_array($result, $how))
	{
		$table .= "  <tr>\n";
		foreach ($keys as $mykey)
		{
			$table .= "    <td><span style=\"font-family:monospace\">$row[$mykey]</span></td>\n";
		}
		$table .= "  </tr>\n";
	}
	$table .= "  </tbody>\n";
	$table .= "<table>\n";
	return $table;
}

function end_html_and_exit( $message )
{
	echo "<p>$message</p>\n";
	echo "<hr />\n";
	echo "<p>Helge Knüttel, 2007-2013</p>\n";
	echo "  </body>\n";
	echo "</html>\n";
	exit;
}

?>

