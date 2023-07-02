.model small
.stack 256H
.data

;допиливание карается законом


;buf db 128(?);массив, в котором будут данные для записи в новый файл
filesize dw 150;размер считываемых данных (в этом случае - 512)

path db  'test42.txt',0
handle dw ?

len db 0
msg00 db 10, 13, 10, 13, '0. Register, 1. Login $' 
msg0 db 'Register: ', '$'
msg1 db 10, 13, 'Login: $'
msg10 db 10, 13, '$' 
msg2 db 10, 13, 'Correct password $'
msg3 db 10, 13,'Wrong password!', 7, 13, 10, '$'
msg4 db 10, 13, 'Enter login: $' 
msg5 db 10, 13, 'Enter password: $' 
ent db 13, 10, '$'
log_check db 25 dup('$'),0
pass db 15 dup('$'),0
pass_check db 15 dup('$'),0 
tmp db 20 dup('$')
log db 25 dup('$') ,0

cons db 4

len1 db 0
f db 10 dup('$')
f1 db 0
f2 db 0
databuf db 200('$'),0;массив, в который будут записаны считываемые данные


 
.code

buflen proc
	push si
	mov si, 0
	dec si
	buflen0: inc si
		cmp databuf[si], '~'
		jne buflen0
	mov filesize, si
	inc filesize
	pop si
	

buflen endp

crypt proc; тут шифруем
	push cx
	push bx
	push di
	mov cl, [si+1]
	lp0:
		lea di, log
	lp1:
		cmp byte ptr[di+2], '$'
		je lp0
		mov bl, byte ptr[di+2]
		mov al, byte ptr[si+2]
		xor al, bl
		mov byte ptr[si+2], al
		inc si
		inc di
		loop lp1
	mov byte ptr[si+2], '$'
	pop di
	pop bx
	pop cx
	ret
crypt endp

crypt1 proc; тут шифруем
	push cx
	push bx
	push di
	mov cl, [si+1]
	lp00:
		lea di, log_check
	lp11:
		cmp byte ptr[di+2], '$'
		je lp00
		mov bl, byte ptr[di+2]
		mov al, byte ptr[si+2]
		xor al, bl
		mov byte ptr[si+2], al
		inc si
		inc di
		loop lp11
	mov byte ptr[si+2], '$'
	pop di
	pop bx
	pop cx
	ret
crypt1 endp

reg proc ;     Ввод пароля и запись его в 
	mov ah, 9
    lea dx, msg4
    int 21H
	
	lea dx, log
	mov ah, 0ah
	int 21h;тут мы вводим строку с консоли
	
	
	
	mov AH, 3fh ; функция чтения из файла
	mov al, 0
    mov BX, handle
    mov DX, offset databuf ; прочитанное в buf
    mov cx, filesize
    int 21h;
	
	lea di, databuf

	dec di
	dio: inc di
	cmp byte ptr[di],0
	je stat
	cmp byte ptr[di],'~'
	je stat
	jmp dio
	
	
	stat:
	cmp f2, 0
	jne skip0
	dec di
	skip0:
	mov f2, 1
	mov bx,handle
	mov ah,3eh;номер функции закрытия файла
	int 21h; закрываем файл, 
	mov AH, 3dh ; функция открытия файла
    mov AL, 2
    mov DX, offset path
    int 21h;открывааааем пидора
    mov handle, ax
	
	
	lea si, log
	;lea di, databuf
	copy: 
	;mov al, byte ptr[si] 
	mov bl, byte ptr[si+2]
	cmp bl, '$'
	je reg0
	
	;cmp byte ptr[di], '$'
	;jne skip
	;inc di
	
	skip:
	mov byte ptr[di], bl
	inc si
	inc di
	jmp copy
	
	
	reg0:
	mov byte ptr[di], ' '
	inc di
	
	xor ax, ax
	xor bx, bx
	mov ah, 9
    lea dx, msg5
    int 21H
	
	lea dx, pass
	mov ah, 0ah
	int 21h;тут мы вводим строку с консоли
	lea si, pass
	
	
	
	call crypt;тут ее криптуем
	;тут запись пароля в файл
	
	lea si, pass
	copy1: 
	;mov al, byte ptr[si] 
	mov bl, byte ptr[si+2]
	cmp bl, '$'
	je reg1
	mov byte ptr[di], bl
	inc si
	inc di
	jmp copy1
	
	reg1:
	mov byte ptr[di], '$'
	mov byte ptr[di+1], '~'
	
	
	
	lea si, pass;кидаем адресс записанного пароля в si
	;mov al, [si+1]; во втором байте строки лежит длинна строки, кидаем в ал
	;mov filesize, al; помещаем длину строки в кол-во считываемых данных
	call buflen
	mov ah,40h
	mov bx,handle;хендл указывает на файл
	mov cx,filesize
	mov dx,offset databuf
	add dx, 0; первые два байта содержат инфу о строке, они нам не нужны
	int 21h
	
    ret
