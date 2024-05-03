HUGO_DEV_PORT = 1313
HUGO_HOMEPAGE = $(shell hugo config --format json \
		| jq --raw-output '.baseurl' \
		| sed 's|https://\([^/]\+\)/|http://127.0.0.1/|' \
		| sed 's|127.0.0.1|127.0.0.1:$(HUGO_DEV_PORT)|')
HUGO_SERVER_OPTS = --noHTTPCache --buildDrafts --renderToMemory

.PHONY: theme
theme:
	git submodule update --init --recursive

serve: theme
	hugo --quiet version
	(sleep 1 ; xdg-open $(HUGO_HOMEPAGE)) >/dev/null 2>&1 &
	hugo server $(HUGO_SERVER_OPTS)

.PHONY: PRINT-MACROS
PRINT-MACROS:
	@make --print-data-base \
		| grep -A1 "^# makefile" \
		| grep -v "^#\|^--" \
		| sort
