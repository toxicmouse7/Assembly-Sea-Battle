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

PlaceValueAt proc uses ebx field: dword, x: dword, y: dword, val: byte
    xor edx, edx
    mov ebx, 10
    mov eax, [y]
    mul ebx
    add eax, [field]
    add eax, [x]
    mov bl, [val]
    mov byte ptr [eax], bl

    ret
PlaceValueAt endp

GetPtrFrom proc uses ebx field: dword, x: dword, y: dword
    xor edx, edx
    mov ebx, 10
    mov eax, [y]
    mul ebx
    add eax, [field]
    add eax, [x]

    ret
GetPtrFrom endp

IsShipRangeValid proc uses ebx s_size: dword, x: dword, y: dword, field: dword, direction: byte
    local dec_s_size: dword
    mov eax, [s_size]
    dec eax
    mov [dec_s_size], eax

    xor ecx, ecx
    .while ecx < [s_size]
        .if [direction] == 0
            mov eax, [x]
            add eax, [dec_s_size]
            .if eax < 10
                xor edx, edx
                mov ebx, 10
                mov eax, [y]
                mul ebx
                add eax, [field]
                add eax, [x]
                add eax, ecx

                .if byte ptr [eax]
                    mov eax, 0
                    ret
                .endif
            .else
                mov eax, 0
                ret
            .endif
        .else
            mov eax, [y]
            add eax, [dec_s_size]
            .if eax < 10
                xor edx, edx
                mov ebx, 10
                mov eax, [y]
                add eax, ecx
                mul ebx
                add eax, [field]
                add eax, [x]

                .if byte ptr [eax]
                    mov eax, 0
                    ret
                .endif
            .else
                mov eax, 0
                ret
            .endif
        .endif
        inc ecx
    .endw

    mov eax, 1

    ret
IsShipRangeValid endp

PlaceShip proc uses ebx s_size: dword, x: dword, y: dword, field: dword, direction: byte
    xor ecx, ecx
    .while ecx < [s_size]
        .if [direction] == 0
            xor edx, edx
            mov ebx, 10
            mov eax, [y]
            mul ebx
            add eax, [field]
            add eax, [x]
            add eax, ecx
            mov byte ptr [eax], 1
        .else
            xor edx, edx
            mov ebx, 10
            mov eax, [y]
            add eax, ecx
            mul ebx
            add eax, [field]
            add eax, [x]
            mov byte ptr [eax], 1
        .endif

        inc ecx
    .endw

    ret
PlaceShip endp

SurroundShip proc uses ebx s_size: dword, x: dword, y: dword, field: dword, direction: byte
    local dec_y: dword
    local inc_y: dword
    local dec_x: dword
    local inc_x: dword

    mov eax, [y]
    mov [dec_y], eax
    mov [inc_y], eax
    dec [dec_y]
    inc [inc_y]

    mov eax, [x]
    mov [dec_x], eax
    mov [inc_x], eax
    dec [dec_x]
    inc [inc_x]

    xor ecx, ecx
    .while ecx < [s_size]
        .if [direction] == 0
            .if [dec_y] >= 0
                push ecx
                mov eax, [x]
                add eax, ecx
                invoke PlaceValueAt, [field], eax, [dec_y], 2
                pop ecx
            .endif

            .if [inc_y] < 10
                push ecx
                mov eax, [x]
                add eax, ecx
                invoke PlaceValueAt, [field], eax, [inc_y], 2
                pop ecx
            .endif
        .else
            .if [dec_x] >= 0
                push ecx
                mov eax, [y]
                add eax, ecx
                invoke PlaceValueAt, [field], [dec_x], eax, 2
                pop ecx
            .endif

            .if [inc_x] < 10
                push ecx
                mov eax, [y]
                add eax, ecx
                invoke PlaceValueAt, [field], [inc_x], eax, 2
                pop ecx
            .endif
        .endif

        inc ecx
    .endw

    .if [direction] == 0
            .if [dec_x] >= 0
                push ecx
                invoke PlaceValueAt, [field], [dec_x], [y], 2
                pop ecx
            .endif

            mov eax, [x]
            add eax, [s_size]
            .if eax < 10
                push ecx
                invoke PlaceValueAt, [field], eax, [y], 2
                pop ecx
            .endif
        .else
            .if [dec_y] >= 0
                push ecx
                invoke PlaceValueAt, [field], [x], [dec_y], 2
                pop ecx
            .endif

            mov eax, [y]
            add eax, [s_size]
            .if eax < 10
                push ecx
                invoke PlaceValueAt, [field], [x], eax, 2
                pop ecx
            .endif
        .endif

    ret
SurroundShip endp

EraseShipBorders proc uses ebx field: dword
    local i: dword
    local j: dword

    mov [i], 0
    mov [j], 0

    .while [i] < 10
        .while [j] < 10
            invoke GetPtrFrom, [field], [i], [j]
            .if byte ptr [eax] == 2
                invoke PlaceValueAt, [field], [i], [j], 0
            .endif
            inc [j]
        .endw

        mov [j], 0
        inc [i]
    .endw

    ret
EraseShipBorders endp

GenerateRandomEnemyField proc uses ebx game_model: ptr ShipBattleModel
    local ships[10]: byte
    local x: dword
    local y: dword
    local direction: byte

    mov ebx, [game_model]
    mov ebx, [ebx].ShipBattleModel.enemy_field

    mov ships[0], 4
    mov ships[1], 3
    mov ships[2], 3
    mov ships[3], 2
    mov ships[4], 2
    mov ships[5], 2
    mov ships[6], 1
    mov ships[7], 1
    mov ships[8], 1
    mov ships[9], 1

    xor ecx, ecx
    .while ecx < 10
        .while 1
            push ecx
            invoke crt_rand
            xor edx, edx
            mov ecx, 10
            div ecx
            mov eax, edx
            mov [x], eax

            invoke crt_rand
            xor edx, edx
            mov ecx, 10
            div ecx
            mov eax, edx
            mov [y], eax

            invoke GetPtrFrom, ebx, [x], [y]
            pop ecx

            .if byte ptr [eax] == 0
                push ecx
                invoke crt_rand
                xor edx, edx
                mov ecx, 2
                div ecx
                mov eax, edx
                mov [direction], al
                pop ecx

                push ecx
                invoke IsShipRangeValid, ships[ecx], [x], [y], ebx, [direction]
                pop ecx

                .if eax
                    push ecx
                    invoke PlaceShip, ships[ecx], [x], [y], ebx, [direction]
                    pop ecx
                    push ecx
                    invoke SurroundShip, ships[ecx], [x], [y], ebx, [direction]
                    pop ecx
                    inc ecx
                    .break
                .endif
            .endif
        .endw
    .endw

    invoke EraseShipBorders, ebx

    ret
GenerateRandomEnemyField endp

end