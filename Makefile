serve:
	hugo --quiet version
	(sleep 1 ; xdg-open localhost:1313) >/dev/null 2>&1 &
	hugo server --noHTTPCache --buildDrafts
