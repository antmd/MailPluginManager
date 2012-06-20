DROP TABLE `crashReportPlugins`;
DROP TABLE `crashReportRecord`;
DROP TABLE `crashReportSession`;


CREATE TABLE `crashReportPlugins` (
  `plugin_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `session_id` int(11) NOT NULL,
  `identifier` varchar(40) NOT NULL DEFAULT '',
  `name` varchar(100) NOT NULL DEFAULT '',
  `path` varchar(250) NOT NULL DEFAULT '',
  `version` varchar(10) NOT NULL DEFAULT '',
  `build` varchar(15) NOT NULL DEFAULT '',
  `is_enabled` int(1) NOT NULL,
  `is_test` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`plugin_id`),
  KEY `BUNDLE_ID_INDEX` (`plugin_id`),
  KEY `VERSION_INDEX` (`version`),
  KEY `BUILD_INDEX` (`build`)
) ENGINE=MyISAM AUTO_INCREMENT=21 DEFAULT CHARSET=utf8;

CREATE TABLE `crashReportRecord` (
  `record_id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` int(11) NOT NULL,
  `identifier` varchar(40) NOT NULL DEFAULT '',
  `report_date` datetime NOT NULL,
  `report_bundle` varchar(200) NOT NULL,
  `report_type` char(6) NOT NULL DEFAULT 'mail',
  `report_content` mediumtext NOT NULL,
  `is_test` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`record_id`),
  UNIQUE KEY `UNIQUE_REPORT` (`identifier`,`report_date`,`report_bundle`),
  KEY `SESSION_INDEX` (`session_id`),
  KEY `DATE_INDEX` (`report_date`),
  KEY `TYPE_INDEX` (`report_type`),
  KEY `BUNDLE_ID_INDEX` (`report_bundle`)
) ENGINE=MyISAM AUTO_INCREMENT=27 DEFAULT CHARSET=utf8;

CREATE TABLE `crashReportSession` (
  `session_id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_addr` char(16) NOT NULL DEFAULT '',
  `session_date` datetime NOT NULL,
  `report_count` int(3) NOT NULL DEFAULT '0',
  `total_report_count` int(3) NOT NULL DEFAULT '0',
  `added_report_count` int(3) NOT NULL DEFAULT '0',
  `identifier` varchar(40) NOT NULL DEFAULT '',
  `hardware` varchar(15) NOT NULL DEFAULT '',
  `system_version` varchar(10) NOT NULL DEFAULT '',
  `system_build` varchar(15) NOT NULL DEFAULT '',
  `mail_version` varchar(10) NOT NULL DEFAULT '',
  `mail_build` varchar(15) NOT NULL DEFAULT '',
  `mail_uuid` varchar(50) NOT NULL DEFAULT '',
  `message_version` varchar(10) NOT NULL DEFAULT '',
  `message_build` varchar(15) NOT NULL DEFAULT '',
  `message_uuid` varchar(50) NOT NULL DEFAULT '',
  `is_test` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`session_id`),
  KEY `IP_DATE_INDEX` (`ip_addr`,`session_date`),
  KEY `ID_INDEX` (`identifier`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
