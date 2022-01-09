.686
.model flat, stdcall
option casemap:none

include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc

include GameModel.inc

.code

GetFieldWidth proc hwnd: HWND
    local win_rect: RECT

    invoke GetClientRect, [hwnd], addr [win_rect]
    add [win_rect].left, 5

    mov eax, [win_rect].right
    sub eax, [win_rect].left
    sub eax, 150

    ret
GetFieldWidth endp

GetFieldHeigth proc hwnd: HWND
    local win_rect: RECT

    invoke GetClientRect, [hwnd], addr [win_rect]

    mov eax, [win_rect].bottom
    sub eax, [win_rect].top

    ret
GetFieldHeigth endp

GetCellWidth proc uses ebx hwnd: HWND
    invoke GetFieldWidth, [hwnd]

    xor edx, edx
    mov ebx, 10
    div ebx

    ret
GetCellWidth endp

GetCellHeigth proc uses ebx hwnd: HWND
    invoke GetFieldHeigth, [hwnd]

    xor edx, edx
    mov ebx, 10
    div ebx

    ret
GetCellHeigth endp

;returns pair x, y in eax:edx
GetCellByCoord proc uses ebx hwnd: dword, x: dword, y: dword
    local w_height: dword
    local w_width: dword
    local block_w: dword
    local block_h: dword
    local cell_x: dword
    local cell_y: dword

    mov [cell_x], 0
    mov [cell_y], 0

    invoke GetFieldWidth, [hwnd]
    mov [w_width], eax

    invoke GetFieldHeigth, [hwnd]
    mov [w_height], eax

    xor edx, edx
    mov eax, [w_width]
    mov ebx, 10
    div ebx
    mov [block_w], eax

    xor edx, edx
    mov eax, [w_height]
    mov ebx, 10
    div ebx
    mov [block_h], eax

    xor ecx, ecx
    .while ecx < [x]
        add ecx, [block_w]
        inc [cell_x]
    .endw

    xor ecx, ecx
    .while ecx < [y]
        add ecx, [block_h]
        inc [cell_y]
    .endw

    mov eax, [cell_x]
    mov edx, [cell_y]

    ret
GetCellByCoord endp

GetCellCoordByID proc hwnd: HWND, x_id: dword, y_id: dword
    local c_width: dword
    local c_heigth: dword

    invoke GetCellWidth, [hwnd]
    mov [c_width], eax

    invoke GetCellHeigth, [hwnd]
    mov [c_heigth], eax

    xor edx, edx
    mov eax, [x_id]
    mov ecx, [c_width]
    mul ecx
    push eax

    xor edx, edx
    mov eax, [y_id]
    mov ecx, [c_heigth]
    mul ecx
    mov edx, eax
    pop eax

    add eax, 5

    ret
GetCellCoordByID endp

GetFieldRect proc uses ebx hwnd: HWND, rect: ptr RECT
    local f_w: dword
    local f_h: dword

    invoke GetFieldHeigth, [hwnd]
    mov [f_h], eax

    invoke GetFieldWidth, [hwnd]
    mov [f_w], eax

    assume ebx: ptr RECT
    mov ebx, [rect]
    
    invoke GetWindowRect, [hwnd], ebx

    mov eax, [ebx].left
    add eax, 5
    add eax, [f_w]
    mov [ebx].right, eax

    mov eax, [ebx].top
    add eax, 30
    add eax, [f_h]
    mov [ebx].bottom, eax

    ret
GetFieldRect endp

