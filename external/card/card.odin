package card

import colors "../odin-colors"
import "core:fmt"
import "core:strings"


T_L :: "╭─"
T_R :: "─╮"
B_L :: "╰─"
B_R :: "─╯"
H_L :: "─"
V_L :: "│"


hls :: proc(n: int) -> string {
	result := strings.repeat(H_L, n)
	return result
}

t_border :: proc(n: int) {
	t: []string = {T_L, hls(n), T_R}
	fmt.println(strings.concatenate(t))
}

c_content :: proc(title: []string) {
	D_H := fmt.tprintf("%s%s", colors.BLACK, colors.RESET)
	ls: string
	for i in title {
		ls = fmt.tprintf("%s %s %s", ls, i, D_H)
	}
	fmt.println(V_L, ls, V_L)
}

b_border :: proc(n: int) {
	b: []string = {B_L, hls(n), B_R}
	fmt.print(strings.concatenate(b))
}

charcunt :: proc(s: []string) -> int {
	t := len(s) + 2
	for i in s {
		t += strip_ansi(i)
	}
	return t
}

rounded :: proc(title: []string) {
	chars := charcunt(title)
	t_border(chars)
	c_content(title)
	b_border(chars)
	fmt.println("")
}

strip_ansi :: proc(s: string) -> int {
	result := 0
	inside_ansi := false

	for i in s {
		if i == '\x1b' {
			inside_ansi = true
		}
		if inside_ansi {
			if i == 'm' {
				inside_ansi = false
			}
		} else {
			result += 1
		}
	}
	return result
}
