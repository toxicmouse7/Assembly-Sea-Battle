;
; Модуль main.asm.
;
; Демонстрирует пример перемещения фигур на шахматной доске.
;
; Маткин Илья Александрович 01.12.2013
;

;----------------------------------------

.686
.model flat, stdcall
option casemap:none


;----------------------------------------
include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc

include GameModel.inc
include GameView.inc
include FieldInteraction.inc

include Strings.mac

AppWindowName equ <"Союзное поле">
AppEnemyWindowName equ <"Вражеское поле">
StartButton equ 201

.data

model_ptr dd ?

.data?

hIns HINSTANCE ?

HwndMainWindow HWND ?

HwndStartButton HWND ?

.const

.code

;----------------------------------------

RegisterClassMainWindow proto

CreateMainWindow proto

CreateStartButton proto

WndProcMainPreparation proto hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM
WndProcMainGame proto hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM
WndProcEnemyField proto hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM


WinMain proc stdcall hInstance:HINSTANCE, hPrevInstance:HINSTANCE, szCmdLine:PSTR, iCmdShow:DWORD

    local msg: MSG

    mov eax, [hInstance]
    mov [hIns], eax

    invoke crt_printf, $CTA("Hello, World\n\0")

    invoke CreateMainWindow
    invoke CreateStartButton
	
    .while TRUE
        invoke GetMessage, addr msg, NULL, 0, 0
            .break .if eax == 0

        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg

    .endw

    mov eax, [msg].wParam
    ret
WinMain endp

;--------------------

;
; Регистрация класса основного окна приложения
;
RegisterClassMainWindow proc

    local WndClass:WNDCLASSEX	; структура класса

    ; заполняем поля структуры
    mov WndClass.cbSize, sizeof (WNDCLASSEX)	; размер структуры класса
    mov WndClass.style, 0
    mov WndClass.lpfnWndProc, WndProcMainPreparation		; адрес оконной процедуры класса
    mov WndClass.cbClsExtra, 0
    mov WndClass.cbWndExtra, 4
    mov eax, [hIns]
    mov WndClass.hInstance, eax					; описатель приложения
    invoke LoadIcon, hIns, $CTA0("MainIcon")	; иконка приложения
    mov WndClass.hIcon, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov WndClass.hCursor, eax
    invoke GetStockObject, WHITE_BRUSH			; кисть для фона
    mov WndClass.hbrBackground, eax
    mov WndClass.lpszMenuName, NULL
    mov WndClass.lpszClassName, $CTA0(AppWindowName)	; имя класса
    invoke LoadIcon, hIns, $CTA0("MainIcon")
    mov WndClass.hIconSm, eax

    invoke RegisterClassEx, addr WndClass
    ret
RegisterClassMainWindow endp

RegisterClassEnemyWindow proc
    local WndClass:WNDCLASSEX

    mov WndClass.cbSize, sizeof (WNDCLASSEX)
    mov WndClass.style, 0
    mov WndClass.lpfnWndProc, WndProcEnemyField
    mov WndClass.cbClsExtra, 0
    mov WndClass.cbWndExtra, 4
    mov eax, [hIns]
    mov WndClass.hInstance, eax
    invoke LoadIcon, hIns, $CTA0("MainIcon")
    mov WndClass.hIcon, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov WndClass.hCursor, eax
    invoke GetStockObject, WHITE_BRUSH
    mov WndClass.hbrBackground, eax
    mov WndClass.lpszMenuName, NULL
    mov WndClass.lpszClassName, $CTA0(AppEnemyWindowName)
    invoke LoadIcon, hIns, $CTA0("MainIcon")
    mov WndClass.hIconSm, eax

    invoke RegisterClassEx, addr WndClass
    ret
RegisterClassEnemyWindow endp

;--------------------

;
; Создание основного окна приложения
;
CreateMainWindow proc uses ebx
    local dwStyle: DWORD

    mov [dwStyle], WS_OVERLAPPED
    or [dwStyle], WS_CAPTION
    or [dwStyle], WS_SYSMENU
    or [dwStyle], WS_MINIMIZEBOX
    or [dwStyle], WS_MAXIMIZEBOX

    ; регистрация класса основного окна
    invoke RegisterClassMainWindow

    ; создание окна зарегестрированного класса
    invoke CreateWindowEx, 
        WS_EX_CONTROLPARENT or WS_EX_APPWINDOW, ; расширенный стиль окна
        $CTA0(AppWindowName),	; имя зарегестрированного класса окна
        $CTA0("Морской бой"),	; заголовок окна
        [dwStyle],	; стиль окна
        10,	    ; X-координата левого верхнего угла
        10,	    ; Y-координата левого верхнего угла
        700,    ; ширина окна
        650,    ; высота окна
        NULL,   ; описатель родительского окна
        NULL,   ; описатель главного меню (для главного окна)
        [hIns], ; идентификатор приложения
        NULL
    mov [HwndMainWindow], eax
    
    .if [HwndMainWindow] == 0
        invoke MessageBox, NULL, $CTA0("Ошибка создания основного окна приложения"), NULL, MB_OK
        xor eax, eax
        ret
    .endif

    invoke ShowWindow, [HwndMainWindow], SW_SHOWNORMAL
    invoke UpdateWindow, [HwndMainWindow]
    
    
    mov eax, [HwndMainWindow]
    ret
