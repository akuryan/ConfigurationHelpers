REM Pass source folder and target folder to create set of default links
REM Target is to store data on slower, but longer living HDD

set sourceFolder=%1
set targetFolder=%2

mkdir %targetFolder%\bin
mkdir %targetFolder%\csx
mkdir %targetFolder%\ecf
mkdir %targetFolder%\obj
mkdir %targetFolder%\rcf
mklink /D %sourceFolder%\bin %targetFolder%\bin
mklink /D %sourceFolder%\csx %targetFolder%\csx
mklink /D %sourceFolder%\ecf %targetFolder%\ecf
mklink /D %sourceFolder%\obj %targetFolder%\obj
mklink /D %sourceFolder%\rcf %targetFolder%\rcf