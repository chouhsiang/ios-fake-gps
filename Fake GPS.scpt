set appPath to POSIX path of (path to me)
set dirPath to do shell script "dirname " & quoted form of appPath

tell application "Terminal"
	activate
	do script "cd " & quoted form of dirPath & "; ./run_init.sh && ./run_main.sh"
end tell