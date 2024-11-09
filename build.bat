@compile_80286.c.exe < snake.asm > snake ^
	&& qemu -m 16 -fda snake ^
	|| pause