DrawField proc c uses ebx hwnd: HWND
    local ps: PAINTSTRUCT
    local win_rect: RECT
    local pen: HPEN
    local hdc: HDC

    invoke BeginPaint, [hwnd], addr [ps]
    mov [hdc], eax

    invoke GetClientRect, [hwnd], addr [win_rect]
    add [win_rect].left, 5

    sub [win_rect].bottom, 7
    mov eax, [win_rect].right
    sub eax, [win_rect].left
    sub eax, 150
    xor edx, edx
    mov ebx, 10
    div ebx
    mov ebx, eax

    ; создаём объект "перо" для рисования линий
    invoke CreatePen, 
        PS_SOLID,       ; задаём тип линии (сплошная)
        3,              ; толщина линии
        0 ; цвет линии
    mov [pen],eax
    invoke SelectObject, [hdc], [pen]

    xor ecx, ecx
    .while ecx != 11
        push ecx
        invoke MoveToEx, [hdc], [win_rect].left, [win_rect].top, NULL
        invoke LineTo, [hdc], [win_rect].left, [win_rect].bottom
        add [win_rect].left, ebx
        pop ecx
        inc ecx
    .endw

    invoke GetClientRect, [hwnd], addr [win_rect]
    add [win_rect].left, 5
    sub [win_rect].right, 160

    mov eax, [win_rect].bottom
    sub eax, [win_rect].top
    xor edx, edx
    mov ebx, 10
    div ebx
    mov ebx, eax

    xor ecx, ecx
    .while ecx != 11
        push ecx
        invoke MoveToEx, [hdc], [win_rect].left, [win_rect].top, NULL
        invoke LineTo, [hdc], [win_rect].right, [win_rect].top
        add [win_rect].top, ebx
        pop ecx
        inc ecx
    .endw

    invoke DeleteObject, [pen]

    invoke EndPaint, [hwnd], addr [ps]
    ret
DrawField endp

ResizeShips proc uses ebx esi gm_ptr: ptr ShipBattleModel, parent: HWND
    local b_width: dword
    local b_height: dword
    local ship_hwnd: HWND
    local s_size: dword
    local point: POINT
    local rotated: byte

    invoke GetCellWidth, [parent]
    mov [b_width], eax

    invoke GetCellHeigth, [parent]
    mov [b_height], eax

    assume ebx: ptr ShipBattleModel
    assume esi: ptr RECT
    mov ebx, [gm_ptr]

    xor ecx, ecx
    .while ecx < 10
        mov eax, [ebx].ships
        mov eax, [eax + 4 * ecx]
        mov [ship_hwnd], eax
        push ecx
        invoke GetWindowLong, [ship_hwnd], 0
        mov edx, [eax].Ship.s_size
        mov [s_size], edx
        mov dl, [eax].Ship.rotated
        mov [rotated], dl

        xor edx, edx
        mov eax, [s_size]
        .if [rotated]
            mov ecx, [b_width]
        .else
            mov ecx, [b_height]
        .endif
        mul ecx
        mov [s_size], eax

        invoke GetWindowLong, [ship_hwnd], 4
        mov esi, eax

        mov eax, [esi].top
        mov [point].y, eax
        mov eax, [esi].left
        mov [point].x, eax
        
        invoke ScreenToClient, [parent], addr [point]
        .if [rotated]
            invoke MoveWindow, [ship_hwnd], [point].x, [point].y, [s_size], [b_height], TRUE
        .else
            invoke MoveWindow, [ship_hwnd], [point].x, [point].y, [b_width], [s_size], TRUE
        .endif
        invoke GetWindowRect, [ship_hwnd], esi

        pop ecx
        inc ecx
    .endw

    ret
ResizeShips endp

IsInField proc uses ebx s_rect: ptr RECT, field_hwnd: HWND
    local f_rect: RECT

    invoke GetFieldRect, [field_hwnd], addr [f_rect]

    assume ebx: ptr RECT
    mov ebx, [s_rect]

    mov eax, [ebx].left
    .if eax < [f_rect].left
        xor eax, eax
        ret
    .endif

    mov eax, [ebx].top
    .if eax < [f_rect].top
        xor eax, eax
        ret
    .endif

    mov eax, [ebx].right
    .if eax > [f_rect].right
        xor eax, eax
        ret
    .endif

    mov eax, [ebx].bottom
    .if eax > [f_rect].bottom
        xor eax, eax
        ret
    .endif

    mov eax, 1

    ret
IsInField endp

IsInCollision proc hwnd: HWND
    local hdc: HDC
    local iClipRes: DWORD
    local rcWndClient: RECT
    local rcWndClip: RECT

    invoke GetDC, [hwnd]
    mov [hdc], eax

    invoke GetClientRect, [hwnd], addr [rcWndClient]

    invoke GetClipBox, [hdc], addr [rcWndClip]
    mov [iClipRes], eax

    invoke ReleaseDC, [hwnd], [hdc]

    .if [iClipRes] == SIMPLEREGION
        invoke EqualRect, addr [rcWndClient], addr [rcWndClip]
        .if eax
            ret
        .endif
    .endif

    xor eax, eax
    ret
IsInCollision endp

