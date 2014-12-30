@cd /d %~dp0
@set here=%cd%
@cd /d %here%

taskkill /f /im "LoginServer.exe" 

taskkill /f /im "LoginServerForm.exe" 

taskkill /f /im "GameLogicServer_1.exe" 

taskkill /f /im "GameLogicServerForm_1.exe" 

pasue