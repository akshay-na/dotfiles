del /q C:\Windows\Prefetch\*

del /q C:\Windows\Temp\*

del /q %USERPROFILE%\appdata\local\temp\*

del /q "C:\Windows\Prefetch\*"
FOR /D %%p IN ("C:\Windows\Prefetch\*.*") DO rmdir "%%p" /s /q

del /q "C:\Windows\Temp\*"
FOR /D %%p IN ("C:\Windows\Temp\*.*") DO rmdir "%%p" /s /q

del /q "%USERPROFILE%\appdata\local\temp\*"
FOR /D %%p IN ("%USERPROFILE%\appdata\local\temp\*.*") DO rmdir "%%p" /s /q

del %PROGRAMDATA%\Microsoft\Search\Data\Applications\Windows\Windows.edb

rd /s /q C:\$Recycle.bin

npm cache clear -f