CheckRight proc uses ebx hwnd: HWND, parent: HWND, ship_rect: ptr RECT, ship_size: DWORD, cell_length: DWORD
    local point: POINT
    local cell_half_length: DWORD

    xor edx, edx
    mov eax, [cell_length]
    mov ecx, 2
    div ecx
    mov [cell_half_length], eax

    assume ebx: ptr RECT

    mov ebx, [ship_rect]

    mov eax, [ebx].right
    mov [point].x, eax
    add [point].x, 1

    mov eax, [ebx].top
    add eax, [cell_half_length]
    mov [point].y, eax

    xor ecx, ecx
    .while ecx != [ship_size]
        push ecx
        invoke WindowFromPoint, [point].x, [point].y
        pop ecx
        .if eax != [parent]
            xor eax, eax
            ret
        .endif

        mov eax, [cell_length]
        add [point].y, eax

        inc ecx
    .endw

    mov eax, 1
    ret
CheckRight endp

CheckLeft proc uses ebx hwnd: HWND, parent: HWND, ship_rect: ptr RECT, ship_size: DWORD, cell_length: DWORD
    local point: POINT
    local cell_half_length: DWORD

    xor edx, edx
    mov eax, [cell_length]
    mov ecx, 2
    div ecx
    mov [cell_half_length], eax

    assume ebx: ptr RECT

    mov ebx, [ship_rect]

    mov eax, [ebx].left
    mov [point].x, eax
    sub [point].x, 1

    mov eax, [ebx].top
    add eax, [cell_half_length]
    mov [point].y, eax

    xor ecx, ecx
    .while ecx != [ship_size]
        push ecx
        invoke WindowFromPoint, [point].x, [point].y
        pop ecx
        .if eax != [parent]
            xor eax, eax
            ret
        .endif

        mov eax, [cell_length]
        add [point].y, eax

        inc ecx
    .endw

    mov eax, 1
    ret
CheckLeft endp

CheckBottom proc uses ebx hwnd: HWND, parent: HWND, ship_rect: ptr RECT, ship_size: DWORD, cell_length: DWORD
    local point: POINT
    local cell_half_length: DWORD

    xor edx, edx
    mov eax, [cell_length]
    mov ecx, 2
    div ecx
    mov [cell_half_length], eax

    assume ebx: ptr RECT

    mov ebx, [ship_rect]

    mov eax, [ebx].left
    add eax, [cell_half_length]
    mov [point].x, eax

    mov eax, [ebx].bottom
    add eax, 1
    mov [point].y, eax

    xor ecx, ecx
    .while ecx != [ship_size]
        push ecx
        invoke WindowFromPoint, [point].x, [point].y
        pop ecx
        .if eax != [parent]
            xor eax, eax
            ret
        .endif

        mov eax, [cell_length]
        add [point].x, eax

        inc ecx
    .endw

    mov eax, 1
    ret
CheckBottom endp

MoveShipByCenter proc uses ebx hwnd:HWND, x:dword, y:dword, s_width: dword, s_height: dword
    
    mov ebx, 2

    xor edx, edx
    mov eax, [s_width]
    div ebx
    sub [x], eax

    xor edx, edx
    mov eax, [s_height]
    div ebx
    sub [y], eax

    invoke MoveWindow, [hwnd], [x], [y], [s_width], [s_height], TRUE
    
    ret
MoveShipByCenter endp

CheckTop proc uses ebx hwnd: HWND, parent: HWND, ship_rect: ptr RECT, ship_size: DWORD, cell_length: DWORD
    local point: POINT
    local cell_half_length: DWORD

    xor edx, edx
    mov eax, [cell_length]
    mov ecx, 2
    div ecx
    mov [cell_half_length], eax

    assume ebx: ptr RECT

    mov ebx, [ship_rect]

    mov eax, [ebx].left
    add eax, [cell_half_length]
    mov [point].x, eax

    mov eax, [ebx].top
    sub eax, 1
    mov [point].y, eax

    xor ecx, ecx
    .while ecx != [ship_size]
        push ecx
        invoke WindowFromPoint, [point].x, [point].y
        pop ecx
        .if eax != [parent]
            xor eax, eax
            ret
        .endif

        mov eax, [cell_length]
        add [point].x, eax

        inc ecx
    .endw

    mov eax, 1
    ret
CheckTop endp

