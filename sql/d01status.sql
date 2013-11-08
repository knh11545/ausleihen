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
-- Dumping data for table `d01status`
--


/*!40000 ALTER TABLE `d01status` DISABLE KEYS */;
LOCK TABLES `d01status` WRITE;
INSERT INTO `d01status` VALUES (2,'bestellt'),(4,'entliehen'),(0,'frei'),(8,'Rückversand an Heimatbibliothek');
UNLOCK TABLES;
/*!40000 ALTER TABLE `d01status` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

