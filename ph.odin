package main

import "base:runtime"
import "core:c"
import "core:encoding/json"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:strings"
import card "external/card"
import curl "external/curl"
import fetch "external/fetch"
import colors "external/odin-colors"


DEFAULT_MAIN := "package main\n\nimport \"core:fmt\"\n\nmain :: proc() {\n\tfmt.println(\"Ready to lock in, anon?\")\n}"
MAKEFILE := "run:\n\todin run src/main.odin -file\n\nb:\n\t@odin build src/main.odin -out=build/%s -n -file\n\t./build/%s \n\n"
PROJECT_DIRS :: []string{"build", "vendor", "src", "tests"}
SRC_DIRS :: []string{"core", "config", "lib"}
README_GIST_ID :: "ebd078a337c17cbb6484a6f1ba5bffea"

main :: proc() {

	validate_args(os.args)

	/* [commands] */
	switch os.args[1] {
	case "create":
		create()
	case "run":
		run()
	case "test":
		test()
	case "build":
		build()
	case "help":
		help()
	case "-h":
		help()
	case "--help":
		help()
	case "version":
		cli_version()
	case "-v":
		cli_version()
	case "--version":
		cli_version()
	case "":
		print_usage()
	case:
		// default
		print_usage()
	}
}

tmpl_project_name :: proc(name: string) -> string {
	return fmt.tprintf("%s%s%s", colors.BRIGHT_CYAN, name, colors.RESET)
}
create :: proc() {
	using os

	project_name := tmpl_project_name(os.args[2])
	project := os.args[2]
	root_dir := get_current_directory()

	check_project_name(project)

	fmt.printf("\n %s\n", c_title("creating ⋯"))
	params := []string{"project:", project_name}
	card.rounded(params)

	fmt.printf(" %s\n", c_title("build started"))
	make_directory(project)
	set_current_directory(project)

	makefile := fmt.tprintf(MAKEFILE, project, project)
	touch("Makefile", makefile)

	gist := gist_content(README_GIST_ID)
	touch("README.md", gist)

	mkdirs(PROJECT_DIRS)

	set_current_directory("src")
	touch("main.odin", DEFAULT_MAIN)
	mkdirs(SRC_DIRS)


	fmt.printf("\n done.\n\n")
}

check_project_name :: proc(project: string) {
	if os.is_dir(project) {
		fmt.printf("\ndirectory with %s already exists.\n", project)
		os.exit(1)
	}
}
mkdirs :: proc(dirs: []string) {
	for d in dirs {
		os.make_directory(d)
	}
}
touch :: proc(filename: string, content: string) {
	os.write_entire_file(filename, transmute([]byte)content)
}
cli_version :: proc() {
	version := fmt.tprintf("%s%s%s", colors.BRIGHT_CYAN, "(ph) version 0.0.2", colors.RESET)
	fmt.printf("\n%s\n", version)
}
c_title :: proc(c: string) -> string {
	return fmt.tprintf("%s%s%s", colors.BLUE, c, colors.RESET)
}
run :: proc() {
	fmt.printf("\n %s %s\n", c_title("run"), "running the project in dev mode...")
}
build :: proc() {
	fmt.printf("\n %s %s\n", c_title("creating ⋯"), "project")

	params := []string{"name"}
	card.rounded(params)

}
help :: proc() {
	print_usage()
}

print_usage :: proc() {
	commands := []string{"create", "run", "test", "build", "help"}
	definitions := []string {
		"use to create a new project",
		"to run the project in dev mode",
		"test to test the project",
		"build to build the project",
		"help to get help",
	}
	header := "\n usage: \n\n"
	high_b :: proc(text: string) -> string {
		return fmt.tprintf("%s%s%s", colors.BLUE, text, colors.RESET)
	}
	format := fmt.tprintf(
		"%s ph [%s] <%s%s%s>\n",
		header,
		high_b("command"),
		colors.BRIGHT_CYAN,
		"project name",
		colors.RESET,
	)

	fmt.println(format)

	gen_tab :: proc(t: string) -> string {
		t_len := card.strip_ansi(t)
		dots := strings.repeat("ꔷ", 12 - t_len)
		return fmt.tprintf(" %s%s%s", colors.BLACK, dots, colors.RESET)
	}
	for c, i in commands {
		fmt.printf(" %s%s%s\n", high_b(c), gen_tab(c), definitions[i])
	}

	os.exit(1)
}