IsHaveUndesirableNeighbors proc hwnd: HWND
    local ship_rect: RECT
    local parent: HWND
    local point: POINT
    local ship_size: dword
    local rotated: byte
    local cell_half_length: dword
    local cell_length: dword

    invoke GetParent, [hwnd]
    mov [parent], eax
    
    invoke GetWindowRect, [hwnd], addr [ship_rect]

    invoke GetWindowLong, [hwnd], 0
    mov edx, [eax].Ship.s_size
    mov [ship_size], edx
    mov dl, [eax].Ship.rotated
    mov [rotated], dl

    invoke GetCellHeigth, [hwnd]
    mov [cell_length], eax
    
    .if [rotated]
        invoke CheckRight, [hwnd], [parent], addr [ship_rect], 1, [cell_length]
    .else
        invoke CheckRight, [hwnd], [parent], addr [ship_rect], [ship_size], [cell_length]
    .endif
    .if !eax
        ret
    .endif

    .if [rotated]
        invoke CheckLeft, [hwnd], [parent], addr [ship_rect], 1, [cell_length]
    .else
        invoke CheckLeft, [hwnd], [parent], addr [ship_rect], [ship_size], [cell_length]
    .endif
    .if !eax
        ret
    .endif

    .if [rotated]
        invoke CheckTop, [hwnd], [parent], addr [ship_rect], [ship_size], [cell_length]
    .else
        invoke CheckTop, [hwnd], [parent], addr [ship_rect], 1, [cell_length]
    .endif
    .if !eax
        ret
    .endif

    .if [rotated]
        invoke CheckBottom, [hwnd], [parent], addr [ship_rect], [ship_size], [cell_length]
    .else
        invoke CheckBottom, [hwnd], [parent], addr [ship_rect], 1, [cell_length]
    .endif
    .if !eax
        ret
    .endif

    mov eax, 1

    ret
IsHaveUndesirableNeighbors endp

CheckValidity proc uses ebx esi gm_ptr: ptr ShipBattleModel, field_hwnd: HWND
    local ship_hwnd: HWND

    assume ebx: ptr ShipBattleModel
    assume esi: ptr RECT
    mov ebx, [gm_ptr]

    xor ecx, ecx
    .while ecx < 10
        mov eax, [ebx].ships
        mov eax, [eax + 4 * ecx]
        mov [ship_hwnd], eax

        push ecx
        invoke GetWindowLong, [ship_hwnd], 4
        mov esi, eax

        invoke IsInField, esi, [field_hwnd]
        .if !eax
            ret
        .endif

        invoke IsInCollision, [ship_hwnd]
        .if !eax
            ret
        .endif

        invoke IsHaveUndesirableNeighbors, [ship_hwnd]
        .if !eax
            ret
        .endif

        pop ecx

        inc ecx
    .endw

    mov eax, 1

    ret
CheckValidity endp

StickShip proc hwnd: HWND
    local parent: HWND
    local f_w: DWORD
    local f_h: DWORD
    local win_rect: RECT
    local point: POINT

    invoke GetParent, [hwnd]
    mov [parent], eax

    invoke GetFieldWidth, [parent]
    mov [f_w], eax

    invoke GetFieldHeigth, [parent]
    mov [f_h], eax

    invoke GetWindowRect, [hwnd], addr [win_rect]
    mov eax, [win_rect].top
    mov [point].y, eax
    mov eax, [win_rect].left
    mov [point].x, eax

    invoke GetClientRect, [hwnd], addr [win_rect]

    invoke ScreenToClient, [parent], addr [point]

    .if sdword ptr [point].x < 0 || sdword ptr [point].y < 0
        invoke GetWindowLong, [hwnd], 4
        invoke GetWindowRect, [hwnd], eax
        xor eax, eax
        ret
    .else
        mov eax, [f_w]
        mov edx, [f_h]
        .if [point].x > eax || [point].y > edx
            invoke GetWindowLong, [hwnd], 4
            invoke GetWindowRect, [hwnd], eax
            xor eax, eax
            ret
        .endif
    .endif
        
    invoke GetCellByCoord, [parent], [point].x, [point].y
    dec eax
    dec edx
    invoke GetCellCoordByID, [parent], eax, edx

    invoke MoveWindow, [hwnd], eax, edx, [win_rect].right, [win_rect].bottom, TRUE
    invoke GetWindowLong, [hwnd], 4
    invoke GetWindowRect, [hwnd], eax

    ret
