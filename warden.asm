;======================EXTERNS==================================================
extern	__imp__GetStdHandle@4
extern	__imp__SetConsoleMode@8

extern	__imp__SetConsoleCursorPosition@8
extern	__imp__WriteConsoleA@20
extern	__imp__wsprintfA

extern	__imp__Sleep@4
extern	__imp__GetAsyncKeyState@4

extern	__imp__ExitProcess@4
;=======================SECTION BSS=============================================
section .bss
	written		resb 1							;number of chars written after WriteConsoleA
	buffer		resb 255
	stdin		resd 1							;STD_INPUT_HANDLE
	stdout		resd 1							;STD_OUTPUT_HANDLE
	console_coord	resd 1							;coord for cursor

	cur_lvl		resd 1
	cur_exp		resd 1
	mb_exp		resd 1
	lvl_in_a_row	resd 1
	need_exp_to_lvl	resd 1
	won_num		resd 1
	retreat		resd 1							;FLAG - comparing on pressing Q in battle

	stat_atk	resd 1
	stat_dex	resd 1
	stat_def	resd 1
	stat_sta	resd 1
	stat_acc	resd 1

	e_stat_atk	resd 1
	e_stat_dex	resd 1
	e_stat_def	resd 1
	e_stat_sta	resd 1
	e_stat_acc	resd 1

	stage_lvl	resd 1

	h_cur_health	resd 1							;hero's health
	e_cur_health	resd 1							;enemy's health
;=======================MAIN CODE SECTION=======================================
section .text
	global	_main
;-------------------------------------------------------------------------------
_main:
	call	init_stdin_stdout
	call	set_startup_features
	call	set_enemy_startup_features

	call	init_main_window
	jmp	main_window_loop
;-------------------------------------------------------------------------------
init_stdin_stdout:

	push dword -10
	call [__imp__GetStdHandle@4]
	mov [stdin], eax

	push dword 8h
	push dword [stdin]
	call [__imp__SetConsoleMode@8]

	push dword -11
	call [__imp__GetStdHandle@4]
	mov [stdout], eax

	ret
;-------------------------------------------------------------------------------
start_battle:
	mov	[stage_lvl], esi

	call	set_enemy_setting
	call	init_fight_scene

	mov	ecx, [stat_sta]
	imul	ecx, 10
	mov	[h_cur_health], ecx

	mov	ecx, [e_stat_sta]
	imul	ecx, 10
	mov	[e_cur_health], ecx

	call	h_healthbar
	call	e_healthbar

	push	600
	call	[__imp__Sleep@4]
fight_main_loop:
;---------------------------------=HERO ATTACK=---------------------------------
	xor	eax, eax							;set fight at pause
	push	eax
	call	combat_log

	push	150
	call	[__imp__Sleep@4]

	call	rand_percent
	mov	eax, [e_stat_dex]
	mov	ecx, [e_stat_def]
	mov	ebx, [stat_atk]
	sub	ecx, ebx
	cmp	ecx, 0
	 jle	enemy_not_grow_chance_dodge
	add	eax, ecx
	enemy_not_grow_chance_dodge:
	cmp	edx, eax
	 jl	enemy_dodged

	call	rand_percent
	mov	eax, [stat_atk]
	mov	esi, [stat_acc]
	cmp	edx, esi
	 jge	hero_dmg_non_critical

	imul	eax, 2
	
	pushad
	mov	ebx, 5								;set critical hero damage
	push	ebx
	call	combat_log
	popad
	jmp	hero_dmg_normal
hero_dmg_non_critical:
	pushad
	mov	ebx, 1								;set normal hero damage
	push	ebx
	call	combat_log
	popad
hero_dmg_normal:
	mov	ebx, [e_stat_def]
	sub	eax, ebx
	cmp	eax, 1
	 jg	h_dmg_grower_than_2
	mov	eax, 2
	h_dmg_grower_than_2:
	mov	ebx, [e_cur_health]
	sub	ebx, eax
	mov	[e_cur_health], ebx

	cmp	ebx, 1
	 jl	fight_win
	jmp	enemy_not_dodged
enemy_dodged:
	mov	eax, 3								;set evasion for enemy
	push	eax
	call	combat_log
enemy_not_dodged:
	call	e_healthbar

	push	150
	call	[__imp__Sleep@4]
;----------------------------------ENEMY_ATACK=---------------------------------
	xor	eax, eax							;set fight at pause
	push	eax
	call	combat_log

	push	150
	call	[__imp__Sleep@4]

	call	rand_percent
	mov	eax, [stat_dex]
	mov	ecx, [stat_def]
	mov	ebx, [e_stat_atk]
	sub	ecx, ebx
	cmp	ecx, 0
	 jle	hero_not_grow_chance_dodge
	add	eax, ecx
	hero_not_grow_chance_dodge:
	cmp	edx, eax
	 jl	hero_dodged

	call	rand_percent
	mov	eax, [e_stat_atk]
	mov	esi, [e_stat_acc]
	cmp	edx, esi
	 jge	enemy_dmg_normal
	imul	eax, 2

	pushad
	mov	ebx, 6								;set critical enemy damage
	push	ebx
	call	combat_log
	popad
	jmp	enemy_dmg_non_critical
enemy_dmg_normal:
	pushad
	mov	ebx, 2								;set normal enemy damage
	push	ebx
	call	combat_log
	popad
enemy_dmg_non_critical:
	mov	ebx, [stat_def]
	sub	eax, ebx
	cmp	eax, 1
	 jg	e_dmg_grower_than_2
	mov	eax, 2
	e_dmg_grower_than_2:
	mov	ebx, [h_cur_health]
	sub	ebx, eax
	mov	[h_cur_health], ebx

	cmp	ebx, 1
	 jl	game_over
	jmp	hero_not_dodged
hero_dodged:

	mov	eax, 4								;set evasion for hero
	push	eax
	call	combat_log
hero_not_dodged:
	call	h_healthbar

	push	150
	call	[__imp__Sleep@4]

	push	51h								;compare on press Quit/Retreat
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	 je	retreat_fight
	jmp	fight_main_loop
;-------------------------------------------------------------------------------
retreat_fight:
	mov	eax, [retreat]
	add	eax, 1
	mov	[retreat], eax
	call	battle_over_clrscr
	call	init_main_window
	jmp	main_window_loop
;-------------------------------------------------------------------------------
combat_log:
	xor	ax, ax
	add	ax, 17
	xor	cx, cx
	add	cx, 5
	call	move_cursor

	mov	bx, 5
	pop	edx								;ret address
	pop	esi								;num of log
	mov	edi, [stage_lvl]						;compare on boss lvl
	xor	ecx, ecx
	cmp	edi, 10
	 je	combat_boss_drow
combat_drow:
	pushad
	cmp	esi, 0
	 je	set_pause
	cmp	esi, 1
	 je	set_norm_hit
	cmp	esi, 2
	 je	set_norm_dmg
	cmp	esi, 3
	 je	set_miss
	cmp	esi, 4
	 je	set_dodge
	cmp	esi, 5
	 je	set_h_crit
	cmp	esi, 6
	 je	set_e_crit

set_pause:
	cmp	ecx, 0
	 je	print_pause_01
	cmp	ecx, 1
	 je	print_pause_02
	cmp	ecx, 2
	 je	print_pause_03
	cmp	ecx, 3
	 je	print_pause_04
	cmp	ecx, 4
	 je	print_pause_05
	cmp	ecx, 5
	 je	print_pause_06
	cmp	ecx, 6
	 je	print_pause_07
	cmp	ecx, 7
	 je	print_pause_08
	cmp	ecx, 8
	 je	print_pause_09
	cmp	ecx, 9
	 je	print_pause_10

	print_pause_01:
	push	sword_pause_01
	jmp	end_set_combat
	print_pause_02:
	push	sword_pause_02
	jmp	end_set_combat
	print_pause_03:
	push	sword_pause_03
	jmp	end_set_combat
	print_pause_04:
	push	sword_pause_04
	jmp	end_set_combat
	print_pause_05:
	push	sword_pause_05
	jmp	end_set_combat
	print_pause_06:
	push	sword_pause_06
	jmp	end_set_combat
	print_pause_07:
	push	sword_pause_07
	jmp	end_set_combat
	print_pause_08:
	push	sword_pause_08
	jmp	end_set_combat
	print_pause_09:
	push	sword_pause_09
	jmp	end_set_combat
	print_pause_10:
	push	sword_pause_10
	jmp	end_set_combat
set_norm_hit:
	cmp	ecx, 0
	 je	print_n_h_01
	cmp	ecx, 1
	 je	print_n_h_02
	cmp	ecx, 2
	 je	print_n_h_03
	cmp	ecx, 3
	 je	print_n_h_04
	cmp	ecx, 4
	 je	print_n_h_05
	cmp	ecx, 5
	 je	print_n_h_06
	cmp	ecx, 6
	 je	print_n_h_07
	cmp	ecx, 7
	 je	print_n_h_08
	cmp	ecx, 8
	 je	print_n_h_09
	cmp	ecx, 9
	 je	print_n_h_10

	print_n_h_01:
	push	sword_n_h_01
	jmp	end_set_combat
	print_n_h_02:
	push	sword_n_h_02
	jmp	end_set_combat
	print_n_h_03:
	push	sword_n_h_03
	jmp	end_set_combat
	print_n_h_04:
	push	sword_n_h_04
	jmp	end_set_combat
	print_n_h_05:
	push	sword_n_h_05
	jmp	end_set_combat
	print_n_h_06:
	push	sword_n_h_06
	jmp	end_set_combat
	print_n_h_07:
	push	sword_n_h_07
	jmp	end_set_combat
	print_n_h_08:
	push	sword_n_h_08
	jmp	end_set_combat
	print_n_h_09:
	push	sword_n_h_09
	jmp	end_set_combat
	print_n_h_10:
	push	sword_n_h_10
	jmp	end_set_combat
set_norm_dmg:
	cmp	ecx, 0
	 je	print_n_e_01
	cmp	ecx, 1
	 je	print_n_e_02
	cmp	ecx, 2
	 je	print_n_e_03
	cmp	ecx, 3
	 je	print_n_e_04
	cmp	ecx, 4
	 je	print_n_e_05
	cmp	ecx, 5
	 je	print_n_e_06
	cmp	ecx, 6
	 je	print_n_e_07
	cmp	ecx, 7
	 je	print_n_e_08
	cmp	ecx, 8
	 je	print_n_e_09
	cmp	ecx, 9
	 je	print_n_e_10

	print_n_e_01:
	push	sword_n_e_01
	jmp	end_set_combat
	print_n_e_02:
	push	sword_n_e_02
	jmp	end_set_combat
	print_n_e_03:
	push	sword_n_e_03
	jmp	end_set_combat
	print_n_e_04:
	push	sword_n_e_04
	jmp	end_set_combat
	print_n_e_05:
	push	sword_n_e_05
	jmp	end_set_combat
	print_n_e_06:
	push	sword_n_e_06
	jmp	end_set_combat
	print_n_e_07:
	push	sword_n_e_07
	jmp	end_set_combat
	print_n_e_08:
	push	sword_n_e_08
	jmp	end_set_combat
	print_n_e_09:
	push	sword_n_e_09
	jmp	end_set_combat
	print_n_e_10:
	push	sword_n_e_10
	jmp	end_set_combat
