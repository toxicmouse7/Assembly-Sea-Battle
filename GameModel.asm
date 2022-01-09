.686
.model flat, stdcall
option casemap:none

include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc
include Strings.mac
include GameModel.inc
include GameView.inc
include FieldInteraction.inc

.code

InitGame proc uses ebx esi
    local model_ptr: ptr ShipBattleModel

    invoke crt_calloc, 1, sizeof(ShipBattleModel)
    mov [model_ptr], eax
    mov esi, eax

    mov [esi].ShipBattleModel.enemy_remained, 20
    mov [esi].ShipBattleModel.player_remained, 20
    
    xor edx, edx
    mov eax, 10
    mul eax

    push eax
    invoke crt_calloc, eax, 1
    mov [esi].ShipBattleModel.field, eax
    pop eax

    invoke crt_calloc, eax, 1
    mov [esi].ShipBattleModel.enemy_field, eax

    invoke GenerateRandomEnemyField, [model_ptr]

    mov eax, [model_ptr]

    ret
InitGame endp

CreateShips proc uses ebx esi hIns: HINSTANCE, hwnd: HWND, gm_ptr: ptr ShipBattleModel
    mov esi, [gm_ptr]
    invoke crt_calloc, 10, 4
    mov [esi].ShipBattleModel.ships, eax
    mov ebx, eax

    invoke CreateShipWindow, [hIns], [hwnd], 4
    mov [ebx], eax
    invoke CreateShipWindow, [hIns], [hwnd], 3
    mov [ebx + 4], eax
    invoke CreateShipWindow, [hIns], [hwnd], 3
    mov [ebx + 8], eax
    invoke CreateShipWindow, [hIns], [hwnd], 2
    mov [ebx + 12], eax
    invoke CreateShipWindow, [hIns], [hwnd], 2
    mov [ebx + 16], eax
    invoke CreateShipWindow, [hIns], [hwnd], 2
    mov [ebx + 20], eax
    invoke CreateShipWindow, [hIns], [hwnd], 1
    mov [ebx + 24], eax
    invoke CreateShipWindow, [hIns], [hwnd], 1
    mov [ebx + 28], eax
    invoke CreateShipWindow, [hIns], [hwnd], 1
    mov [ebx + 32], eax
    invoke CreateShipWindow, [hIns], [hwnd], 1
    mov [ebx + 36], eax

    ret
CreateShips endp

RegisterClassShipWindow proc hIns:HINSTANCE

    local WndClass:WNDCLASSEX	; структура класса
    
    ;invoke CreateChessRgn, hIns

    ; заполняем поля структуры
    mov WndClass.cbSize, sizeof (WNDCLASSEX)    ; размер структуры класса
    mov WndClass.style, 0
    mov WndClass.lpfnWndProc, WndProcShipPrepare      ; адрес оконной процедуры класса
    mov WndClass.cbClsExtra, 0
    mov WndClass.cbWndExtra, 8        
    mov eax, [hIns]
    mov WndClass.hInstance, eax                 ; описатель приложения
    mov WndClass.hIcon, NULL
    invoke LoadCursor, NULL, IDC_ARROW
    mov WndClass.hCursor, eax
    mov WndClass.hbrBackground, NULL
    mov WndClass.lpszMenuName, NULL
    mov WndClass.lpszClassName, $CTA0("Ship")	; имя класса
    mov WndClass.hIconSm, NULL

    invoke RegisterClassEx, addr WndClass
    ret
RegisterClassShipWindow endp