reg endp

login proc ;     Ввод пароля и запись его в pass_check
	mov ah, 9
    lea dx, msg4
    int 21H
	
	lea dx, log_check
	mov ah, 0ah
	int 21h;вводим строку
	
	mov ah, 9
    lea dx, msg5
    int 21H
	
    lea dx, pass_check
	mov ah, 0ah
	int 21h;вводим строку
	lea si, pass_check
	call crypt1; криптуем
    ret
login endp
 
compare proc; сравнение пароля	
	lea si, pass_check;кидаем адресс записанного пароля в si
	;mov al, [si+1]; во втором байте строки лежит длинна строки, кидаем в ал
	;mov filesize, al; помещаем длину строки в кол-во считываемых данных
	
	mov AH, 3fh ; функция чтения из файла
	mov al, 0
    mov BX, handle
    mov DX, offset databuf ; прочитанное в buf
    mov cx, filesize
    int 21h; считываем из файла в tmp строку размера filesize
	
	
	;mov al, filesize
	;lea si, pass_check
	;mov bl, [si+1]
	;cmp al, bl
	;jne c3;тут сравнили длины строк, если не равны, то пароли разные
	
	lea di, databuf
	
	
	;mov bx, 0
	;viv:
	;mov dl, byte ptr[di+bx]
	;mov ah,02h
	;int 21h
	;inc bx
	;cmp bx, 6
	;jne viv
	cmp0:lea si, log_check;кидаем адресс записанного пароля в si
	mov al, byte ptr[si+2]
	dec di
	
	cmp1: inc di
	cmp byte ptr[di], 0
	je c3
	cmp al, byte ptr[di]
	jne cmp3
	
	cmp2:inc si
	inc di
	mov bl, byte ptr[di]
	cmp bl, 0
	je c3
	mov al, byte ptr[si+2]
	cmp al, '$'
	je c0
	cmp al, byte ptr[di]
	je cmp2
	cmp al, byte ptr[di]
	jne cmp0
	
	cmp3:inc di
	cmp byte ptr[di], '0'
	je c3
	cmp byte ptr[di], '$'
	jne cmp3
	cmp byte ptr[di], '$'
	je cmp2
	
	
	
	c0:
	inc di
	;xor ah, ah
	;mov dl, byte ptr[si+2]
	;mov ah,02h
	;int 21h
	;xor ah, ah
	
	lea si, pass_check
	mov cx,filesize
cc:
    mov al, byte ptr[di]
    mov bl, byte ptr [si+2]
	cmp al, '$'
	je c1;если дошли в пароле до доллара - пароли совпадает
    cmp al, bl
    jne c3;если символы не совпали - выходим
	inc si
	inc di
    jmp cc
c1: 
	xor al, al
    mov ah, 9     ; если правильный
    lea dx, msg2
    int 21h
    mov cons, 5
	mov f1, 0
    ret
c3:         
	mov ah, 9
    lea dx, msg3
    int 21h; если неправильный
    mov ah, 9
    lea dx, ent
    Int 21H  
	mov f1, 1
    ret 
endp compare
 
start:
    mov ax, @data
    mov ds,ax
	
	mov cx,0
	mov al,1
	mov ah,3ch;номер функции для создания файла
	mov dx,offset path	;устанавливаем адрес к файлу
	int 21h; создаем файл
	mov handle,ax; записываем данные о файле в хендл 
	
	vibor:
	
	mov ah, 9
    lea dx, msg00
    int 21H
	
	lea dx, f
	mov ah, 0ah
	int 21h;тут мы вводим строку с консоли
	
	lea di, f
	add di, 2
	cmp byte ptr[di], '1'
	je logi
	
	mov AH, 3dh ; функция открытия файла
    mov AL, 0
	
    mov DX, offset path
    int 21h;открывааааем пидора
    mov handle, ax
	
	
	
	mov ah, 9    
    lea dx, msg10
    int 21h
	
	call reg; регаемся
	
	mov bx,handle
	mov ah,3eh;номер функции закрытия файла
	int 21h; закрываем файл, чтобы потом открыть, ибо этот пидр не хотел иначе и считывать и записывать в файл
	
	jmp vibor
	
	logi:
	mov AH, 3dh ; функция открытия файла
    mov AL, 0
    mov DX, offset path
    int 21h;открывааааем пидора
    mov handle, ax
	
	mov ah, 9    
    lea dx, msg10
    int 21h
	
	
cbb:    

    call login;логинимся
	
    call compare;сравниваем с паролем из файла
	
	dec cons
	cmp cons, 0;это кол-во попыток введения файла
    je en; если попытки закончились - посъебам
	
	cmp f1, 0
	jne cbb
	
    jmp vibor	
    mov ah,2
    mov dl,7
    int 21h
 
	
en: 

	mov cons, 5
    mov ah, 4ch
    int 21H
 
end start