set_miss:
	cmp	ecx, 0
	 je	print_miss_01
	cmp	ecx, 1
	 je	print_miss_02
	cmp	ecx, 2
	 je	print_miss_03
	cmp	ecx, 3
	 je	print_miss_04
	cmp	ecx, 4
	 je	print_miss_05
	cmp	ecx, 5
	 je	print_miss_06
	cmp	ecx, 6
	 je	print_miss_07
	cmp	ecx, 7
	 je	print_miss_08
	cmp	ecx, 8
	 je	print_miss_09
	cmp	ecx, 9
	 je	print_miss_10

	print_miss_01:
	push	sword_miss_01
	jmp	end_set_combat
	print_miss_02:
	push	sword_miss_02
	jmp	end_set_combat
	print_miss_03:
	push	sword_miss_03
	jmp	end_set_combat
	print_miss_04:
	push	sword_miss_04
	jmp	end_set_combat
	print_miss_05:
	push	sword_miss_05
	jmp	end_set_combat
	print_miss_06:
	push	sword_miss_06
	jmp	end_set_combat
	print_miss_07:
	push	sword_miss_07
	jmp	end_set_combat
	print_miss_08:
	push	sword_miss_08
	jmp	end_set_combat
	print_miss_09:
	push	sword_miss_09
	jmp	end_set_combat
	print_miss_10:
	push	sword_miss_10
	jmp	end_set_combat
set_dodge:
	cmp	ecx, 0
	 je	print_dodge_01
	cmp	ecx, 1
	 je	print_dodge_02
	cmp	ecx, 2
	 je	print_dodge_03
	cmp	ecx, 3
	 je	print_dodge_04
	cmp	ecx, 4
	 je	print_dodge_05
	cmp	ecx, 5
	 je	print_dodge_06
	cmp	ecx, 6
	 je	print_dodge_07
	cmp	ecx, 7
	 je	print_dodge_08
	cmp	ecx, 8
	 je	print_dodge_09
	cmp	ecx, 9
	 je	print_dodge_10

	print_dodge_01:
	push	sword_dodge_01
	jmp	end_set_combat
	print_dodge_02:
	push	sword_dodge_02
	jmp	end_set_combat
	print_dodge_03:
	push	sword_dodge_03
	jmp	end_set_combat
	print_dodge_04:
	push	sword_dodge_04
	jmp	end_set_combat
	print_dodge_05:
	push	sword_dodge_05
	jmp	end_set_combat
	print_dodge_06:
	push	sword_dodge_06
	jmp	end_set_combat
	print_dodge_07:
	push	sword_dodge_07
	jmp	end_set_combat
	print_dodge_08:
	push	sword_dodge_08
	jmp	end_set_combat
	print_dodge_09:
	push	sword_dodge_09
	jmp	end_set_combat
	print_dodge_10:
	push	sword_dodge_10
	jmp	end_set_combat
set_h_crit:
	cmp	ecx, 0
	 je	print_crit_01
	cmp	ecx, 1
	 je	print_crit_02
	cmp	ecx, 2
	 je	print_crit_03
	cmp	ecx, 3
	 je	print_crit_04
	cmp	ecx, 4
	 je	print_crit_05
	cmp	ecx, 5
	 je	print_crit_06
	cmp	ecx, 6
	 je	print_crit_07
	cmp	ecx, 7
	 je	print_crit_08
	cmp	ecx, 8
	 je	print_crit_09
	cmp	ecx, 9
	 je	print_crit_10

	print_crit_01:
	push	sword_crit_01
	jmp	end_set_combat
	print_crit_02:
	push	sword_crit_02
	jmp	end_set_combat
	print_crit_03:
	push	sword_crit_03
	jmp	end_set_combat
	print_crit_04:
	push	sword_crit_04
	jmp	end_set_combat
	print_crit_05:
	push	sword_crit_05
	jmp	end_set_combat
	print_crit_06:
	push	sword_crit_06
	jmp	end_set_combat
	print_crit_07:
	push	sword_crit_07
	jmp	end_set_combat
	print_crit_08:
	push	sword_crit_08
	jmp	end_set_combat
	print_crit_09:
	push	sword_crit_09
	jmp	end_set_combat
	print_crit_10:
	push	sword_crit_10
	jmp	end_set_combat
set_e_crit:
	cmp	ecx, 0
	 je	print_ouch_01
	cmp	ecx, 1
	 je	print_ouch_02
	cmp	ecx, 2
	 je	print_ouch_03
	cmp	ecx, 3
	 je	print_ouch_04
	cmp	ecx, 4
	 je	print_ouch_05
	cmp	ecx, 5
	 je	print_ouch_06
	cmp	ecx, 6
	 je	print_ouch_07
	cmp	ecx, 7
	 je	print_ouch_08
	cmp	ecx, 8
	 je	print_ouch_09
	cmp	ecx, 9
	 je	print_ouch_10

	print_ouch_01:
	push	sword_ouch_01
	jmp	end_set_combat
	print_ouch_02:
	push	sword_ouch_02
	jmp	end_set_combat
	print_ouch_03:
	push	sword_ouch_03
	jmp	end_set_combat
	print_ouch_04:
	push	sword_ouch_04
	jmp	end_set_combat
	print_ouch_05:
	push	sword_ouch_05
	jmp	end_set_combat
	print_ouch_06:
	push	sword_ouch_06
	jmp	end_set_combat
	print_ouch_07:
	push	sword_ouch_07
	jmp	end_set_combat
	print_ouch_08:
	push	sword_ouch_08
	jmp	end_set_combat
	print_ouch_09:
	push	sword_ouch_09
	jmp	end_set_combat
	print_ouch_10:
	push	sword_ouch_10
	jmp	end_set_combat

end_set_combat:
	mov	eax, 24
	call	add_string_to_buffer
	call	print_line
	popad
	add	bx, 1
	pushad
	mov	ax, 17
	mov	cx, bx
	call	move_cursor
	popad
	add	ecx, 1
	cmp	ecx, 10
	 jl	combat_drow

	push	edx
	ret
	;-----------------------------------------------------------------------
combat_boss_drow:
	pushad
	cmp	esi, 0
	 je	set_boss_pause
	cmp	esi, 1
	 je	set_boss_norm_hit
	cmp	esi, 2
	 je	set_boss_norm_dmg
	cmp	esi, 3
	 je	set_boss_miss
	cmp	esi, 4
	 je	set_boss_dodge
	cmp	esi, 5
	 je	set_boss_h_crit
	cmp	esi, 6
	 je	set_boss_e_crit

set_boss_pause:
	cmp	ecx, 0
	 je	print_boss_pause_01
	cmp	ecx, 1
	 je	print_boss_pause_02
	cmp	ecx, 2
	 je	print_boss_pause_03
	cmp	ecx, 3
	 je	print_boss_pause_04
	cmp	ecx, 4
	 je	print_boss_pause_05
	cmp	ecx, 5
	 je	print_boss_pause_06
	cmp	ecx, 6
	 je	print_boss_pause_07
	cmp	ecx, 7
	 je	print_boss_pause_08
	cmp	ecx, 8
	 je	print_boss_pause_09
	cmp	ecx, 9
	 je	print_boss_pause_10

	print_boss_pause_01:
	push	boss_pause_01
	jmp	end_set_boss_combat
	print_boss_pause_02:
	push	boss_pause_02
	jmp	end_set_boss_combat
	print_boss_pause_03:
	push	boss_pause_03
	jmp	end_set_boss_combat
	print_boss_pause_04:
	push	boss_pause_04
	jmp	end_set_boss_combat
	print_boss_pause_05:
	push	boss_pause_05
	jmp	end_set_boss_combat
	print_boss_pause_06:
	push	boss_pause_06
	jmp	end_set_boss_combat
	print_boss_pause_07:
	push	boss_pause_07
	jmp	end_set_boss_combat
	print_boss_pause_08:
	push	boss_pause_08
	jmp	end_set_boss_combat
	print_boss_pause_09:
	push	boss_pause_09
	jmp	end_set_boss_combat
	print_boss_pause_10:
	push	boss_pause_10
	jmp	end_set_boss_combat
set_boss_norm_hit:
	cmp	ecx, 0
	 je	print_boss_n_h_01
	cmp	ecx, 1
	 je	print_boss_n_h_02
	cmp	ecx, 2
	 je	print_boss_n_h_03
	cmp	ecx, 3
	 je	print_boss_n_h_04
	cmp	ecx, 4
	 je	print_boss_n_h_05
	cmp	ecx, 5
	 je	print_boss_n_h_06
	cmp	ecx, 6
	 je	print_boss_n_h_07
	cmp	ecx, 7
	 je	print_boss_n_h_08
	cmp	ecx, 8
	 je	print_boss_n_h_09
	cmp	ecx, 9
	 je	print_boss_n_h_10

	print_boss_n_h_01:
	push	boss_n_h_01
	jmp	end_set_boss_combat
	print_boss_n_h_02:
	push	boss_n_h_02
	jmp	end_set_boss_combat
	print_boss_n_h_03:
	push	boss_n_h_03
	jmp	end_set_boss_combat
	print_boss_n_h_04:
	push	boss_n_h_04
	jmp	end_set_boss_combat
	print_boss_n_h_05:
	push	boss_n_h_05
	jmp	end_set_boss_combat
	print_boss_n_h_06:
	push	boss_n_h_06
	jmp	end_set_boss_combat
	print_boss_n_h_07:
	push	boss_n_h_07
	jmp	end_set_boss_combat
	print_boss_n_h_08:
	push	boss_n_h_08
	jmp	end_set_boss_combat
	print_boss_n_h_09:
	push	boss_n_h_09
	jmp	end_set_boss_combat
	print_boss_n_h_10:
	push	boss_n_h_10
	jmp	end_set_boss_combat
set_boss_norm_dmg:
	cmp	ecx, 0
	 je	print_boss_n_e_01
	cmp	ecx, 1
	 je	print_boss_n_e_02
	cmp	ecx, 2
	 je	print_boss_n_e_03
	cmp	ecx, 3
	 je	print_boss_n_e_04
	cmp	ecx, 4
	 je	print_boss_n_e_05
	cmp	ecx, 5
	 je	print_boss_n_e_06
	cmp	ecx, 6
	 je	print_boss_n_e_07
	cmp	ecx, 7
	 je	print_boss_n_e_08
	cmp	ecx, 8
	 je	print_boss_n_e_09
	cmp	ecx, 9
	 je	print_boss_n_e_10

	print_boss_n_e_01:
	push	boss_n_e_01
	jmp	end_set_boss_combat
	print_boss_n_e_02:
	push	boss_n_e_02
	jmp	end_set_boss_combat
	print_boss_n_e_03:
	push	boss_n_e_03
	jmp	end_set_boss_combat
	print_boss_n_e_04:
	push	boss_n_e_04
	jmp	end_set_boss_combat
	print_boss_n_e_05:
	push	boss_n_e_05
	jmp	end_set_boss_combat
	print_boss_n_e_06:
	push	boss_n_e_06
	jmp	end_set_boss_combat
	print_boss_n_e_07:
	push	boss_n_e_07
	jmp	end_set_boss_combat
	print_boss_n_e_08:
	push	boss_n_e_08
	jmp	end_set_boss_combat
	print_boss_n_e_09:
	push	boss_n_e_09
	jmp	end_set_boss_combat
	print_boss_n_e_10:
	push	boss_n_e_10
	jmp	end_set_boss_combat
set_boss_miss:
	cmp	ecx, 0
	 je	print_boss_miss_01
	cmp	ecx, 1
	 je	print_boss_miss_02
	cmp	ecx, 2
	 je	print_boss_miss_03
	cmp	ecx, 3
	 je	print_boss_miss_04
	cmp	ecx, 4
	 je	print_boss_miss_05
	cmp	ecx, 5
	 je	print_boss_miss_06
	cmp	ecx, 6
	 je	print_boss_miss_07
	cmp	ecx, 7
	 je	print_boss_miss_08
	cmp	ecx, 8
	 je	print_boss_miss_09
	cmp	ecx, 9
	 je	print_boss_miss_10

	print_boss_miss_01:
	push	boss_miss_01
	jmp	end_set_boss_combat
	print_boss_miss_02:
	push	boss_miss_02
	jmp	end_set_boss_combat
	print_boss_miss_03:
	push	boss_miss_03
	jmp	end_set_boss_combat
	print_boss_miss_04:
	push	boss_miss_04
	jmp	end_set_boss_combat
	print_boss_miss_05:
	push	boss_miss_05
	jmp	end_set_boss_combat
	print_boss_miss_06:
	push	boss_miss_06
	jmp	end_set_boss_combat
	print_boss_miss_07:
	push	boss_miss_07
	jmp	end_set_boss_combat
	print_boss_miss_08:
	push	boss_miss_08
	jmp	end_set_boss_combat
	print_boss_miss_09:
	push	boss_miss_09
	jmp	end_set_boss_combat
	print_boss_miss_10:
	push	boss_miss_10
	jmp	end_set_boss_combat
