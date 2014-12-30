@echo ============±àÒë·þÎñÆ÷============
@set OutPutDir=..\..\Product

@del %OutPutDir%\*.lua /s /q>null
@del null

@xcopy *.lua %OutPutDir%\ /s /q /y

@for /f "delims=" %%a  in ('dir %OutPutDir%\*.lua /b /a /s') do @..\..\buildTool\luajit\luajit.exe -bg %%a %%a