@echo off
cd /d %~dp0
echo npm install...
call npm install
cd ..
set FUNCTIONS_DISCOVERY_TIMEOUT=90
echo firebase deploy --only functions:purge ...
firebase deploy --only functions:purge
pause