set_boss_dodge:
	cmp	ecx, 0
	 je	print_boss_dodge_01
	cmp	ecx, 1
	 je	print_boss_dodge_02
	cmp	ecx, 2
	 je	print_boss_dodge_03
	cmp	ecx, 3
	 je	print_boss_dodge_04
	cmp	ecx, 4
	 je	print_boss_dodge_05
	cmp	ecx, 5
	 je	print_boss_dodge_06
	cmp	ecx, 6
	 je	print_boss_dodge_07
	cmp	ecx, 7
	 je	print_boss_dodge_08
	cmp	ecx, 8
	 je	print_boss_dodge_09
	cmp	ecx, 9
	 je	print_boss_dodge_10

	print_boss_dodge_01:
	push	boss_dodge_01
	jmp	end_set_boss_combat
	print_boss_dodge_02:
	push	boss_dodge_02
	jmp	end_set_boss_combat
	print_boss_dodge_03:
	push	boss_dodge_03
	jmp	end_set_boss_combat
	print_boss_dodge_04:
	push	boss_dodge_04
	jmp	end_set_boss_combat
	print_boss_dodge_05:
	push	boss_dodge_05
	jmp	end_set_boss_combat
	print_boss_dodge_06:
	push	boss_dodge_06
	jmp	end_set_boss_combat
	print_boss_dodge_07:
	push	boss_dodge_07
	jmp	end_set_boss_combat
	print_boss_dodge_08:
	push	boss_dodge_08
	jmp	end_set_boss_combat
	print_boss_dodge_09:
	push	boss_dodge_09
	jmp	end_set_boss_combat
	print_boss_dodge_10:
	push	boss_dodge_10
	jmp	end_set_boss_combat
set_boss_h_crit:
	cmp	ecx, 0
	 je	print_boss_crit_01
	cmp	ecx, 1
	 je	print_boss_crit_02
	cmp	ecx, 2
	 je	print_boss_crit_03
	cmp	ecx, 3
	 je	print_boss_crit_04
	cmp	ecx, 4
	 je	print_boss_crit_05
	cmp	ecx, 5
	 je	print_boss_crit_06
	cmp	ecx, 6
	 je	print_boss_crit_07
	cmp	ecx, 7
	 je	print_boss_crit_08
	cmp	ecx, 8
	 je	print_boss_crit_09
	cmp	ecx, 9
	 je	print_boss_crit_10

	print_boss_crit_01:
	push	boss_crit_01
	jmp	end_set_boss_combat
	print_boss_crit_02:
	push	boss_crit_02
	jmp	end_set_boss_combat
	print_boss_crit_03:
	push	boss_crit_03
	jmp	end_set_boss_combat
	print_boss_crit_04:
	push	boss_crit_04
	jmp	end_set_boss_combat
	print_boss_crit_05:
	push	boss_crit_05
	jmp	end_set_boss_combat
	print_boss_crit_06:
	push	boss_crit_06
	jmp	end_set_boss_combat
	print_boss_crit_07:
	push	boss_crit_07
	jmp	end_set_boss_combat
	print_boss_crit_08:
	push	boss_crit_08
	jmp	end_set_boss_combat
	print_boss_crit_09:
	push	boss_crit_09
	jmp	end_set_boss_combat
	print_boss_crit_10:
	push	boss_crit_10
	jmp	end_set_boss_combat
set_boss_e_crit:
	cmp	ecx, 0
	 je	print_boss_ouch_01
	cmp	ecx, 1
	 je	print_boss_ouch_02
	cmp	ecx, 2
	 je	print_boss_ouch_03
	cmp	ecx, 3
	 je	print_boss_ouch_04
	cmp	ecx, 4
	 je	print_boss_ouch_05
	cmp	ecx, 5
	 je	print_boss_ouch_06
	cmp	ecx, 6
	 je	print_boss_ouch_07
	cmp	ecx, 7
	 je	print_boss_ouch_08
	cmp	ecx, 8
	 je	print_boss_ouch_09
	cmp	ecx, 9
	 je	print_boss_ouch_10

	print_boss_ouch_01:
	push	boss_ouch_01
	jmp	end_set_boss_combat
	print_boss_ouch_02:
	push	boss_ouch_02
	jmp	end_set_boss_combat
	print_boss_ouch_03:
	push	boss_ouch_03
	jmp	end_set_boss_combat
	print_boss_ouch_04:
	push	boss_ouch_04
	jmp	end_set_boss_combat
	print_boss_ouch_05:
	push	boss_ouch_05
	jmp	end_set_boss_combat
	print_boss_ouch_06:
	push	boss_ouch_06
	jmp	end_set_boss_combat
	print_boss_ouch_07:
	push	boss_ouch_07
	jmp	end_set_boss_combat
	print_boss_ouch_08:
	push	boss_ouch_08
	jmp	end_set_boss_combat
	print_boss_ouch_09:
	push	boss_ouch_09
	jmp	end_set_boss_combat
	print_boss_ouch_10:
	push	boss_ouch_10
	jmp	end_set_boss_combat

end_set_boss_combat:
	mov	eax, 24
	call	add_string_to_buffer
	call	print_line
	popad
	add	bx, 1
	pushad
	mov	ax, 17
	mov	cx, bx
	call	move_cursor
	popad
	add	ecx, 1
	cmp	ecx, 10
	 jl	combat_boss_drow
	push	edx
	ret
;-------------------------------------------------------------------------------
fight_win:
	call	battle_over_clrscr
	mov	eax, [won_num]
	add	eax, 1
	mov	[won_num], eax

	mov	eax, [stage_lvl]
	cmp	eax, 10
	 je	win_game							;GAME OVER (won)
	 
	mov	eax, [cur_exp]
	mov	ebx, [mb_exp]
	add	eax, ebx
	mov	[cur_exp], eax

	xor	ebx, ebx
	mov	[lvl_in_a_row], ebx						;set 0 level in a row

check_lvl_row:
	mov	eax, [cur_exp]
	mov	ebx, [need_exp_to_lvl]
	cmp	eax, ebx
	 jl	fight_to_main							;not enough XP for lvl-up

	imul	ebx, 2								;coef. of multiply to lvl
	mov	[need_exp_to_lvl], ebx

	mov	ebx, [lvl_in_a_row]
	add	ebx, 1
	mov	[lvl_in_a_row], ebx

	mov	ebx, [cur_lvl]
	add	ebx, 1
	mov	[cur_lvl], ebx
	jmp	level_up

fight_to_main:
	mov	ebx, [lvl_in_a_row]
	cmp	ebx, 0
	 je	fight_mode
	jmp	stat_window_init
;-------------------------------------------------------------------------------
level_up:
	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	xor	eax, eax
	add	eax, 42
	push	lvl_up_line_1
	call	add_string_to_buffer
	call	print_line

	xor	eax, eax
	add	eax, 2
	mov	ebx, [cur_lvl]
	push	ebx
	call	add_num_to_buffer
	call	print_line
	call	print_end_line

	xor	eax, eax
	add	eax, 42
	push	lvl_up_line_2
	call	add_string_to_buffer
	call	print_line
	call	print_end_line

	xor	eax, eax
	add	eax, 42
	push	lvl_up_line_3
	call	add_string_to_buffer
	call	print_line
	call	print_end_line

	mov	eax, [stat_atk]
	add	eax, 1
	mov	[stat_atk], eax
	mov	eax, [stat_dex]
	add	eax, 1
	mov	[stat_dex], eax
	mov	eax, [stat_def]
	add	eax, 1
	mov	[stat_def], eax
	mov	eax, [stat_sta]
	add	eax, 1
	mov	[stat_sta], eax
	mov	eax, [stat_acc]
	add	eax, 1
	mov	[stat_acc], eax

wait_for_level_up:
	push	31h								;compare on press 1
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	lvl_up_on_1
	push	32h								;compare on press 2
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	lvl_up_on_2
	push	33h								;compare on press 3
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	lvl_up_on_3
	push	34h								;compare on press 4
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	lvl_up_on_4
	push	35h								;compare on press 5
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	lvl_up_on_5
jmp	wait_for_level_up

;1)Atack 2)Defence 3)Stamina 4)Accur 5)Dext
lvl_up_on_1:
	mov	eax, [stat_atk]
	add	eax, 5
	mov	[stat_atk], eax
jmp	lvl_up_end
lvl_up_on_2:
	mov	eax, [stat_def]
	add	eax, 5
	mov	[stat_def], eax
jmp	lvl_up_end
lvl_up_on_3:
	mov	eax, [stat_sta]
	add	eax, 5
	mov	[stat_sta], eax
jmp	lvl_up_end
lvl_up_on_4:
	mov	eax, [stat_acc]
	add	eax, 5
	mov	[stat_acc], eax
jmp	lvl_up_end
lvl_up_on_5:
	mov	eax, [stat_dex]
	add	eax, 5
	mov	[stat_dex], eax
jmp	lvl_up_end

lvl_up_end:
	jmp	check_lvl_row
;-------------------------------------------------------------------------------
game_over:
	call	battle_over_clrscr

	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	xor	eax, eax
	add	eax, 31
	push	game_over_line_1
	call	add_string_to_buffer
	call	print_line
	call	print_end_line

	xor	eax, eax
	add	eax, 29
	push	game_over_line_2
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	call	print_end_line

	xor	ecx, ecx
	add	ecx, 1
game_over_loop:
	pushad
	cmp	ecx, 1
	 je	print_game_over_line_1
	cmp	ecx, 2
	 je	print_game_over_line_2
	cmp	ecx, 3
	 je	print_game_over_line_3
	cmp	ecx, 4
	 je	print_game_over_line_4
	cmp	ecx, 5
	 je	print_game_over_line_5
	cmp	ecx, 6
	 je	print_game_over_line_6
	cmp	ecx, 7
	 je	print_game_over_line_7
	cmp	ecx, 8
	 je	print_game_over_line_8
	cmp	ecx, 9
	 je	print_game_over_line_9
	cmp	ecx, 10
	 je	print_game_over_line_10

	print_game_over_line_1:
	push	death_line_01
	jmp	over_str_chosen
	print_game_over_line_2:
	push	death_line_02
	jmp	over_str_chosen
	print_game_over_line_3:
	push	death_line_03
	jmp	over_str_chosen
	print_game_over_line_4:
	push	death_line_04
	jmp	over_str_chosen
	print_game_over_line_5:
	push	death_line_05
	jmp	over_str_chosen
	print_game_over_line_6:
	push	death_line_06
	jmp	over_str_chosen
	print_game_over_line_7:
	push	death_line_07
	jmp	over_str_chosen
	print_game_over_line_8:
	push	death_line_08
	jmp	over_str_chosen
	print_game_over_line_9:
	push	death_line_09
	jmp	over_str_chosen
	print_game_over_line_10:
	push	death_line_10

	over_str_chosen:
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 11
	 jl	game_over_loop

game_over_wait_loop:
	push	1Bh
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	exit
jmp	game_over_wait_loop
;-------------------------------------------------------------------------------
win_game:
	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	xor	ecx, ecx
	add	ecx, 1
