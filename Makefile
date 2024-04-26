serve:
	hugo --quiet version
	(sleep 1 ; xdg-open http://localhost:1313/blog) >/dev/null 2>&1 &
	hugo server --noHTTPCache --buildDrafts
