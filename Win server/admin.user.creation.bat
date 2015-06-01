REM Invoke with username and password to create new user and add to administrators group
NET USER %1 "%2" /ADD
NET LOCALGROUP "Administrators" "%1" /add