win_game_loop:
	pushad
	cmp	ecx, 1
	 je	print_win_game_line_1
	cmp	ecx, 2
	 je	print_win_game_line_2
	cmp	ecx, 3
	 je	print_win_game_line_3
	cmp	ecx, 4
	 je	print_win_game_line_4
	cmp	ecx, 5
	 je	print_win_game_line_5
	cmp	ecx, 6
	 je	print_win_game_line_6
	cmp	ecx, 7
	 je	print_win_game_line_7
	cmp	ecx, 8
	 je	print_win_game_line_8
	cmp	ecx, 9
	 je	print_win_game_line_9
	cmp	ecx, 10
	 je	print_win_game_line_10
	cmp	ecx, 11
	 je	print_win_game_line_11
	cmp	ecx, 12
	 je	print_win_game_line_12
	cmp	ecx, 13
	 je	print_win_game_line_13
	cmp	ecx, 14
	 je	print_win_game_line_14
	cmp	ecx, 15
	 je	print_win_game_line_15
	cmp	ecx, 16
	 je	print_win_game_line_16
	cmp	ecx, 17
	 je	print_win_game_line_17
	cmp	ecx, 18
	 je	print_win_game_line_18
	cmp	ecx, 19
	 je	print_win_game_line_19
	cmp	ecx, 20
	 je	print_win_game_line_20
	cmp	ecx, 21
	 je	print_win_game_line_21
	cmp	ecx, 22
	 je	print_win_game_line_22
	cmp	ecx, 23
	 je	print_win_game_line_23
	cmp	ecx, 24
	 je	print_win_game_line_24

	print_win_game_line_1:
	push	graz_01
	jmp	win_chosen
	print_win_game_line_2:
	push	graz_02
	jmp	win_chosen
	print_win_game_line_3:
	push	graz_03
	jmp	win_chosen
	print_win_game_line_4:
	push	graz_04
	jmp	win_chosen
	print_win_game_line_5:
	push	graz_05
	jmp	win_chosen
	print_win_game_line_6:
	push	graz_06
	jmp	win_chosen
	print_win_game_line_7:
	push	graz_07
	jmp	win_chosen
	print_win_game_line_8:
	push	graz_08
	jmp	win_chosen
	print_win_game_line_9:
	push	graz_09
	jmp	win_chosen
	print_win_game_line_10:
	push	graz_10
	jmp	win_chosen
	print_win_game_line_11:
	push	graz_11
	jmp	win_chosen
	print_win_game_line_12:
	push	graz_12
	jmp	win_chosen
	print_win_game_line_13:
	push	graz_13
	jmp	win_chosen
	print_win_game_line_14:
	push	graz_14
	jmp	win_chosen
	print_win_game_line_15:
	push	graz_15
	jmp	win_chosen
	print_win_game_line_16:
	push	graz_16
	jmp	win_chosen
	print_win_game_line_17:
	push	graz_17
	jmp	win_chosen
	print_win_game_line_18:
	push	graz_18
	jmp	win_chosen
	print_win_game_line_19:
	push	graz_19
	jmp	win_chosen
	print_win_game_line_20:
	push	graz_20
	jmp	win_chosen
	print_win_game_line_21:
	push	graz_21
	jmp	win_chosen
	print_win_game_line_22:
	push	graz_22
	jmp	win_chosen
	print_win_game_line_23:
	push	graz_23
	jmp	win_chosen
	print_win_game_line_24:
	push	graz_24
	jmp	win_chosen

	win_chosen:
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 25
	 jl	win_game_loop

win_wait_loop:
	push	1Bh
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	stop_win_wait_loop
jmp	win_wait_loop

stop_win_wait_loop:
	call	battle_over_clrscr

	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	mov	eax, 23
	push	end_stat_01
	call	add_string_to_buffer
	call	print_line
	mov	eax, 2
	mov	ecx, [cur_lvl]
	push	ecx
	call	add_num_to_buffer
	call	print_line
	call	print_end_line

	call	print_line

	mov	eax, 35
	push	end_stat_03
	call	add_string_to_buffer
	call	print_line
	call	print_end_line

	;<-------------------------------------------------------------------------------------===============================

	mov	eax, 35
	push	end_stat_11
	call	add_string_to_buffer
	call	print_line
	mov	eax, 3
	mov	ecx, [won_num]
	push	ecx
	call	add_num_to_buffer
	call	print_line
	call	print_end_line

	call	print_line

	mov	eax, 35
	push	end_stat_13
	call	add_string_to_buffer
	call	print_line
	mov	eax, 3
	mov	ecx, [retreat]
	push	ecx
	call	add_num_to_buffer
	call	print_line
	call	print_end_line

	call	print_line

	mov	eax, 35
	push	end_stat_15
	call	add_string_to_buffer
	call	print_line

	jmp	game_over_wait_loop
;-------------------------------------------------------------------------------
battle_over_clrscr:
	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	xor	ecx, ecx
	clean_screen:
	pushad
	xor	eax, eax
	add	eax, 39
	push	empty_line_39
	call	add_string_to_buffer
	call	print_line
	xor	eax, eax
	add	eax, 39
	push	empty_line_39
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 24
	 jl	clean_screen
ret
;-------------------------------------------------------------------------------
set_enemy_setting:
	mov	eax, [stage_lvl]

	cmp	eax, 1
	 je	set_lvl_1
	cmp	eax, 2
	 je	set_lvl_2
	cmp	eax, 3
	 je	set_lvl_3
	cmp	eax, 4
	 je	set_lvl_4
	cmp	eax, 5
	 je	set_lvl_5
	cmp	eax, 6
	 je	set_lvl_6
	cmp	eax, 7
	 je	set_lvl_7
	cmp	eax, 8
	 je	set_lvl_8
	cmp	eax, 9
	 je	set_lvl_9

;	set_lvl_boss:			;--------------------------------BOSS---<<<<<<<<<<<<<<
	mov	ax, 40			;40
	mov	[e_stat_acc], ax
	mov	[e_stat_dex], ax
	mov	[e_stat_atk], ax
	mov	[e_stat_def], ax
	add	ax, 59			;99
	mov	[e_stat_sta], ax
	mov	eax, 100000000		;100 000 000
	mov	[mb_exp], eax
	jmp	end_set_lvl
	set_lvl_1:			;--------------------------------1-st---<<<<<<<<<<<<<<
	mov	ax, 2			;2
	mov	[mb_exp], ax
	mov	[e_stat_dex], ax
	mov	[e_stat_acc], ax
	add	ax, 5			;7
	mov	[e_stat_atk], ax
	mov	[e_stat_def], ax
	add	ax, 3			;10
	mov	[e_stat_sta], ax
	jmp	end_set_lvl
	set_lvl_2:			;--------------------------------2-nd---<<<<<<<<<<<<<<
	mov	ax, 5			;5
	mov	[e_stat_dex], ax
	mov	[e_stat_acc], ax
	add	ax, 3			;8
	mov	[e_stat_sta], ax
	mov	[e_stat_def], ax
	add	ax, 5			;13
	mov	[mb_exp], ax
	mov	[e_stat_atk], ax
	jmp	end_set_lvl
	set_lvl_3:			;--------------------------------3-rd---<<<<<<<<<<<<<<
	xor	ax, ax			;0
	mov	[e_stat_dex], ax
	mov	[e_stat_acc], ax
	mov	[e_stat_def], ax
	add	ax, 19			;19
	mov	[e_stat_atk], ax
	add	ax, 19			;38
	mov	[e_stat_sta], ax
	add	ax, 32			;70
	mov	[mb_exp], ax
	jmp	end_set_lvl
	set_lvl_4:			;--------------------------------4-th---<<<<<<<<<<<<<<
	xor	ax, ax			;0
	mov	[e_stat_acc], ax
	mov	[e_stat_atk], ax
	add	ax, 15			;15
	mov	[e_stat_def], ax
	mov	[e_stat_sta], ax
	add	ax, 65			;80
	mov	[e_stat_dex], ax
	add	ax, 140			;220
	mov	[mb_exp], ax
	jmp	end_set_lvl
	set_lvl_5:			;--------------------------------5-th---<<<<<<<<<<<<<<
	mov	ax, 10			;10
	mov	[e_stat_dex], ax
	mov	[e_stat_acc], ax
	add	ax, 10			;20
	mov	[e_stat_atk], ax
	mov	[e_stat_def], ax
	add	ax, 10			;30
	mov	[e_stat_sta], ax
	add	ax, 970			;1000
	mov	[mb_exp], ax
	jmp	end_set_lvl
	set_lvl_6:			;--------------------------------6-th---<<<<<<<<<<<<<<
	xor	ax, ax			;0
	mov	[e_stat_def], ax
	add	ax, 25			;25
	mov	[e_stat_atk], ax
	add	ax, 10			;35
	mov	[e_stat_dex], ax
	mov	[e_stat_acc], ax
	mov	[e_stat_sta], ax
	add	ax, 4770		;4800
	mov	[mb_exp], ax
	jmp	end_set_lvl
	set_lvl_7:			;--------------------------------7-th---<<<<<<<<<<<<<<
	xor	ax, ax			;0
	mov	[e_stat_acc], ax
	mov	[e_stat_dex], ax
	add	ax, 20			;20
	mov	[e_stat_atk], ax
	add	ax, 30			;50
	mov	[e_stat_def], ax
	add	ax, 40			;90
	mov	[e_stat_sta], ax
	mov	eax, 100000		;100 000
	mov	[mb_exp], eax
	jmp	end_set_lvl
	set_lvl_8:			;--------------------------------8-th---<<<<<<<<<<<<<<
	xor	ax, ax		;0
	mov	[e_stat_acc], ax	
	mov	[e_stat_def], ax
	mov	[e_stat_dex], ax
	add	ax, 10			;10
	mov	[e_stat_sta], ax
	add	ax, 190			;200
	mov	[e_stat_atk], ax
	mov	eax, 200000		;200 000
	mov	[mb_exp], eax
	jmp	end_set_lvl
	set_lvl_9:			;--------------------------------9-th---<<<<<<<<<<<<<<
	mov	ax, 10			;10
	mov	[e_stat_acc], ax	
	add	ax, 20			;30
	mov	[e_stat_atk], ax
	add	ax, 30			;60
	mov	[e_stat_def], ax
	add	ax, 10			;70
	mov	[e_stat_dex], ax
	mov	[e_stat_sta], ax
	mov	eax, 8500000		;8 500 000
	mov	[mb_exp], eax
	end_set_lvl:
	ret
;-------------------------------------------------------------------------------
h_healthbar:
	xor	ax, ax
	add	ax, 17
	xor	cx, cx
	add	cx, 1
	call	move_cursor

	mov	eax, 7
	push	empty_line_7
	call	add_string_to_buffer
	call	print_line

	xor	ax, ax
	add	ax, 17
	xor	cx, cx
	add	cx, 1
	call	move_cursor

	mov	eax, 3
	mov	ecx, [h_cur_health]
	push	ecx
	call	add_num_to_buffer
	call	print_line

	xor	ax, ax
	add	ax, 20
	xor	cx, cx
	add	cx, 1
	call	move_cursor

	mov	eax, 1
	push	slash
	call	add_string_to_buffer
	call	print_line

	mov	eax, 3
	mov	ecx, [stat_sta]
	imul	ecx, 10
	push	ecx
	call	add_num_to_buffer
	call	print_line

	xor	ax, ax
	add	ax, 14
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	xor	eax, eax
	mov	ecx, [stat_sta]
	mov	ebx, [h_cur_health]
h_helthbar_loop:
	pushad
	mov	eax, 2
	push	health_tab
	call	add_string_to_buffer
	call	print_line
	popad
	sub	ebx, ecx
	add	eax, 1
	cmp	ebx, 0
	 jg	h_helthbar_loop
	cmp	eax, 10
	 je	end_h_healthbar_loop
h_empty_health_loop:
	pushad
	mov	eax, 2
	push	empty_health_tab
	call	add_string_to_buffer
	call	print_line
	popad
	add	eax, 1
	cmp	eax, 10
	 jl	h_empty_health_loop
end_h_healthbar_loop:
	ret
