rgb MACRO red, green, blue
    EXITM % blue SHL 16 + green SHL 8 + red
ENDM

ShipBattleModel struct
    field dword ?
    enemy_field dword ?
    ships dword ?
    enemy_remained dword ?
    player_remained dword ?
ShipBattleModel ends

Ship struct
    s_size dword ?
    rotated byte ?
Ship ends

WndProcShipPrepare proto :HWND, :UINT, :WPARAM, :LPARAM
WndProcShipGame proto :HWND, :UINT, :WPARAM, :LPARAM
CreateShipWindow proto stdcall :HINSTANCE, :HWND, : dword
RegisterClassShipWindow proto :HINSTANCE
CreateShips proto : HINSTANCE, : HWND, : ptr ShipBattleModel
InitGame proto
FillMatrixFromField proto stdcall : HWND
MakeShotByPlayer proto stdcall : HWND, : dword, : dword
CheckWin proto stdcall : HWND