GetShipCenter proc uses ebx hwnd:HWND, x:ptr dword, y:ptr dword

    local rect:RECT
    local parent:HWND
    local point:POINT
    local half_width: dword
    local half_height: dword
    
    ; получение расположения фигуры на экране
    invoke GetWindowRect, [hwnd], addr rect

    mov ebx, 2

    xor edx, edx
    mov eax, [rect].right
    sub eax, [rect].left
    div ebx
    mov [half_width], eax

    xor edx, edx
    mov eax, [rect].bottom
    sub eax, [rect].top
    div ebx
    mov [half_height], eax
    
    ; вычисляем координаты центра
    mov eax, [rect].left
    add eax, [half_width]
    mov [point].x, eax

    mov eax, [rect].top
    add eax, [half_height]
    mov [point].y, eax

    ; получаем описатель родительского окна    
    invoke GetParent, [hwnd]
    mov [parent], eax
    
    ; переводим координаты на экране в координаты относительно родительского окна
    invoke ScreenToClient, [parent], addr point
    
    ; возвращаем координаты центра
    mov ecx, [x]
    mov eax, [point].x
    mov [ecx], eax
    mov ecx, [y]
    mov eax, [point].y
    mov [ecx], eax
    
    ret
GetShipCenter endp

WndProcShipPrepare proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
    local ps:PAINTSTRUCT
    local win_rect: RECT
    local brush: HBRUSH
    local x: dword
    local y: dword
    local center_x: dword
    local center_y: dword
    local half_width: dword
    local half_height: dword

    .if [iMsg] == WM_CREATE
        ; создание окна
        
        xor eax, eax
        ret
    .elseif [iMsg] == WM_DESTROY
        ; закрытие окна
        
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .elseif [iMsg] == WM_PAINT

        invoke BeginPaint, [hwnd], addr [ps]
        mov [hdc], eax

        invoke CreateSolidBrush, rgb(0ADh, 0FFh, 02Fh)
        mov [brush], eax

        invoke GetClientRect, [hwnd], addr [win_rect]

        invoke FillRect, [hdc], addr [win_rect], [brush]

        invoke EndPaint, [hwnd], addr [ps]

        xor eax, eax
        ret

    .elseif [iMsg] == WM_LBUTTONDOWN
        invoke SetCapture, [hwnd]
        invoke InvalidateRect, [hwnd], NULL, TRUE

        xor eax, eax
        ret

    .elseif [iMsg] == WM_LBUTTONUP

        invoke ReleaseCapture

        invoke StickShip, [hwnd]

        invoke GetParent, [hwnd]
        invoke SendMessage, eax, WM_NOTIFY, 0, 0

    .elseif [iMsg] == WM_RBUTTONDOWN

        invoke RotateShip, [hwnd]

        invoke GetParent, [hwnd]
        invoke SendMessage, eax, WM_NOTIFY, 0, 0

    .elseif [iMsg] == WM_MOUSEMOVE

        .if [wParam] & MK_LBUTTON
            movsx eax, word ptr [lParam]
            mov [x], eax
            movsx eax, word ptr [lParam+2]
            mov [y], eax
            
            invoke GetShipCenter, [hwnd], addr [center_x], addr [center_y]
            invoke GetClientRect, [hwnd], addr [win_rect]

            mov ebx, 2

            xor edx, edx
            mov eax, [win_rect].right
            div ebx
            mov [half_width], eax

            xor edx, edx
            mov eax, [win_rect].bottom
            div ebx
            mov [half_height], eax
            

            mov eax, [x]
            sub eax, [half_width]
            add [center_x], eax
            mov eax, [y]
            sub eax, half_height
            add [center_y], eax

            invoke MoveShipByCenter, [hwnd], [center_x], [center_y], [win_rect].right, [win_rect].bottom
            
            invoke GetWindowLong, [hwnd], 4
            invoke GetWindowRect, [hwnd], eax
        .endif

        xor eax, eax
        ret

    .endif

    ; Необработанные сообщения направляются в функцию
    ; обработки по умолчанию.
    invoke DefWindowProc, hwnd, iMsg, wParam, lParam
    ret
WndProcShipPrepare endp