;-------------------------------------------------------------------------------
e_healthbar:
	xor	ax, ax
	add	ax, 42
	xor	cx, cx
	add	cx, 1
	call	move_cursor

	mov	eax, 7
	push	empty_line_7
	call	add_string_to_buffer
	call	print_line

	xor	ax, ax
	add	ax, 42
	xor	cx, cx
	add	cx, 1
	call	move_cursor

	mov	eax, 3
	mov	ecx, [e_cur_health]
	push	ecx
	call	add_num_to_buffer
	call	print_line

	xor	ax, ax
	add	ax, 45
	xor	cx, cx
	add	cx, 1
	call	move_cursor

	mov	eax, 1
	push	slash
	call	add_string_to_buffer
	call	print_line

	mov	eax, 3
	mov	ecx, [e_stat_sta]
	imul	ecx, 10
	push	ecx
	call	add_num_to_buffer
	call	print_line

	xor	ax, ax
	add	ax, 39
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	xor	edx, edx
	mov	ecx, [e_stat_sta]
	mov	ebx, [e_cur_health]
e_helthbar_loop:
	pushad
	mov	eax, 2
	push	health_tab
	call	add_string_to_buffer
	call	print_line
	popad
	sub	ebx, ecx
	add	edx, 1
	cmp	ebx, 0
	 jg	e_helthbar_loop
	cmp	edx, 10
	 je	end_e_healthbar_loop
e_empty_health_loop:
	pushad
	mov	eax, 2
	push	empty_health_tab
	call	add_string_to_buffer
	call	print_line
	popad
	add	edx, 1
	cmp	edx, 10
	 jl	e_empty_health_loop
end_e_healthbar_loop:
	ret
;-------------------------------------------------------------------------------
set_startup_features:
	xor	ax, ax
	mov	[won_num], ax
	mov	[retreat], ax
	mov	[cur_exp], ax
	mov	[stat_acc], ax
	mov	[stat_dex], ax
	add	ax, 1
	mov	[cur_lvl], ax
	add	ax, 1
	mov	[need_exp_to_lvl], ax
	add	ax, 8
	mov	[stat_sta], ax
	mov	[stat_atk], ax
	mov	[stat_def], ax
	ret
;-------------------------------------------------------------------------------
set_enemy_startup_features:
	xor	ax, ax
	add	ax, 2
	mov	[e_stat_acc], ax
	mov	[e_stat_dex], ax
	add	ax, 2
	mov	[e_stat_atk], ax
	mov	[e_stat_def], ax
	add	ax, 1
	mov	[e_stat_sta], ax
	ret
;-------------------------------------------------------------------------------
main_window_loop:
	push	10
	call	[__imp__Sleep@4]
	xor	eax, eax

	push	46h								;compare on press Fight
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode

	push	53h								;compare on press Stat
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	stat_window_init

	push	45h								;compare on press Exit
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	exit

	push	48h								;compare on press HELP
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	help_window_init

jmp	main_window_loop
;-------------------------------------------------------------------------------
fight_mode:
	call	print_fight_mode

	fight_mode_loop:
	push	10
	call	[__imp__Sleep@4]
	xor	eax, eax

	push	1Bh								;compare on press Esc
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_exit

	push	31h								;compare on press 1
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_1
	push	32h								;compare on press 2
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_2
	push	33h								;compare on press 3
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_3
	push	34h								;compare on press 4
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_4
	push	35h								;compare on press 5
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_5
	push	36h								;compare on press 6
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_6
	push	37h								;compare on press 7
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_7
	push	38h								;compare on press 8
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_8
	push	39h								;compare on press 9
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_9
	push	30h								;compare on press 0
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode_on_10

	jmp	fight_mode_loop
fight_mode_exit:
	call	init_main_window
	jmp	main_window_loop

fight_mode_on_1:
	mov	esi, 1
	jmp	start_battle
fight_mode_on_2:
	mov	esi, 2
	jmp	start_battle
fight_mode_on_3:
	mov	esi, 3
	jmp	start_battle
fight_mode_on_4:
	mov	esi, 4
	jmp	start_battle
fight_mode_on_5:
	mov	esi, 5
	jmp	start_battle
fight_mode_on_6:
	mov	esi, 6
	jmp	start_battle
fight_mode_on_7:
	mov	esi, 7
	jmp	start_battle
fight_mode_on_8:
	mov	esi, 8
	jmp	start_battle
fight_mode_on_9:
	mov	esi, 9
	jmp	start_battle
fight_mode_on_10:
	mov	esi, 10
	jmp	start_battle
;-------------------------------------------------------------------------------
init_fight_scene:
	mov	esi, [stage_lvl]

	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	xor	ecx, ecx
	add	ecx, 1
	
	cmp	esi, 10
	 je	boss_scene
	;-----------------------------------------------------------------------
fight_scene:
	cmp	ecx, 1
	 je	print_fight_line_01
	cmp	ecx, 2
	 je	print_fight_line_02
	cmp	ecx, 3
	 je	print_fight_line_03
	cmp	ecx, 4
	 je	print_fight_line_04
	cmp	ecx, 5
	 je	print_fight_line_05
	cmp	ecx, 6
	 je	print_fight_line_06
	cmp	ecx, 7
	 je	print_fight_line_07
	cmp	ecx, 8
	 je	print_fight_line_08
	cmp	ecx, 9
	 je	print_fight_line_09
	cmp	ecx, 10
	 je	print_fight_line_10
	cmp	ecx, 11
	 je	print_fight_line_11
	cmp	ecx, 12
	 je	print_fight_line_12
	cmp	ecx, 13
	 je	print_fight_line_13
	cmp	ecx, 14
	 je	print_fight_line_14
	cmp	ecx, 15
	 je	print_fight_line_15
	cmp	ecx, 16
	 je	print_fight_line_16
	cmp	ecx, 17
	 je	print_fight_line_17
	cmp	ecx, 18
	 je	print_fight_line_18
	cmp	ecx, 19
	 je	print_fight_line_19
	cmp	ecx, 20
	 je	print_fight_line_20
	cmp	ecx, 21
	 je	print_fight_line_21
	cmp	ecx, 22
	 je	print_fight_line_22
	cmp	ecx, 23
	 je	print_fight_line_23
	cmp	ecx, 24
	 je	print_fight_line_24

	print_fight_line_01:
	push	fight_line_01
	jmp	end_print_fight_line
	print_fight_line_02:
	push	fight_line_02
	jmp	end_print_fight_line
	print_fight_line_03:
	push	fight_line_03
	jmp	end_print_fight_line
	print_fight_line_04:
	push	fight_line_04
	jmp	end_print_fight_line
	print_fight_line_05:
	push	fight_line_05
	jmp	end_print_fight_line
	print_fight_line_06:
	push	fight_line_06
	jmp	end_print_fight_line
	print_fight_line_07:
	push	fight_line_07
	jmp	end_print_fight_line
	print_fight_line_08:
	push	fight_line_08
	jmp	end_print_fight_line
	print_fight_line_09:
	push	fight_line_09
	jmp	end_print_fight_line
	print_fight_line_10:
	push	fight_line_10
	jmp	end_print_fight_line
	print_fight_line_11:
	push	fight_line_11
	jmp	end_print_fight_line
	print_fight_line_12:
	push	fight_line_12
	jmp	end_print_fight_line
	print_fight_line_13:
	push	fight_line_13
	jmp	end_print_fight_line
	print_fight_line_14:
	push	fight_line_14
	jmp	end_print_fight_line
	print_fight_line_15:
	push	fight_line_15
	jmp	end_print_fight_line
	print_fight_line_16:
	push	fight_line_16
	jmp	end_print_fight_line
	print_fight_line_17:
	push	fight_line_17
	jmp	end_print_fight_line
	print_fight_line_18:
	push	fight_line_18
	jmp	end_print_fight_line
	print_fight_line_19:
	push	fight_line_19
	jmp	end_print_fight_line
	print_fight_line_20:
	push	fight_line_20
	jmp	end_print_fight_line
	print_fight_line_21:
	push	fight_line_21
	jmp	end_print_fight_line
	print_fight_line_22:
	push	fight_line_22
	jmp	end_print_fight_line
	print_fight_line_23:
	push	fight_line_23
	jmp	end_print_fight_line
	print_fight_line_24:
	push	fight_line_24
	end_print_fight_line:

	mov	edi, ecx
	mov	eax, 60
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	mov	ecx, edi
	add	ecx, 1
	cmp	ecx, 25
	 jl	fight_scene
	ret
	;-----------------------------------------------------------------------
boss_scene:
	cmp	ecx, 1
	 je	print_b_fight_line_01
	cmp	ecx, 2
	 je	print_b_fight_line_02
	cmp	ecx, 3
	 je	print_b_fight_line_03
	cmp	ecx, 4
	 je	print_b_fight_line_04
	cmp	ecx, 5
	 je	print_b_fight_line_05
	cmp	ecx, 6
	 je	print_b_fight_line_06
	cmp	ecx, 7
	 je	print_b_fight_line_07
	cmp	ecx, 8
	 je	print_b_fight_line_08
	cmp	ecx, 9
	 je	print_b_fight_line_09
	cmp	ecx, 10
	 je	print_b_fight_line_10
	cmp	ecx, 11
	 je	print_b_fight_line_11
	cmp	ecx, 12
	 je	print_b_fight_line_12
	cmp	ecx, 13
	 je	print_b_fight_line_13
	cmp	ecx, 14
	 je	print_b_fight_line_14
	cmp	ecx, 15
	 je	print_b_fight_line_15
	cmp	ecx, 16
	 je	print_b_fight_line_16
	cmp	ecx, 17
	 je	print_b_fight_line_17
	cmp	ecx, 18
	 je	print_b_fight_line_18
	cmp	ecx, 19
	 je	print_b_fight_line_19
	cmp	ecx, 20
	 je	print_b_fight_line_20
	cmp	ecx, 21
	 je	print_b_fight_line_21
	cmp	ecx, 22
	 je	print_b_fight_line_22
	cmp	ecx, 23
	 je	print_b_fight_line_23
	cmp	ecx, 24
	 je	print_b_fight_line_24

	print_b_fight_line_01:
	push	b_fight_line_01
	jmp	end_print_b_fight_line
	print_b_fight_line_02:
	push	b_fight_line_02
	jmp	end_print_b_fight_line
	print_b_fight_line_03:
	push	b_fight_line_03
	jmp	end_print_b_fight_line
	print_b_fight_line_04:
	push	b_fight_line_04
	jmp	end_print_b_fight_line
	print_b_fight_line_05:
	push	b_fight_line_05
	jmp	end_print_b_fight_line
	print_b_fight_line_06:
	push	b_fight_line_06
	jmp	end_print_b_fight_line
	print_b_fight_line_07:
	push	b_fight_line_07
	jmp	end_print_b_fight_line
	print_b_fight_line_08:
	push	b_fight_line_08
	jmp	end_print_b_fight_line
	print_b_fight_line_09:
	push	b_fight_line_09
	jmp	end_print_b_fight_line
	print_b_fight_line_10:
	push	b_fight_line_10
	jmp	end_print_b_fight_line
	print_b_fight_line_11:
	push	b_fight_line_11
	jmp	end_print_b_fight_line
	print_b_fight_line_12:
	push	b_fight_line_12
	jmp	end_print_b_fight_line
	print_b_fight_line_13:
	push	b_fight_line_13
	jmp	end_print_b_fight_line
	print_b_fight_line_14:
	push	b_fight_line_14
	jmp	end_print_b_fight_line
	print_b_fight_line_15:
	push	b_fight_line_15
	jmp	end_print_b_fight_line
	print_b_fight_line_16:
	push	b_fight_line_16
	jmp	end_print_b_fight_line
	print_b_fight_line_17:
	push	b_fight_line_17
	jmp	end_print_b_fight_line
	print_b_fight_line_18:
	push	b_fight_line_18
	jmp	end_print_b_fight_line
	print_b_fight_line_19:
	push	b_fight_line_19
	jmp	end_print_b_fight_line
	print_b_fight_line_20:
	push	b_fight_line_20
	jmp	end_print_b_fight_line
	print_b_fight_line_21:
	push	b_fight_line_21
	jmp	end_print_b_fight_line
	print_b_fight_line_22:
	push	b_fight_line_22
	jmp	end_print_b_fight_line
	print_b_fight_line_23:
	push	b_fight_line_23
	jmp	end_print_b_fight_line
	print_b_fight_line_24:
	push	b_fight_line_24
	end_print_b_fight_line:

	mov	edi, ecx
	mov	eax, 77
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	mov	ecx, edi
	add	ecx, 1
	cmp	ecx, 25
	 jl	boss_scene

	ret