CreateMainWindow endp

CreateEnemyWindow proc main_hwnd: HWND
    local dwStyle: DWORD
    local hwnd: HWND

    mov [dwStyle], WS_OVERLAPPED
    or [dwStyle], WS_CAPTION
    or [dwStyle], WS_SYSMENU
    or [dwStyle], WS_MINIMIZEBOX
    or [dwStyle], WS_MAXIMIZEBOX

    ; регистрация класса основного окна
    invoke RegisterClassEnemyWindow

    ; создание окна зарегестрированного класса
    invoke CreateWindowEx, 
        WS_EX_CONTROLPARENT or WS_EX_APPWINDOW, ; расширенный стиль окна
        $CTA0(AppEnemyWindowName),	; имя зарегестрированного класса окна
        $CTA0("Вражеское поле"),	; заголовок окна
        [dwStyle],	; стиль окна
        10,	    ; X-координата левого верхнего угла
        10,	    ; Y-координата левого верхнего угла
        700,    ; ширина окна
        650,    ; высота окна
        NULL,   ; описатель родительского окна
        NULL,   ; описатель главного меню (для главного окна)
        [hIns], ; идентификатор приложения
        NULL
    mov [hwnd], eax
    
    .if [hwnd] == 0
        invoke MessageBox, NULL, $CTA0("Ошибка создания второстепенного окна приложения"), NULL, MB_OK
        xor eax, eax
        ret
    .endif

    invoke ShowWindow, [hwnd], SW_SHOWNORMAL
    invoke UpdateWindow, [hwnd]
    
    invoke GetWindowLong, [main_hwnd], 0
    invoke SetWindowLong, [hwnd], 0, eax
    
    mov eax, [HwndMainWindow]
    ret
CreateEnemyWindow endp

CreateStartButton proc
    local hwnd: HWND
    local dwStyle: DWORD

    mov [dwStyle], WS_TABSTOP
    or [dwStyle], WS_VISIBLE
    or [dwStyle], WS_CHILD
    or [dwStyle], BS_DEFPUSHBUTTON


    invoke CreateWindowEx,
        0,
        $CTA0("button"),
        $CTA0("Start"),
        [dwStyle],
        550,
        10,
        40,
        40,
        [HwndMainWindow],
        StartButton,
        [hIns],
        NULL
    mov [hwnd], eax
    mov [HwndStartButton], eax

    .if [hwnd] == 0
        invoke MessageBox, NULL, $CTA0("Ошибка создания основного окна приложения"), NULL, MB_OK
        xor eax, eax
        ret
    .endif

    invoke ShowWindow, [hwnd], SW_SHOWNORMAL
    invoke UpdateWindow, [hwnd]

    invoke EnableWindow, [hwnd], FALSE

    ret
CreateStartButton endp

;--------------------

WndProcMainPreparation proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
    local pen:HPEN
    local ps:PAINTSTRUCT

    .if [iMsg] == WM_CREATE
        invoke InitGame
        push eax
        invoke SetWindowLong, [hwnd], 0, eax
        pop eax
        invoke CreateShips, [hIns], [hwnd], eax
        
        xor eax, eax
        ret
    .elseif [iMsg] == WM_DESTROY
        ; закрытие окна
        
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .elseif [iMsg] == WM_PAINT

        invoke DrawField, [HwndMainWindow]
     
    .elseif [iMsg] == WM_SIZE

        invoke InvalidateRect, [HwndMainWindow], NULL, TRUE
        invoke GetWindowLong, [hwnd], 0
        invoke ResizeShips, eax, [hwnd]

        xor eax, eax
        ret
    
    .elseif [iMsg] == WM_NOTIFY

        invoke GetWindowLong, [hwnd], 0
        invoke CheckValidity, eax, [hwnd]
        .if eax
            invoke EnableWindow, [HwndStartButton], TRUE
        .else
            invoke EnableWindow, [HwndStartButton], FALSE
        .endif

    .elseif [iMsg] == WM_MOVE

        invoke UpdateShipsPosition, [hwnd]

    .elseif [iMsg] == WM_COMMAND

        mov eax, [wParam]
        .if al == StartButton
            invoke FillMatrixFromField, [hwnd]
            invoke CreateEnemyWindow, [hwnd]
            invoke SetWindowLong, [hwnd], GWLP_WNDPROC, WndProcMainGame
            invoke GetWindowLong, [hwnd], 0
            mov ebx, [eax].ShipBattleModel.ships

            xor ecx, ecx
            .while ecx < 10
                push ecx
                invoke SetWindowLong, [ebx], GWLP_WNDPROC, WndProcShipGame
                pop ecx

                add ebx, 4
                
                inc ecx
            .endw

            xor eax, eax
            ret
        .endif

    .endif
    
    ; Необработанные сообщения направляются в функцию
    ; обработки по умолчанию.
    invoke DefWindowProc, hwnd, iMsg, wParam, lParam
    ret
