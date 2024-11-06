package fetch

import curl "../curl"
import "base:runtime"
import "core:c"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"


// BASE_URL :: "https://ui.shadcn.com"
BASE_URL :: "https://api.github.com/gists"

Gist_Owner :: struct {
	login:               string,
	id:                  int,
	node_id:             string,
	avatar_url:          string,
	gravatar_id:         string,
	url:                 string,
	html_url:            string,
	followers_url:       string,
	following_url:       string,
	gists_url:           string,
	starred_url:         string,
	subscriptions_url:   string,
	organizations_url:   string,
	repos_url:           string,
	events_url:          string,
	received_events_url: string,
	type:                string,
	user_view_type:      string,
	site_admin:          string,
}

Gist_File :: struct {
	filename: string,
	type:     string,
	language: Maybe(string),
	raw_url:  string,
	size:     int,
	content:  string,
}

Gist :: struct {
	url:         string,
	files:       Gist_File,
	description: Maybe(string),
	public:      bool,
	created_at:  string,
	updated_at:  string,
	owner:       Gist_Owner,
}


ResponseBuffer :: struct {
	data:      string,
	allocator: runtime.Allocator,
}


write_cb :: proc "c" (
	data: rawptr,
	size: c.size_t,
	nmemb: c.size_t,
	userdata: rawptr,
) -> c.size_t {
	buf := (^ResponseBuffer)(userdata)
	c := (^runtime.Context)(userdata)
	context = c^
	data := strings.string_from_ptr((^u8)(data), (int)(size * nmemb))

	if len(data) < 1 {
		buf.data = strings.clone(data, buf.allocator)
	}

	if len(data) > 0 {
		old_boy := buf.data
		buf.data = strings.concatenate({old_boy, data}, buf.allocator)
		delete(old_boy, buf.allocator)
	}
	return size * nmemb
}

buf_content :: proc(gist_id: string, buf: ^ResponseBuffer) {

	url := fmt.tprintf("%s/%s", BASE_URL, gist_id)
	handle := curl.easy_init()
	if handle == nil {
		fmt.println("Failed to initialize curl.")
		return
	}
	url_encoded := curl.easy_escape(nil, raw_data(url), len(url))
	// fmt.println(url)
	// fmt.println(url_encoded)
	curl.free(url_encoded)


	// Setup headers
	content_type := "Content-Type: application/json"
	user_agent := "User-Agent: PhClient Odincurl/1.2"
	// accept := "Accept: application/json"

	headers: ^curl.SList
	headers = add_header(headers, content_type)
	headers = add_header(headers, user_agent)
	defer free_headers(headers)


	// Make request
	curl.easy_setopt(handle, curl.CurlOption.URL, url) // `10002` is the CURLOPT_URL option in libcurl
	// curl.easy_setopt(handle, curl.CurlOption.RANGE, "1-15000")
	curl.easy_setopt(handle, curl.CurlOption.WRITEFUNCTION, write_cb)
	curl.easy_setopt(handle, curl.CurlOption.VERBOSE, (c.long)(0))
	curl.easy_setopt(handle, curl.CurlOption.HTTPHEADER, headers)

	curl.easy_setopt(handle, curl.CurlOption.WRITEDATA, buf)
	res := curl.easy_perform(handle)
	defer curl.easy_cleanup(handle)

	if res != curl.CurlCode.OK {
		fmt.panicf("curl.easy_perform() has failed: %s", curl.easy_strerror(res))
	}
}


free_headers :: proc(headers: ^curl.SList) {
	curl.slist_free_all(headers)
}

add_header :: proc(headers: ^curl.SList, h: string) -> ^curl.SList {
	return curl.slist_append(headers, raw_data(h))
}