;-------------------------------------------------------------------------------
print_fight_mode:
	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	mov	ecx, 1
	mov	eax, 42
	print_fight_mode_loop_1:
	pushad
	call	choose_tab_1
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 9
	 jl	print_fight_mode_loop_1

	call	print_end_line
	mov	ecx, 9
	print_fight_mode_loop_2:
	pushad
	push	empty_line
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 24
	 jl	print_fight_mode_loop_2

	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 9
	call	move_cursor

	xor	eax, eax
	add	eax, 42
	xor	ecx, ecx
	add	ecx, 1
	print_fight_mode_loop_3:

	pushad
	cmp	ecx, 1
	 je	print_mode_01
	cmp	ecx, 2
	 je	print_mode_02
	cmp	ecx, 3
	 je	print_mode_03
	cmp	ecx, 4
	 je	print_mode_04
	cmp	ecx, 5
	 je	print_mode_05
	cmp	ecx, 6
	 je	print_mode_06
	cmp	ecx, 7
	 je	print_mode_07
	cmp	ecx, 8
	 je	print_mode_08
	cmp	ecx, 9
	 je	print_mode_09
	cmp	ecx, 10
	 je	print_mode_10
	cmp	ecx, 11
	 je	print_mode_11

	push	mode_line_12
	jmp	end_print_mode
	print_mode_01:
	push	mode_line_01
	jmp	end_print_mode
	print_mode_02:
	push	mode_line_02
	jmp	end_print_mode
	print_mode_03:
	push	mode_line_03
	jmp	end_print_mode
	print_mode_04:
	push	mode_line_04
	jmp	end_print_mode
	print_mode_05:
	push	mode_line_05
	jmp	end_print_mode
	print_mode_06:
	push	mode_line_06
	jmp	end_print_mode
	print_mode_07:
	push	mode_line_07
	jmp	end_print_mode
	print_mode_08:
	push	mode_line_08
	jmp	end_print_mode
	print_mode_09:
	push	mode_line_09
	jmp	end_print_mode
	print_mode_10:
	push	mode_line_10
	jmp	end_print_mode
	print_mode_11:
	push	mode_line_11

	end_print_mode:
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	pushad
	cmp	ecx, 11
	 je	call_print_end_line_in_mode
	call_print_end_line_in_mode_back:
	popad
	add	ecx, 1
	cmp	ecx, 13
	 jl	print_fight_mode_loop_3
	ret

call_print_end_line_in_mode:
	call	print_end_line
jmp	call_print_end_line_in_mode_back
;-------------------------------------------------------------------------------
stat_window_init:
	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	mov	ecx, 1
	mov	eax, 42
	stat_window_loop_1:
	pushad
	call	choose_tab_2
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 7
	 jl	stat_window_loop_1

	stat_window_loop_2:
	pushad
	push	empty_line
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 25
	 jl	stat_window_loop_2

	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 8
	call	move_cursor

	mov	ecx, 1
	stat_window_loop_3:
	pushad
	cmp	ecx, 1
	 je	print_stat_1
	cmp	ecx, 2
	 je	print_stat_2
	cmp	ecx, 3
	 je	print_stat_3
	cmp	ecx, 4
	 je	print_stat_4
	cmp	ecx, 5
	 je	print_stat_5
	cmp	ecx, 6
	 je	print_stat_6

	push	stat_need_exp
	jmp	end_print_stat
	print_stat_1:
	push	stat_atk_line
	jmp	end_print_stat
	print_stat_2:
	push	stat_def_line
	jmp	end_print_stat
	print_stat_3:
	push	stat_sta_line
	jmp	end_print_stat
	print_stat_4:
	push	stat_acc_line
	jmp	end_print_stat
	print_stat_5:
	push	stat_dex_line
	jmp	end_print_stat
	print_stat_6:
	push	stat_cur_exp

	end_print_stat:
	call	add_string_to_buffer
	call	print_line

	popad
	pushad

	cmp	ecx, 1
	 je	print_stat_01
	cmp	ecx, 2
	 je	print_stat_02
	cmp	ecx, 3
	 je	print_stat_03
	cmp	ecx, 4
	 je	print_stat_04
	cmp	ecx, 5
	 je	print_stat_05
	cmp	ecx, 6
	 je	print_stat_06

	mov	esi, [need_exp_to_lvl]
	jmp	end_print_stat_num
	print_stat_01:
	mov	esi, [stat_atk]
	jmp	end_print_stat_num
	print_stat_02:
	mov	esi, [stat_def]
	jmp	end_print_stat_num
	print_stat_03:
	mov	esi, [stat_sta]
	jmp	end_print_stat_num
	print_stat_04:
	mov	esi, [stat_acc]
	jmp	end_print_stat_num
	print_stat_05:
	mov	esi, [stat_dex]
	jmp	end_print_stat_num
	print_stat_06:
	mov	esi, [cur_exp]

	end_print_stat_num:
	pushad
	call	clear_buffer
	popad
	pushad
	push	esi
	call	add_num_to_buffer
	popad
	pushad
	mov	eax, 9
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 8
	 jl	stat_window_loop_3

	call	print_end_line

	xor	eax, eax
	add	eax, 42
	push	help_text_10
	call	add_string_to_buffer
	call	print_line

stat_window_loop:
	push	10
	call	[__imp__Sleep@4]
	xor	eax, eax

	push	1Bh								;compare on press Esc
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	stat_exit

	jmp	stat_window_loop
stat_exit:
	call	init_main_window
	jmp	main_window_loop
;-------------------------------------------------------------------------------
help_window_init:
	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	mov	eax, 42
	xor	ecx, ecx
	add	ecx, 1
help_window_init_loop_1:
	pushad
	cmp	ecx, 1
	 je	print_help_line_1
	cmp	ecx, 2
	 je	print_help_line_2
	cmp	ecx, 3
	 je	print_help_line_3
	cmp	ecx, 4
	 je	print_help_line_4
	cmp	ecx, 5
	 je	print_help_line_5
	cmp	ecx, 6
	 je	print_help_line_6
	cmp	ecx, 7
	 je	print_help_line_7
	cmp	ecx, 8
	 je	print_help_line_8

	print_help_line_1:
	push	help_line_1
	jmp	end_print_help_lines
	print_help_line_2:
	push	help_line_2
	jmp	end_print_help_lines
	print_help_line_3:
	push	help_line_3
	jmp	end_print_help_lines
	print_help_line_4:
	push	help_line_4
	jmp	end_print_help_lines
	print_help_line_5:
	push	help_line_5
	jmp	end_print_help_lines
	print_help_line_6:
	push	help_line_6
	jmp	end_print_help_lines
	print_help_line_7:
	push	help_line_7
	jmp	end_print_help_lines
	print_help_line_8:
	push	help_line_8
	jmp	end_print_help_lines

	end_print_help_lines:
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 9
	 jl	help_window_init_loop_1

	call	print_end_line
	xor	ecx, ecx
	add	ecx, 1
help_window_init_loop_2:
	pushad
	cmp	ecx, 1
	 je	help_str_line_1
	cmp	ecx, 2
	 je	help_str_line_2
	cmp	ecx, 3
	 je	help_str_line_3
	cmp	ecx, 4
	 je	help_str_line_empty
	cmp	ecx, 5
	 je	help_str_line_5
	cmp	ecx, 6
	 je	help_str_line_6
	cmp	ecx, 7
	 je	help_str_line_empty
	cmp	ecx, 8
	 je	help_str_line_8
	cmp	ecx, 9
	 je	help_str_line_empty
	cmp	ecx, 10
	 je	help_str_line_10
	cmp	ecx, 11
	 je	help_str_line_empty
	cmp	ecx, 12
	 je	help_str_line_12
	cmp	ecx, 13
	 je	help_str_line_13
	cmp	ecx, 14
	 jge	help_str_line_empty

	help_str_line_1:
	push	help_text_01
	jmp	help_str_chosen
	help_str_line_2:
	push	help_text_02
	jmp	help_str_chosen
	help_str_line_3:
	push	help_text_03
	jmp	help_str_chosen
	help_str_line_5:
	push	help_text_05
	jmp	help_str_chosen
	help_str_line_6:
	push	help_text_06
	jmp	help_str_chosen
	help_str_line_8:
	push	help_text_08
	jmp	help_str_chosen
	help_str_line_10:
	push	help_text_10
	jmp	help_str_chosen
	help_str_line_12:
	push	help_text_12
	jmp	help_str_chosen
	help_str_line_13:
	push	help_text_13
	jmp	help_str_chosen
	help_str_line_empty:
	push	empty_line

	help_str_chosen:
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 16
	 jl	help_window_init_loop_2
help_window_loop:
	push	10
	call	[__imp__Sleep@4]
	xor	eax, eax

	push	1Bh								;compare on press Esc
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	 je	help_exit

	push	46h								;compare on press Fight
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	fight_mode

	push	53h								;compare on press Stat
	call	[__imp__GetAsyncKeyState@4]
	cmp	eax, 4294934529
	je	stat_window_init

	jmp	help_window_loop
;-------------------------------------------------------------------------------
help_exit:
	call	init_main_window
	jmp	main_window_loop
;-------------------------------------------------------------------------------
init_main_window:
	xor	ax, ax
	add	ax, 0
	xor	cx, cx
	add	cx, 0
	call	move_cursor

	mov	ecx, 1
	mov	eax, 42
	init_main_window_loop_1:
	pushad
	call	choose_tab_1
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 9
	 jl	init_main_window_loop_1

	push	empty_line
	call	add_string_to_buffer
	call	print_line
	call	print_end_line

	mov	ecx, 1
	mov	eax, 42
	init_main_window_loop_2:
	pushad
	call	choose_tab_2
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 7
	 jl	init_main_window_loop_2

	push	empty_line
	call	add_string_to_buffer
	call	print_line
	call	print_end_line

	mov	ecx, 1
	mov	eax, 42
	init_main_window_loop_3:
	pushad
	call	choose_tab_3
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	popad
	add	ecx, 1
	cmp	ecx, 7
	 jl	init_main_window_loop_3

	push	empty_line
	call	add_string_to_buffer
	call	print_line
	call	print_end_line

	push	help_line
	call	add_string_to_buffer
	call	print_line
	call	print_end_line
	ret
;-------------------------------------------------------------------------------
choose_tab_1:
	pop	esi
	cmp	ecx, 1
	 je	push_fight_line_1
	cmp	ecx, 2
	 je	push_fight_line_2
	cmp	ecx, 3
	 je	push_fight_line_3
	cmp	ecx, 4
	 je	push_fight_line_4
	cmp	ecx, 5
	 je	push_fight_line_5
	cmp	ecx, 6
	 je	push_fight_line_6
	cmp	ecx, 7
	 je	push_fight_line_7

	push	fight_line_8
	push	esi
	ret
	push_fight_line_1:
	push	fight_line_1
	push	esi
	ret
	push_fight_line_2:
	push	fight_line_2
	push	esi
	ret
	push_fight_line_3:
	push	fight_line_3
	push	esi
	ret
	push_fight_line_4:
	push	fight_line_4
	push	esi
	ret
	push_fight_line_5:
	push	fight_line_5
	push	esi
	ret
	push_fight_line_6:
	push	fight_line_6
	push	esi
	ret
	push_fight_line_7:
	push	fight_line_7
	push	esi
	ret
