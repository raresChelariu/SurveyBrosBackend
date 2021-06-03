# pass = SHA512 ( 'SurveyBrosAPIPass' )
# https://emn178.github.io/online-tools/sha512.html

create database if not exists SurveyBrosAPITables;
create user if not exists SurveyBrosAPIUser@localhost identified by 'ad0ac79248356e2f93b8a48e8d0da4e1b206afff0972ad11a186218f5c3533efb0efc799320d31cf3c29ea4e3ef45f05fff4683e4f9c9cda6ffc597908d0f7b8';
grant all privileges on SurveyBrosAPITables.* to SurveyBrosAPIUser@localhost;
flush privileges;