WndProcShipGame proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
    local ps:PAINTSTRUCT
    local win_rect: RECT
    local brush: HBRUSH

    .if [iMsg] == WM_CREATE
        ; создание окна
        
        xor eax, eax
        ret
    .elseif [iMsg] == WM_DESTROY
        ; закрытие окна
        
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .elseif [iMsg] == WM_PAINT

        invoke BeginPaint, [hwnd], addr [ps]
        mov [hdc], eax

        invoke CreateSolidBrush, rgb(0ADh, 0FFh, 02Fh)
        mov [brush], eax

        invoke GetClientRect, [hwnd], addr [win_rect]

        invoke FillRect, [hdc], addr [win_rect], [brush]

        invoke EndPaint, [hwnd], addr [ps]

    .endif

    ; Необработанные сообщения направляются в функцию
    ; обработки по умолчанию.
    invoke DefWindowProc, hwnd, iMsg, wParam, lParam
    ret
WndProcShipGame endp

CreateShipWindow proc uses ebx hIns:HINSTANCE, parent:HWND, s_size: dword

    local hwnd:HWND
    local rect:RECT
    
    invoke RegisterClassShipWindow, hIns

    invoke GetClientRect, [parent], addr [rect]
    sub [rect].right, 75
    .if s_size == 4
        mov [rect].top, 10
    .elseif s_size == 3
        mov [rect].top, 220
    .elseif s_size == 2
        mov [rect].top, 380
    .elseif s_size == 1
        mov [rect].top, 490
    .endif

    mov eax, [s_size]
    mov ebx, 50
    xor edx, edx
    mul ebx

    invoke CreateWindowEx, 0, $CTA0("Ship"), NULL, WS_OVERLAPPED or WS_CHILD or WS_CLIPSIBLINGS, [rect].right, [rect].top, 50, eax, parent, NULL, hIns, NULL
    mov [hwnd], eax
    .if ![hwnd]
        xor eax, eax
        ret
    .endif

    invoke crt_calloc, 1, sizeof(Ship)
    mov ebx, [s_size]
    mov [eax].Ship.s_size, ebx

    invoke SetWindowLong, [hwnd], 0, eax

    invoke crt_calloc, 1, sizeof(RECT)
    mov ebx, eax
    invoke SetWindowLong, [hwnd], 4, eax
    invoke GetWindowRect, [hwnd], ebx
    
    invoke ShowWindow, [hwnd], SW_SHOWNORMAL
    invoke UpdateWindow, [hwnd]

    mov eax, [hwnd]
    ret
CreateShipWindow endp

FillMatrixFromField proc hwnd: HWND
    local i: dword
    local j: dword
    local point: POINT

    mov [i], 0
    mov [j], 0

    invoke GetWindowLong, [hwnd], 0
    mov ebx, [eax].ShipBattleModel.field

    .while [i] < 10

        .while [j] < 10
            invoke GetCellCoordByID, [hwnd], [i], [j]
            invoke ChildWindowFromPoint, [hwnd], eax, edx
            
            .if eax != [hwnd]
                invoke GetPtrFrom, ebx, [i], [j]
                mov byte ptr [eax], 1
            .endif

            inc [j]
        .endw

        mov [j], 0
        inc [i]

    .endw

    ret
FillMatrixFromField endp

MakeShotByPlayer proc uses ebx hwnd: HWND, cell_x: dword, cell_y: dword
    invoke GetWindowLong, [hwnd], 0
    push eax
    mov ebx, [eax].ShipBattleModel.enemy_field

    invoke GetPtrFrom, ebx, [cell_x], [cell_y]
    pop ebx
    .if byte ptr [eax] == 1
        mov byte ptr [eax], 2
        mov eax, 1
        dec [ebx].ShipBattleModel.enemy_remained
    .elseif byte ptr [eax] == 0
        mov byte ptr [eax], -1
        xor eax, eax
    .elseif byte ptr [eax] == 2
        mov eax, [eax]
    .elseif sbyte ptr [eax] == -1
        mov eax, 2
    .endif

    ret
MakeShotByPlayer endp

