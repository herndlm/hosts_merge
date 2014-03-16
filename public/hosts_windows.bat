@ECHO OFF
%~d0
cd %~d0%~p0
ATTRIB +A -H -R -S %windir%\system32\drivers\etc\HOSTS
COPY /Y hosts.txt %windir%\system32\drivers\etc\HOSTS
echo Hosts file has been updated. The ads should be gone now.
Pause
EXIT
