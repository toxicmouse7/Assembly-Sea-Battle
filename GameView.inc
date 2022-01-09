DrawField proto c : HWND
GetFieldWidth proto stdcall : HWND
GetFieldHeigth proto stdcall : HWND
GetCellByCoord proto stdcall : HWND, : dword, : dword
ResizeShips proto stdcall : ptr ShipBattleModel, : HWND
GetCellCoordByID proto stdcall : HWND, : dword, : dword
StickShip proto stdcall : HWND
RotateShip proto stdcall : HWND
CheckValidity proto stdcall : ptr ShipBattleModel, : HWND
UpdateShipsPosition proto stdcall : HWND
MoveShipByCenter proto stdcall : HWND, : dword, : dword, : dword, : dword
DrawMiss proto stdcall : HWND, : dword, : dword
DrawReached proto stdcall : HWND, : dword, : dword
MakeShotByBot proto stdcall : HWND