;-------------------------------------------------------------------------------
choose_tab_2:
	pop	esi
	cmp	ecx, 1
	 je	push_stat_line_1
	cmp	ecx, 2
	 je	push_stat_line_2
	cmp	ecx, 3
	 je	push_stat_line_3
	cmp	ecx, 4
	 je	push_stat_line_4
	cmp	ecx, 5
	 je	push_stat_line_5

	push	stat_line_6
	push	esi
	ret
	push_stat_line_1:
	push	stat_line_1
	push	esi
	ret
	push_stat_line_2:
	push	stat_line_2
	push	esi
	ret
	push_stat_line_3:
	push	stat_line_3
	push	esi
	ret
	push_stat_line_4:
	push	stat_line_4
	push	esi
	ret
	push_stat_line_5:
	push	stat_line_5
	push	esi
	ret
;-------------------------------------------------------------------------------
choose_tab_3:
	pop	esi
	cmp	ecx, 1
	 je	push_exit_line_1
	cmp	ecx, 2
	 je	push_exit_line_2
	cmp	ecx, 3
	 je	push_exit_line_3
	cmp	ecx, 4
	 je	push_exit_line_4
	cmp	ecx, 5
	 je	push_exit_line_5

	push	exit_line_6
	push	esi
	ret
	push_exit_line_1:
	push	exit_line_1
	push	esi
	ret
	push_exit_line_2:
	push	exit_line_2
	push	esi
	ret
	push_exit_line_3:
	push	exit_line_3
	push	esi
	ret
	push_exit_line_4:
	push	exit_line_4
	push	esi
	ret
	push_exit_line_5:
	push	exit_line_5
	push	esi
	ret
;-------------------------------------------------------------------------------
rand_percent:
	rdtsc									;stomp of time in EDX:EAX
	xor	edx, edx
	xor	ebx, ebx
	add	ebx, 100
	idiv	bx
ret
;-------------------------------------------------------------------------------
move_cursor:
	mov	[console_coord], ax						;ax = X coord
	mov	[console_coord + 2], cx						;cx = Y coord
	push	dword [console_coord]
	push	dword [stdout]
	call	[__imp__SetConsoleCursorPosition@8]
	ret
;-------------------------------------------------------------------------------
clear_buffer:
	pop	esi								;ret in stack
	push	empty_line_9
	push	sformat
	push	buffer
	call	[__imp__wsprintfA]
	add	esp, 12
	push	esi
	ret
;-------------------------------------------------------------------------------
add_string_to_buffer:
	pop	esi								;ret in stack
	push	sformat
	push	buffer
	call	[__imp__wsprintfA]
	add	esp, 12
	push	esi
	ret
;-------------------------------------------------------------------------------
add_num_to_buffer:
	pop	esi								;ret in stack
	push	iformat
	push	buffer
	call	[__imp__wsprintfA]
	add	esp, 12
	push	esi
	ret
;-------------------------------------------------------------------------------
print_line:
	push	dword 0
	push	written
	push	dword eax							;eax contain number of char
	push	buffer
	push	dword[stdout]
	call	[__imp__WriteConsoleA@20]
	ret
;-------------------------------------------------------------------------------
print_end_line:
	push	dword 0
	push	written
	push	dword 2
	push	end_line
	push	dword[stdout]
	call	[__imp__WriteConsoleA@20]
	ret
;-------------------------------------------------------------------------------
exit:
	push	0
	call	[__imp__ExitProcess@4]
end

;=======================SECTION RDATA===========================================
section .rdata

fight_line_1	db "       ______  _         _      _         ", 0
fight_line_2	db "      |  ____|(_)       | |    | |        ", 0
fight_line_3	db "      | |__    _   __ _ | |__  | |_       ", 0
fight_line_4	db "      |  __|  | | / _` || '_ \ | __|      ", 0
fight_line_5	db "      | |     | || (_| || | | || |_       ", 0
fight_line_6	db "      |_|     |_| \__, ||_| |_| \__|      ", 0
fight_line_7	db "                   __/ |                  ", 0
fight_line_8	db "                  |___/                   ", 0

stat_line_1	db "  _____ _        _   _     _   _          ", 0
stat_line_2	db " / ____| |      | | (_)   | | (_)         ", 0
stat_line_3	db "| (___ | |_ __ _| |_ _ ___| |_ _  ___ ___ ", 0
stat_line_4	db " \___ \| __/ _` | __| / __| __| |/ __/ __|", 0
stat_line_5	db " ____) | || (_| | |_| \__ \ |_| | (__\__ \", 0
stat_line_6	db "|_____/ \__\__,_|\__|_|___/\__|_|\___|___/", 0

exit_line_1	db "           ______        _  _             ", 0
exit_line_2	db "          |  ____|      (_)| |            ", 0
exit_line_3	db "          | |__   __  __ _ | |_           ", 0
exit_line_4	db "          |  __|  \ \/ /| || __|          ", 0
exit_line_5	db "          | |____  >  < | || |_           ", 0
exit_line_6	db "          |______|/_/\_\|_| \__|          ", 0

help_line	db "    PRESS <H> TO OPEN HELP                ", 0

help_line_1	db "          _    _        _                 ", 0
help_line_2	db "         | |  | |      | |                ", 0
help_line_3	db "         | |__| |  ___ | | _ __           ", 0
help_line_4	db "         |  __  | / _ \| || '_ \          ", 0
help_line_5	db "         | |  | ||  __/| || |_) |         ", 0
help_line_6	db "         |_|  |_| \___\|_|| ,__/          ", 0
help_line_7	db "                          | |             ", 0
help_line_8	db "                          |_|             ", 0

help_text_01	db "At the start, you have a hero with startup", 0
help_text_02	db "features, that you may look at Statistics ", 0
help_text_03	db "(Press <S> to open)                       ", 0

help_text_05	db "When you are ready to fight with computer ", 0
help_text_06	db "go to the tab 'Fight' (Press <F> to open) ", 0

help_text_08	db "You may RUN from fight, just hold down <Q>", 0

help_text_10	db "If you want to open Main Window, press Esc", 0

help_text_12	db "If you are tired you can leave the game   ", 0
help_text_13	db "(Press Esc + <E> to Exit without any save)", 0

lvl_up_line_1	db "Congratulation! You have reached level ", 0
lvl_up_line_2	db "      Choose a skill to upgrade:          ", 0
lvl_up_line_3	db "1)Atack 2)Defence 3)Stamina 4)Crit 5)Dodge", 0

mode_line_01	db "Choose difficult for your next fight:     ", 0
mode_line_02	db "1) Nooby                                  ", 0
mode_line_03	db "2) Stick                                  ", 0
mode_line_04	db "3) Looser                                 ", 0
mode_line_05	db "4) Lucky Man                              ", 0
mode_line_06	db "5) Bad Boy                                ", 0
mode_line_07	db "6) Killer                                 ", 0
mode_line_08	db "7) Fat Boy                                ", 0
mode_line_09	db "8) Kamikadze     (BEWARE)                 ", 0
mode_line_10	db "9) Wisp                                   ", 0
mode_line_11	db "0) Boss Level    (Achtung!)               ", 0
mode_line_12	db "If you aren't ready to fight, press Esc!  ", 0

empty_line	db "                                          ", 0		;42 char
empty_line_39	db "                                       ", 0			;39 char
empty_line_9	db "         ", 0						;9 char
empty_line_7	db "       ", 0							;7 char

fight_line_01	db "                                                            ", 0
fight_line_02	db "                                                            ", 0
fight_line_03	db "                                                            ", 0
fight_line_04	db "       __                                          __       ", 0
fight_line_05	db "      /  \                                        /  \      ", 0
fight_line_06	db "    _/=TL=\_       |                   |        _/=TL=\_    ", 0
fight_line_07	db "   [________]      |\                 /|       [________]   ", 0
fight_line_08	db "    ||/''\||       ||                 ||        ||/''\||    ", 0
fight_line_09	db "    ( 0..0 )       ||                 ||        ( 0..0 )    ", 0
fight_line_10	db "     \_--_/        ||                 ||         \_--_/     ", 0
fight_line_11	db "  .-[\!--!/]-.__   ||                 ||    __.-[\!--!/]-.  ", 0
fight_line_12	db " /  \      /    -. ||                 || .-'    \      /  \ ", 0
fight_line_13	db "/ _, '----'|-.__ 0wwwww0            0wwwww0 __.-|'----' ,_ \", 0
fight_line_14	db "\  \|      |    '~_ 3                 3  _~'    |      |/  /", 0
fight_line_15	db " \  >==[]==<       \|                 |/        >==[]==<  / ", 0
fight_line_16	db "  \/__.''.__\                                  /__.''.__\/  ", 0
fight_line_17	db "    |  __  |                                    |  __  |    ", 0
fight_line_18	db "    |  ||  |                                    |  ||  |    ", 0
fight_line_19	db "    |  ||  |                                    |  ||  |    ", 0
fight_line_20	db "    |  ||  |                                    |  ||  |    ", 0
fight_line_21	db "    |__||__|                                    |__||__|    ", 0
fight_line_22	db "    [__][__]                                    [__][__]    ", 0
fight_line_23	db "    |_ || _|                                    |_ || _|    ", 0
fight_line_24	db "    (__)(__)                                    (__)(__)    ", 0	;60 char

sword_pause_01	db "         /|  |\         ", 0
sword_pause_02	db "        //    \\        ", 0
sword_pause_03	db "       //      \\       ", 0
sword_pause_04	db "      //        \\      ", 0
sword_pause_05	db "     //          \\     ", 0
sword_pause_06	db "    //            \\    ", 0
sword_pause_07	db "._ //              \\ _.", 0
sword_pause_08	db "| wwww0          0wwww t", 0
sword_pause_09	db "~jp                  et~", 0
sword_pause_10	db "jp                    et", 0				;24 char

sword_n_h_01	db "             |\ //      ", 0
sword_n_h_02	db "              XX/       ", 0
sword_n_h_03	db "            ///\\       ", 0
sword_n_h_04	db "          ///   \\      ", 0
sword_n_h_05	db "        ///      \\     ", 0
sword_n_h_06	db " \\   ///         \\    ", 0
sword_n_h_07	db " \\\///            \\ _.", 0
sword_n_h_08	db "-,///            0wwww t", 0
sword_n_h_09	db "tll\\\               et~", 0
sword_n_h_10	db "l    \\               et", 0

sword_n_e_01	db "      \\ /|             ", 0
sword_n_e_02	db "       \XX              ", 0
sword_n_e_03	db "       //\\\            ", 0
sword_n_e_04	db "      //   \\\          ", 0
sword_n_e_05	db "     //      \\\        ", 0
sword_n_e_06	db "    //         \\\   // ", 0
sword_n_e_07	db "._ //            \\\/// ", 0
sword_n_e_08	db "| wwww0            \\\,-", 0
sword_n_e_09	db "~jp               ///ttr", 0
sword_n_e_10	db "jp               //    t", 0

sword_miss_01	db "                //   |  ", 0
sword_miss_02	db "              ///   /|  ", 0
sword_miss_03	db "            ///     ||  ", 0
sword_miss_04	db "          ///       ||  ", 0
sword_miss_05	db "        ///         ||  ", 0
sword_miss_06	db " \\   ///           ||  ", 0
sword_miss_07	db " \\\///             || .", 0
sword_miss_08	db "-,///            0wwwww0", 0
sword_miss_09	db "tll\\\              3 _~", 0
sword_miss_10	db "l    \\             |/  ", 0

sword_dodge_01	db "  |   \\                ", 0
sword_dodge_02	db "  |\   \\\              ", 0
sword_dodge_03	db "  ||     \\\            ", 0
sword_dodge_04	db "  ||       \\\          ", 0
sword_dodge_05	db "  ||         \\\        ", 0
sword_dodge_06	db "  ||           \\\   // ", 0
sword_dodge_07	db ". ||             \\\/// ", 0
sword_dodge_08	db "0wwww0             \\\,-", 0
sword_dodge_09	db "~_ 3              ///ttr", 0
sword_dodge_10	db "  \|             //    t", 0