StickShip endp

RotateShip proc uses ebx hwnd: HWND
    local parent: HWND
    local win_rect: RECT
    local point: POINT

    invoke GetParent, [hwnd]
    mov [parent], eax
    invoke GetWindowRect, [hwnd], addr [win_rect]

    mov eax, [win_rect].left
    mov [point].x, eax
    mov eax, [win_rect].top
    mov [point].y, eax

    invoke ScreenToClient, [parent], addr [point]

    invoke GetClientRect, [hwnd], addr [win_rect]
    invoke MoveWindow, [hwnd], [point].x, [point].y, [win_rect].bottom, [win_rect].right, TRUE
    invoke GetWindowLong, [hwnd], 4
    invoke GetWindowRect, [hwnd], eax

    invoke GetWindowLong, [hwnd], 0
    mov bl, [eax].Ship.rotated
    neg bl
    add bl, 1
    mov [eax].Ship.rotated, bl

    invoke GetWindowLong, [parent], 0

    invoke ResizeShips, eax, [parent]
    
    ret
RotateShip endp

UpdateShipsPosition proc uses ebx hwnd: HWND
    local ship_hwnd: HWND
    assume ebx: ptr ShipBattleModel

    invoke GetWindowLong, [hwnd], 0
    mov ebx, eax

    xor ecx, ecx
    .while ecx < 10
        mov eax, [ebx].ships
        mov eax, [eax + 4 * ecx]
        mov [ship_hwnd], eax

        push ecx
        invoke GetWindowLong, [ship_hwnd], 4
        invoke GetWindowRect, [ship_hwnd], eax
        pop ecx

        inc ecx
    .endw

    ret
UpdateShipsPosition endp

DrawMiss proc hwnd: HWND, cell_x: dword, cell_y: dword
    local pen: HPEN
    local hdc: HDC
    local right: dword
    local left: dword
    local top: dword
    local bottom: dword

    invoke GetDC, [hwnd]
    mov [hdc], eax

    invoke GetCellCoordByID, [hwnd], [cell_x], [cell_y]
    mov [left], eax
    mov [right], eax
    mov [top], edx
    mov [bottom], edx

    ; создаём объект "перо" для рисования линий
    invoke CreatePen, 
        PS_SOLID,       ; задаём тип линии (сплошная)
        5,              ; толщина линии
        rgb(255, 0, 0) ; цвет линии
    mov [pen], eax
    invoke SelectObject, [hdc], [pen]

    invoke GetCellWidth, [hwnd]
    shr eax, 1
    add [right], eax
    shr eax, 1
    add [left], eax
    add [right], eax

    invoke GetCellHeigth, [hwnd]
    shr eax, 1
    add [bottom], eax
    shr eax, 1
    add [top], eax
    add [bottom], eax

    invoke Ellipse, [hdc], [left], [top], [right], [bottom]

    invoke DeleteObject, [pen]

    invoke ReleaseDC, [hwnd], [hdc]

    ret
DrawMiss endp

DrawReached proc hwnd: HWND, cell_x: dword, cell_y: dword
    local pen: HPEN
    local hdc: HDC
    local right: dword
    local left: dword
    local top: dword
    local bottom: dword

    invoke GetDC, [hwnd]
    mov [hdc], eax

    invoke GetCellCoordByID, [hwnd], [cell_x], [cell_y]
    mov [left], eax
    mov [right], eax
    mov [top], edx
    mov [bottom], edx

    ; создаём объект "перо" для рисования линий
    invoke CreatePen, 
        PS_SOLID,       ; задаём тип линии (сплошная)
        5,              ; толщина линии
        rgb(0, 0, 255) ; цвет линии
    mov [pen], eax
    invoke SelectObject, [hdc], [pen]

    invoke GetCellWidth, [hwnd]
    add [right], eax

    invoke GetCellHeigth, [hwnd]
    add [bottom], eax

    invoke MoveToEx, [hdc], [left], [top], NULL
    invoke LineTo, [hdc], [right], [bottom]

    invoke MoveToEx, [hdc], [right], [top], NULL
    invoke LineTo, [hdc], [left], [bottom]

    invoke DeleteObject, [pen]

    invoke ReleaseDC, [hwnd], [hdc]

    ret
DrawReached endp

end