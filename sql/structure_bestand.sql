-- MySQL dump 10.9
--
-- Host: localhost    Database: bestand
-- ------------------------------------------------------
-- Server version	4.1.15-Debian_0.dotdeb.4-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `branch_libraries`
--

DROP TABLE IF EXISTS `branch_libraries`;
CREATE TABLE `branch_libraries` (
  `branch` varchar(255) collate latin1_german1_ci NOT NULL default '',
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `branch` (`branch`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_german1_ci;

--
-- Table structure for table `cache_verfuegbarkeit`
--

DROP TABLE IF EXISTS `cache_verfuegbarkeit`;
CREATE TABLE `cache_verfuegbarkeit` (
  `date` date NOT NULL default '0000-00-00',
  `standort` varchar(10) collate latin1_german1_ci default NULL,
  `d01katkey` int(11) NOT NULL default '0',
  `basissignatur` varchar(40) collate latin1_german1_ci default NULL,
  `exemplare` bigint(21) NOT NULL default '0',
  `frei` double(17,0) default NULL,
  `ausgeliehen` double(17,0) default NULL,
  `bestellt` double(17,0) default NULL,
  `rueckversand` double(17,0) default NULL,
  KEY `date` (`date`),
  KEY `d01katkey` (`d01katkey`),
  KEY `standort` (`standort`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_german1_ci;


--
-- Table structure for table `d01status`
--

DROP TABLE IF EXISTS `d01status`;
CREATE TABLE `d01status` (
  `code` smallint(6) NOT NULL default '0' COMMENT 'Loan status of a copy. Value from sisis.d01buch.d01status.',
  `name` varchar(255) default NULL COMMENT 'Textual description of loan status',
  PRIMARY KEY  (`code`),
  UNIQUE KEY `idx_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Codes for loan status of a copy';

--
-- Table structure for table `faculty`
--

DROP TABLE IF EXISTS `faculty`;
CREATE TABLE `faculty` (
  `d02fakul` varchar(16) NOT NULL default '' COMMENT 'Faculty or School. Value of sisis.d02ben.d02fakul.',
  `d02zweig` smallint(6) default NULL COMMENT 'Zweigstelle. From sisis.d50zweig.d50zweig',
  `name` varchar(255) default NULL COMMENT 'Name of faculty or school.',
  PRIMARY KEY  (`d02fakul`),
  UNIQUE KEY `idx_name` (`name`),
  KEY `fk_faculty_d02zweig` (`d02zweig`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Faculties (or schools) of university.';

--
-- Table structure for table `library_user_group`
--

DROP TABLE IF EXISTS `library_user_group`;
CREATE TABLE `library_user_group` (
  `d02bg` smallint(6) NOT NULL default '0' COMMENT 'Faculty or School. Value of sisis.d01buch.d01bg and sisis.d02ben.d02bg.',
  `name` varchar(255) default NULL COMMENT 'Name of library user group.',
  PRIMARY KEY  (`d02bg`),
  UNIQUE KEY `idx_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Groups of library users.';

--
-- Table structure for table `loan_statistics`
--

DROP TABLE IF EXISTS `loan_statistics`;
CREATE TABLE `loan_statistics` (
  `date` date NOT NULL default '0000-00-00',
  `total` int(11) NOT NULL default '0',
  `free` int(11) NOT NULL default '0',
  `ordered` int(11) NOT NULL default '0',
  `borrowed` int(11) NOT NULL default '0',
  `sent_back` int(11) NOT NULL default '0',
  `shelfmark` varchar(255) collate latin1_german1_ci NOT NULL default '',
  `branch_id` int(11) default NULL,
  `holding_id` int(11) default NULL,
  PRIMARY KEY  (`date`,`shelfmark`),
  KEY `date` (`date`),
  KEY `shelfmark` (`shelfmark`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_german1_ci;

--
-- Table structure for table `loan_status`
--

DROP TABLE IF EXISTS `loan_status`;
CREATE TABLE `loan_status` (
  `d01katkey` int(11) default NULL,
  `d01gsi` varchar(27) collate latin1_german1_ci default NULL COMMENT 'Mediennummer',
  `d01ort` varchar(40) collate latin1_german1_ci default NULL,
  `d01status` int(11) default NULL,
  `d01av` date default NULL,
  `d01rv` date default NULL,
  `d01vlanz` int(11) default NULL,
  `d01bg` int(11) default NULL,
  `d01vmanz` int(11) default NULL,
  `d02fakul` int(11) default NULL COMMENT 'Fakultaet',
  `date` date default NULL,
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `date_d01ort` (`date`,`d01ort`),
  UNIQUE KEY `date_katkey_ort` (`date`,`d01katkey`,`d01ort`),
  KEY `d01katkey` (`d01katkey`),
  KEY `d01ort` (`d01ort`),
  KEY `d01status` (`d01status`),
  KEY `date` (`date`),
  KEY `d01bg` (`d01bg`),
  KEY `d02fakul` (`d02fakul`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_german1_ci MAX_ROWS=1000000000;

--
-- Table structure for table `locations`
--

DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations` (
  `shelfmark` varchar(255) collate latin1_german1_ci NOT NULL default '',
  `description` varchar(255) collate latin1_german1_ci default NULL,
  `branch_id` int(11) default NULL,
  `details` tinyint(1) default '0',
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `shelfmark` (`shelfmark`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_german1_ci;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