sword_crit_01	db "               \ pu**  |", 0
sword_crit_02	db "          \  \ pum/*  //", 0
sword_crit_03	db "     _  \  \ pum/    // ", 0
sword_crit_04	db "   _  \  \ pum/     |/  ", 0
sword_crit_05	db "    \  \ pum/       ||  ", 0
sword_crit_06	db "  tt \ pum/         ||  ", 0
sword_crit_07	db "_ tpupum/           || .", 0
sword_crit_08	db " -,tp/            0wwww0", 0
sword_crit_09	db "~tll uwt            3 _~", 0
sword_crit_10	db "ll    tt            |/  ", 0

sword_ouch_01	db "|  **bu /               ", 0
sword_ouch_02	db "\\  *\bum /  /          ", 0
sword_ouch_03	db " \\    \bum /  /  _     ", 0
sword_ouch_04	db "  \|     \bum /  /  _   ", 0
sword_ouch_05	db "  ||       \bum /  /    ", 0
sword_ouch_06	db "  ||         \bum / rr  ", 0
sword_ouch_07	db ". ||           \bubumr _", 0
sword_ouch_08	db "0wwww0           \bum,- ", 0
sword_ouch_09	db "~_ 3            rbu ttr~", 0
sword_ouch_10	db "  \|            rr    tt", 0

b_fight_line_01	db "                                    \                       /                ", 0
b_fight_line_02	db "                                    |\   \        /        /|                ", 0
b_fight_line_03	db "                                   /  \  |\__  __/|       /  \               ", 0
b_fight_line_04	db "       __                         / /\ \ \ _ \/ _ /      /  ^ \              ", 0
b_fight_line_05	db "      /  \                       / / /\ \ (*}\/{*)      /  / \ \             ", 0
b_fight_line_06	db "    _/=TL=\_       |             | | | ) \( (oo) )     /  // |\ \            ", 0
b_fight_line_07	db "   [________]      |\            | | | |\ \(V''V)\    /  / | || \|           ", 0
b_fight_line_08	db "    ||/''\||       ||            | | | | \ |^__^| \  /  / || || ||           ", 0
b_fight_line_09	db "    ( 0..0 )       ||           / / /  | |\ WWWW__ \/  /| || || ||           ", 0
b_fight_line_10	db "     \_--_/        ||          | | | | | | \_______\  / / || || ||           ", 0
b_fight_line_11	db "  .-[\!--!/]-.__   ||          | | | / | | )|______\ ) | / | || ||           ", 0
b_fight_line_12	db " /  \      /    -. ||          / / /  / /  /______/   /| \ \ || ||           ", 0
b_fight_line_13	db "/ _, '----'|-.__ 0wwwww0      / / /  / /  /\_____/  |/ /__\ \ \ \ \          ", 0
b_fight_line_14	db "\  \|      |    '~_ 3         | | | / /  /\______/    \   \__| \ \ \         ", 0
b_fight_line_15	db " \  >==[]==<       \|         | | | | | |\______ __    \_    \__|_| \        ", 0
b_fight_line_16	db "  \/__.''.__\                 | | |___ /\______ /  \     \_       \  |       ", 0
b_fight_line_17	db "    |  __  |                  | |/    /\_______/    \      \__     \ |    /\ ", 0
b_fight_line_18	db "    |  ||  |                  |/ |   |\_______|      |        \___  \ |__/  \", 0
b_fight_line_19	db "    |  ||  |                  /  |   |\_______|      |            \___/     |", 0
b_fight_line_20	db "    |  ||  |                     |   |\_______|      |                    __/", 0
b_fight_line_21	db "    |__||__|                      \   \________\_    _\               ____/  ", 0
b_fight_line_22	db "    [__][__]                    __/   /\________/   /   )\__      _____/     ", 0
b_fight_line_23	db "    |_ || _|                   /  __ /  \uuuu/  __ /___]    \______/         ", 0
b_fight_line_24	db "    (__)(__)                   VVV  V        VVV  V                          ", 0	;77 char

boss_pause_01	db "         /|     | | | ) ", 0
boss_pause_02	db "        //      | | | |\", 0
boss_pause_03	db "       //       | | | | ", 0
boss_pause_04	db "      //       / / /  | ", 0
boss_pause_05	db "     //       | | | | | ", 0
boss_pause_06	db "    //        | | | / | ", 0
boss_pause_07	db "._ //         / / /  / /", 0
boss_pause_08	db "| wwww0      / / /  / / ", 0
boss_pause_09	db "~jp          | | | / /  ", 0
boss_pause_10	db "jp           | | | | | |", 0				;24 char

boss_n_h_01	db "                //**| ) ", 0
boss_n_h_02	db "              ///** | |\", 0
boss_n_h_03	db "            ///***| | | ", 0
boss_n_h_04	db "          /// ** / /  | ", 0
boss_n_h_05	db "        ///  *| | | | | ", 0
boss_n_h_06	db " \\   ///   * | | | / | ", 0
boss_n_h_07	db " \\\///       / / /  / /", 0
boss_n_h_08	db "-,///        / / /  / / ", 0
boss_n_h_09	db "tll\\\       | | | / /  ", 0
boss_n_h_10	db "l    \\      | | | | | |", 0

boss_n_e_01	db "     *   /|   * | | | ) ", 0
boss_n_e_02	db "        //      | | | |\", 0
boss_n_e_03	db "  *    //(*.*)=w| | | | ", 0
boss_n_e_04	db "      //(*.O.*)=w/ /  | ", 0
boss_n_e_05	db "     //  (*.*)=w| | | | ", 0
boss_n_e_06	db "    //*       | | | / | ", 0
boss_n_e_07	db "._ //         / / /  / /", 0
boss_n_e_08	db "| wwww0   *  / / /  / / ", 0
boss_n_e_09	db "~jp          | | | / /  ", 0
boss_n_e_10	db "jp           | | | | | |", 0

boss_miss_01	db "                | | | ) ", 0
boss_miss_02	db "                | | | |\", 0
boss_miss_03	db "            /|  | | | | ", 0
boss_miss_04	db "          / /  / / /  | ", 0
boss_miss_05	db "        / /   | | | | | ", 0
boss_miss_06	db " \\   / /     | | | / | ", 0
boss_miss_07	db " \ \/ /       / / /  / /", 0
boss_miss_08	db "-,/ /        / / /  / / ", 0
boss_miss_09	db "t l\ \       | | | / /  ", 0
boss_miss_10	db "l    \\      | | | | | |", 0

boss_dodge_01	db "  |             | | | ) ", 0
boss_dodge_02	db "  |\            | | | |\", 0
boss_dodge_03	db "  ||            | | | | ", 0
boss_dodge_04	db "  ||  (\|/)    / / /  | ", 0
boss_dodge_05	db "  ||  --O--   | | | | | ", 0
boss_dodge_06	db "  ||  (/|\)   | | | / | ", 0
boss_dodge_07	db ". ||          / / /  / /", 0
boss_dodge_08	db "0wwwww0      / / /  / / ", 0
boss_dodge_09	db "~_ 3         | | | / /  ", 0
boss_dodge_10	db "  \|         | | | | | |", 0

boss_crit_01	db "               \ pu*'** ", 0
boss_crit_02	db "          \  \ pum/'**|\", 0
boss_crit_03	db "     _  \  \ pum/'*** | ", 0
boss_crit_04	db "   _  \  \ pum/'** /  | ", 0
boss_crit_05	db "    \  \ pum/ ''' | | | ", 0
boss_crit_06	db "  tt \ pum/   | | | / | ", 0
boss_crit_07	db "_ tpupum/     / / /  / /", 0
boss_crit_08	db " -,tp/       / / /  / / ", 0
boss_crit_09	db "~tll uwt     | | | / /  ", 0
boss_crit_10	db "ll    tt     | | | | | |", 0

boss_ouch_01	db "   _ (*.*)=w    | | | ) ", 0
boss_ouch_02	db "  //(*.O.*)=w   | | | |\", 0
boss_ouch_03	db "  \\ (*.*)=w  (*.*)=w | ", 0
boss_ouch_04	db "  //         (*.O.*)=w| ", 0
boss_ouch_05	db "  \\ (*.*)=w  (*.*)=w | ", 0
boss_ouch_06	db "  //(*.O.*)=w | | | / | ", 0
boss_ouch_07	db ". \\ (*.*)=w  / / /  / /", 0
boss_ouch_08	db "0wwwww0      / / /  / / ", 0
boss_ouch_09	db "~_ 3         | | | / /  ", 0
boss_ouch_10	db "  \|         | | | | | |", 0

stat_atk_line	db "1) Atack:        ", 0
stat_def_line	db "2) Defence:      ", 0
stat_sta_line	db "3) Stamina:      ", 0
stat_acc_line	db "4) Crit chance:  ", 0
stat_dex_line	db "5) Dodge chance: ", 0					;17 char

stat_cur_exp	db "Your curent experience is: ", 0				;27 char
stat_need_exp	db "Experience border for Level Up: ", 0			;32 char

death_line_01	db "............____.......", 0
death_line_02	db ".........../   /\......", 0
death_line_03	db "....______/The/_/___...", 0
death_line_04	db ".../_____    ______/\..", 0
death_line_05	db "...\____/End/\_____\/..", 0
death_line_06	db "......./   / /.........", 0
death_line_07	db "....../   / /..........", 0
death_line_08	db "...../   / /...........", 0
death_line_09	db "..../___/ /............", 0
death_line_10	db "....\___\/.............", 0

graz_01		db "          /\                                    /\          ", 0
graz_02		db "         /  \          Congratulation          /  \         ", 0
graz_03		db "        (    )                                (    )        ", 0
graz_04		db "        | () |         You have slain         | () |        ", 0
graz_05		db "        | || |        the primal Evil!        | || |        ", 0
graz_06		db "        | || |                                | || |        ", 0
graz_07		db "        | || |              BUT               | || |        ", 0
graz_08		db "        | || |      Dragons poison touch      | || |        ", 0
graz_09		db "        | || |      has made its mission      | || |        ", 0
graz_10		db "        | || |                                | || |        ", 0
graz_11		db "        | || |         Poisoning soon         | || |        ", 0
graz_12		db "        | || |       killed the warrior       | || |        ", 0
graz_13		db "        | || |    But he is not forgotten!    | || |        ", 0
graz_14		db "        | || |                                | || |        ", 0
graz_15		db "        | || |       Rest In Peace hero       | || |        ", 0
graz_16		db "        | () |                                | () |        ", 0
graz_17		db "  |\____|''''|____/|                    |\____|''''|____/|  ", 0
graz_18		db "  | ______________ |                    | ______________ |  ", 0
graz_19		db "  |/    (__,,)    \|                    |/    (__,,)    \|  ", 0
graz_20		db "        (__,,)                                (__,,)        ", 0
graz_21		db "        (__,,)                                (__,,)        ", 0
graz_22		db "        (__,,)                                (__,,)        ", 0
graz_23		db "        / /\ \     Press <Esc> to continue    / /\ \        ", 0
graz_24		db "        \_\/_/                                \_\/_/        ", 0

end_stat_01	db "You have reached level ", 0					;23 char
end_stat_03	db "Your stats at killing BOSS:        ", 0			;35 char
end_stat_11	db "Quantity of battle, that you win:  ", 0
end_stat_13	db "Quantity of battle, you retreated: ", 0
end_stat_15	db "PRESS <Esc> TO LEAVE THE GAME      ", 0

slash		db "/", 0
iformat		db "%i", 0
sformat		db "%s", 0
end_line	db 0Dh, 0Ah, 0							;\r + \n

health_tab		db "²²", 0
empty_health_tab	db "__", 0

game_over_line_1	db "Sorry, but you have been slain.", 0			;31 char
game_over_line_2	db "Press <Esc> to exit the game.", 0			;29 char