WndProcMainPreparation endp

WndProcEnemyField proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
    local pen:HPEN
    local ps:PAINTSTRUCT
    local x: WORD
    local y: WORD
    local cell_x: DWORD
    local cell_y: DWORD

    .if [iMsg] == WM_CREATE
        
        xor eax, eax
        ret

    .elseif [iMsg] == WM_DESTROY
        ; закрытие окна
        
        invoke PostQuitMessage, 0
        xor eax, eax
        ret

    .elseif [iMsg] == WM_PAINT

        invoke DrawField, [hwnd]
     
    .elseif [iMsg] == WM_SIZE

        invoke InvalidateRect, [hwnd], NULL, TRUE

        xor eax, eax
        ret

    .elseif [iMsg] == WM_LBUTTONDOWN

        invoke GetWindowLong, [HwndMainWindow], 0
        mov ebx, eax

        mov ax, word ptr [lParam + 2]
        mov [y], ax

        mov ax, word ptr [lParam]
        mov [x], ax

        invoke GetCellByCoord, [hwnd], [x], [y]
        dec eax
        dec edx
        mov [cell_x], eax
        mov [cell_y], edx
        invoke MakeShotByPlayer, [hwnd], eax, edx
        .if eax == 0
            invoke DrawMiss, [hwnd], [cell_x], [cell_y]
            .while 1
                invoke MakeShotByBot, [HwndMainWindow]
                mov [cell_x], eax
                mov [cell_y], edx
                
                invoke GetPtrFrom, [ebx].ShipBattleModel.field, [cell_x], [cell_y]
                .if byte ptr [eax] == 2
                    dec [ebx].ShipBattleModel.player_remained
                    invoke DrawReached, [HwndMainWindow], [cell_x], [cell_y]
                    invoke CheckWin, [hwnd]
                    .if eax == 2
                        invoke MessageBox, NULL, $CTA0("Вы проиграли"), $CTA0("Оповещение"), MB_OK
                        invoke DestroyWindow, [hwnd]
                        invoke DestroyWindow, [HwndMainWindow]
                        xor eax, eax
                        ret
                    .endif
                .elseif sbyte ptr [eax] == -1
                    invoke DrawMiss, [HwndMainWindow], [cell_x], [cell_y]
                    .break
                .endif
            .endw
        .elseif eax == 1

            invoke DrawReached, [hwnd], [cell_x], [cell_y]
            invoke CheckWin, [hwnd]
            .if eax == 1
                invoke MessageBox, NULL, $CTA0("Вы победили"), $CTA0("Оповещение"), MB_OK
                invoke DestroyWindow, [hwnd]
                invoke DestroyWindow, [HwndMainWindow]
                xor eax, eax
                ret
            .endif

        .endif

    .endif
    
    ; Необработанные сообщения направляются в функцию
    ; обработки по умолчанию.
    invoke DefWindowProc, hwnd, iMsg, wParam, lParam
    ret
WndProcEnemyField endp

WndProcMainGame proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
    local pen:HPEN
    local ps:PAINTSTRUCT

    .if [iMsg] == WM_CREATE
        
        xor eax, eax
        ret

    .elseif [iMsg] == WM_DESTROY
        
        invoke PostQuitMessage, 0
        xor eax, eax
        ret

    .elseif [iMsg] == WM_PAINT

        invoke DrawField, [HwndMainWindow]
     
    .elseif [iMsg] == WM_SIZE

        invoke InvalidateRect, [HwndMainWindow], NULL, TRUE

        xor eax, eax
        ret

    .endif
    
    ; Необработанные сообщения направляются в функцию
    ; обработки по умолчанию.
    invoke DefWindowProc, hwnd, iMsg, wParam, lParam
    ret
WndProcMainGame endp

end