validate_args :: proc(args: []string) {

	if len(args) < 2 {
		print_usage()
	}
	if args[1] == "create" && len(args) < 3 {
		print_usage()
	}
}

write_from_file :: proc(from: string, to: string) {
	cwd := fmt.tprintf(os.get_current_directory())
	path := fmt.tprintf("%s/libs/%s", cwd, from)
	o_path := fmt.tprintf("%s/%s", cwd, to)
	handle, err := os.open(path)

	if err != nil {
		fmt.printf("⛌ Error opening file from path %s: %v\n", path, err)
	}

	content, rerr := os.read_entire_file_from_handle(handle)
	if !rerr {
		fmt.printf("⛌ Error reading file from path %s: %v\n", path, rerr)
	}

	written := os.write_entire_file(o_path, transmute([]byte)content)
	if written {
		fmt.printf("⋯ %s created\n", to)
	}
	defer os.close(handle)
}


gist_content :: proc(id: string) -> string {

	content: string

	buf := fetch.ResponseBuffer {
		data      = "",
		allocator = context.allocator,
	}

	fetch.buf_content(id, &buf)

	if not_empty(buf.data) do content = parse_gist(buf.data)

	return content
}

parse_gist :: proc(data: string) -> string {
	json_v, err := json.parse(transmute([]u8)data)

	if err != nil {
		fmt.eprintln("Unabled to parse json")
	}

	filename: json.Value
	content: json.Value

	for i, j in json_v.(json.Object) {
		if i == "files" {
			for k, l in j.(json.Object) {
				filename = k
				for m, n in l.(json.Object) {
					if m == "content" {
						content = n
					}
				}
			}
		}
	}


	defer json.destroy_value(json_v)
	return content.(json.String)
}

not_empty :: proc(data: string) -> bool {
	ok := len(data) > 0
	return ok
}

Env :: struct {
	key:   string,
	value: string,
}

load_env :: proc() -> [dynamic]Env {

	vars := make([dynamic]Env)

	data, ok := os.read_entire_file(".env")
	defer delete(data)

	if !ok {
		fmt.eprintf(" Error loading environment vars in path: %s\n ERR: %v\n", ".env")
	}

	lines := strings.split_lines(string(data))
	for line in lines {
		// Ignore empty lines and comments
		line := strings.trim_space(line)
		if line == "" || strings.has_prefix(line, "#") {
			continue
		}

		// Split key and value
		parts := strings.split(line, "=")
		defer delete(parts)

		if len(parts) >= 2 {
			key := strings.trim_space(parts[0])
			value := strings.trim_space(strings.join(parts[1:], "=")) // Handles values with `=` characters
			value = strings.trim(value, "\"")

			os.set_env(key, value)
			append(&vars, Env{key, value})
		}


	}

	return vars
}

test :: proc() {
	fmt.printf("\n %s %s\n", c_title("running ⋯"), "test")
	vars := load_envs()
	for v, i in vars {
		fmt.printf("pair %d: %s", i + 1, v)
	}
}

load_envs :: proc() -> [dynamic]string {
	vars: [dynamic]string

	// Try to read .env file
	data, ok := os.read_entire_file(".env")
	if !ok {
		fmt.eprintln("Could not read .env file")
		return vars
	}
	defer delete(data)

	// Convert to string and split by lines
	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	// Process each line
	for line in lines {
		line := strings.trim_space(line)
		if line == "" || strings.has_prefix(line, "#") {
			continue
		}

		// Split by first = character
		parts := strings.split(line, "=")
		defer delete(parts)

		if len(parts) >= 2 {
			key := strings.trim_space(parts[0])
			// Join remaining parts in case value contains = characters
			value := strings.trim_space(strings.join(parts[1:], "="))

			// Remove quotes if present
			value = strings.trim(value, "\"'")

			pairs := fmt.tprintf("%s -> %s\n", key, value)
			append(&vars, pairs)
			// Set environment variable
			os.set_env(key, value)

			// Store in our array
		}
	}

	return vars
}
