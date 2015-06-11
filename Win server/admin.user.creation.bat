REM Invoke with username and password to create new user and add to administrators group
REM All switches can be read here - http://pcsupport.about.com/od/commandlinereference/p/net-user-command.htm
NET USER %1 "%2" /fullname:"%3" /ADD
NET LOCALGROUP "Administrators" "%1" /add