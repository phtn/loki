package card

import "core:fmt"
import "core:strings"


T_L :: "╭"
T_R :: "╮"
B_L :: "╰"
B_R :: "╯"
H_L :: "─"
V_L :: "│"
PADDING :: 3


hls :: proc(n: int) -> string {
	result := strings.repeat(H_L, n)
	return result
}

t_border :: proc(n: int) {
	t: []string = {T_L, hls(n), T_R}
	fmt.println(strings.concatenate(t))
}

content_text :: proc(title: []string) -> string {
	text: string
	for item, index in title {
		if index > 0 {
			text = fmt.tprintf("%s %s", text, item)
		} else {
			text = item
		}
	}
	return text
}

c_content :: proc(title: []string, width: int) {
	text := content_text(title)
	visible := strip_ansi(text)
	padding := width - visible
	left_padding := padding / 2
	right_padding := padding - left_padding
	fmt.printf(
		"%s%s%s%s%s\n",
		V_L,
		strings.repeat(" ", left_padding),
		text,
		strings.repeat(" ", right_padding),
		V_L,
	)
}

b_border :: proc(n: int) {
	b: []string = {B_L, hls(n), B_R}
	fmt.print(strings.concatenate(b))
}

charcunt :: proc(s: []string) -> int {
	return strip_ansi(content_text(s)) + PADDING * 2
}

rounded :: proc(title: []string) {
	chars := charcunt(title)
	t_border(chars)
	c_content(title, chars)
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
