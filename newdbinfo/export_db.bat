set user=root
set pwd=12345678
set T=%date:~0,4%_%date:~5,2%_%date:~8,2%_%time:~0,2%_%time:~3,2%_%time:~6,2%

mysqldump -u%user% -p%pwd% dgacc > dgacc_%T%.sql


pause