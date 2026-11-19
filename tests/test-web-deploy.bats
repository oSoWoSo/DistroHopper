#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	PROJECT="$TEST_DIR/project"
	mkdir -p "$PROJECT/website-source" "$TEST_DIR/bin" "$TEST_DIR/outside"
	cp "$REPO_ROOT/web-deploy" "$REPO_ROOT/lib.sh" "$PROJECT/"
	printf "TITLE='Deploy Test'\n" > "$PROJECT/website-source/.env"
	export BUILD_MARKER="$TEST_DIR/built" BUILD_STATUS=0
	export SURFER_ARGS="$TEST_DIR/surfer-args" SURFER_STATUS=0 SURFER_SITE_NAME=dh
	unset SURFER_SERVER SURFER_USER SURFER_TOKEN SURFER_MESSAGE OUT_DIR
	export WEB_DEPLOY_CHOICE='Build this website'
	mkdir -p "$PROJECT/website"
	printf '<html>Test site</html>\n' > "$PROJECT/website/index.html"
	cat > "$PROJECT/web-create" <<'EOF'
#!/usr/bin/env bash
printf '%s|%s\n' "$PWD" "$*" > "$BUILD_MARKER"
exit "$BUILD_STATUS"
EOF
	cat > "$TEST_DIR/bin/gum" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	choose) echo "$WEB_DEPLOY_CHOICE" ;;
	style|confirm) exit 0 ;;
	*) exit 99 ;;
esac
EOF
	cat > "$TEST_DIR/bin/surfer" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$SURFER_ARGS"
exit "$SURFER_STATUS"
EOF
	chmod +x "$PROJECT/web-create" "$TEST_DIR/bin/gum" "$TEST_DIR/bin/surfer"
	export PATH="$TEST_DIR/bin:$PATH"
	cd "$TEST_DIR/outside"
}

teardown() {
	rm -rf "$TEST_DIR"
}

@test "web-deploy builds this repository without requiring LIST" {
	run "$PROJECT/web-deploy"
	[ "$status" -eq 0 ]
	[[ "$output" != *'LIST is empty'* ]]
	[ "$(< "$BUILD_MARKER")" = "$PROJECT|-b" ]
}

@test "web-deploy provides a non-interactive build with website-source config" {
	run "$PROJECT/web-deploy" --build
	[ "$status" -eq 0 ]
	[ "$(< "$BUILD_MARKER")" = "$PROJECT|-b" ]
	[[ "$output" == *"Using $PROJECT/website-source/.env"* ]]
}

@test "web-deploy propagates standalone build failures" {
	export BUILD_STATUS=42
	run "$PROJECT/web-deploy" --build
	[ "$status" -eq 42 ]
}

@test "web-deploy exit does not build or publish anything" {
	export WEB_DEPLOY_CHOICE=Exit
	run "$PROJECT/web-deploy"
	[ "$status" -eq 0 ]
	[ ! -e "$BUILD_MARKER" ]
}

@test "web-deploy retains multi-repository LIST builds" {
	printf 'LIST=("%s")\n' "$PROJECT" > "$PROJECT/.env"
	export WEB_DEPLOY_CHOICE='Build all repos'
	run "$PROJECT/web-deploy"
	[ "$status" -eq 0 ]
	[ "$(< "$BUILD_MARKER")" = "$PROJECT|-b" ]
}

@test "web-deploy help does not require config and distinguishes building from publishing" {
	rm "$PROJECT/website-source/.env"
	run "$PROJECT/web-deploy" --help
	[ "$status" -eq 0 ]
	[[ "$output" == *'LIST is optional'* ]]
	[[ "$output" == *'no publishing'* ]]
	[ ! -e "$BUILD_MARKER" ]
}

@test "web-deploy publishes the built directory using saved Surfer configuration" {
	run "$PROJECT/web-deploy" --surfer
	[ "$status" -eq 0 ]
	[ "$(< "$SURFER_ARGS")" = "$(printf 'deploy\n%s/website\n--site-name\ndh' "$PROJECT")" ]
	[ ! -e "$BUILD_MARKER" ]
}

@test "web-deploy passes explicit CI credentials without printing them" {
	export SURFER_SERVER=https://surfer.example.com SURFER_USER='CI user'
	export SURFER_TOKEN='test password with spaces' SURFER_MESSAGE='Build abc123'
	run "$PROJECT/web-deploy" --surfer
	[ "$status" -eq 0 ]
	grep -qx -- '--server' "$SURFER_ARGS"
	grep -qx 'https://surfer.example.com' "$SURFER_ARGS"
	grep -qx 'CI user' "$SURFER_ARGS"
	grep -qx 'test password with spaces' "$SURFER_ARGS"
	grep -qx 'Build abc123' "$SURFER_ARGS"
	[[ "$output" != *'test password with spaces'* ]]
}

@test "web-deploy propagates Surfer upload failure" {
	export SURFER_STATUS=17
	run "$PROJECT/web-deploy" --surfer
	[ "$status" -eq 17 ]
}

@test "web-deploy builds before publishing in combined mode" {
	run "$PROJECT/web-deploy" --build-and-deploy
	[ "$status" -eq 0 ]
	[ -e "$BUILD_MARKER" ]
	[ -e "$SURFER_ARGS" ]
}

@test "web-deploy does not upload when the build fails" {
	export BUILD_STATUS=42
	run "$PROJECT/web-deploy" --build-and-deploy
	[ "$status" -eq 42 ]
	[ ! -e "$SURFER_ARGS" ]
}

@test "web-deploy refuses an unbuilt directory and private configuration" {
	rm "$PROJECT/website/index.html"
	run "$PROJECT/web-deploy" --surfer
	[ "$status" -ne 0 ]
	[ ! -e "$SURFER_ARGS" ]
	printf '<html>Test</html>\n' > "$PROJECT/website/index.html"
	printf 'SECRET=test\n' > "$PROJECT/website/.env"
	run "$PROJECT/web-deploy" --surfer
	[ "$status" -ne 0 ]
	[ ! -e "$SURFER_ARGS" ]
}

@test "web-deploy requires an explicit site and complete credential overrides" {
	unset SURFER_SITE_NAME
	run "$PROJECT/web-deploy" --surfer
	[ "$status" -ne 0 ]
	[ ! -e "$SURFER_ARGS" ]
	export SURFER_SITE_NAME=dh SURFER_USER='CI user'
	run "$PROJECT/web-deploy" --surfer
	[ "$status" -ne 0 ]
	[ ! -e "$SURFER_ARGS" ]
}
