SET port=16000
IF [%2] NEQ [] SET port=%2
"C:\Program Files\Godot\Godot_v4.3-stable_win64.exe" scenes\menu.tscn --headless --map=%1 --port=%port%