ShootAt proc uses ebx field: dword, x: dword, y: dword
    invoke GetPtrFrom, [field], [x], [y]

    .if byte ptr [eax] == 1
        mov byte ptr [eax], 2
        mov eax, 1
        ret
    .elseif byte ptr [eax] == 0
        mov byte ptr [eax], -1
        xor eax, eax
        ret
    .endif

    mov ebx, eax
    xor eax, eax
    mov al, byte ptr [ebx]

    ret
ShootAt endp

TryShootAround proc field: dword, x: dword, y: dword
    local inc_x: dword
    local dec_x: dword
    local inc_y: dword
    local dec_y: dword

    mov eax, [x]
    mov [inc_x], eax
    inc [inc_x]
    mov [dec_x], eax
    dec [dec_x]

    mov eax, [y]
    mov [inc_y], eax
    inc [inc_y]
    mov [dec_y], eax
    dec [dec_y]

    .if [x] < 9
        invoke ShootAt, [field], [inc_x], [y]
        .if sbyte ptr al != -1 && sbyte ptr al != 2
            mov eax, [inc_x]
            mov edx, [y]
            ret
        .endif
    .endif
    .if [y] < 9
        invoke ShootAt, [field], [x], [inc_y]
        .if sbyte ptr al != -1 && sbyte ptr al != 2
            mov eax, [x]
            mov edx, [inc_y]
            ret
        .endif
    .endif
    .if sdword ptr [x] > 0
       invoke ShootAt, [field], [dec_x], [y]
       .if sbyte ptr al != -1 && sbyte ptr al != 2
           mov eax, [dec_x]
           mov edx, [y]
           ret
       .endif
    .endif
    .if sdword ptr [y] > 0
        invoke ShootAt, [field], [x], [dec_y]
        .if sbyte ptr al != -1 && sbyte ptr al != 2
            mov eax, [x]
            mov edx, [dec_y]
            ret
        .endif
    .endif

    mov eax, -2

    ret
TryShootAround endp

MakeShotByBot proc uses ebx hwnd: HWND
    local x: dword
    local y: dword
    local is_odd: byte
    local field: dword

    mov [x], 0
    mov [y], 0

    invoke GetWindowLong, [hwnd], 0
    mov ebx, eax
    mov eax, [eax].ShipBattleModel.field
    mov [field], eax

    mov [is_odd], 1

    .while [y] < 10
        .while [x] < 10
            invoke GetPtrFrom, [field], [x], [y]
            .if byte ptr [eax] == 0 || byte ptr [eax] == 1
                .if [is_odd]
                    invoke ShootAt, [field], [x], [y]
                    mov eax, [x]
                    mov edx, [y]
                    ret
                .else
                    neg [is_odd]
                    add [is_odd], 1
                .endif
            .elseif sbyte ptr [eax] == -1
                neg [is_odd]
                add [is_odd], 1
            .elseif byte ptr [eax] == 2
                invoke TryShootAround, [field], [x], [y]
                .if sdword ptr eax != -2
                    ret
                .else
                    neg [is_odd]
                    add [is_odd], 1
                .endif
            .endif
            inc [x]
        .endw
        mov [x], 0
        inc [y]
    .endw

    .while 1
        invoke crt_rand
        mov ebx, 10
        xor edx, edx
        div ebx
        mov [x], edx

        invoke crt_rand
        mov ebx, 10
        xor edx, edx
        div ebx
        mov [y], edx

        invoke GetPtrFrom, [field], [x], [y]
        .if byte ptr [eax] == 1
            
            mov byte ptr [eax], 2
            mov eax, [x]
            mov edx, [y]
            ret
        .endif
    .endw

    ret
MakeShotByBot endp

CheckWin proc hwnd: HWND
    invoke GetWindowLong, [hwnd], 0
    
    .if [eax].ShipBattleModel.enemy_remained == 0
        mov eax, 1
        ret
    .elseif [eax].ShipBattleModel.player_remained == 0
        mov eax, 2
        ret
    .endif

    mov eax, 0

    ret
CheckWin endp

end