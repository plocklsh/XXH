set names utf8;

drop database if exists `gameacc`;
create database `gameacc`;
use `gameacc`;

drop table if exists `user`;
create table `user`(
	`uid` int(11) not null auto_increment comment 'user id',
	`name` varchar(50) not null comment '用户名',
	`password` varchar(50) not null,

	unique key `name` (`name`),
	primary key(`uid`)
)
ENGINE=InnoDB 
DEFAULT CHARSET=utf8;

commit;