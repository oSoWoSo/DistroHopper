#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	git init --bare --quiet "$TEST_DIR/remote.git"
	git init --quiet --initial-branch=main "$TEST_DIR/source"
	cd "$TEST_DIR/source"
	git config user.name Test
	git config user.email test@example.com
	printf 'source\n' > source.txt
	git add source.txt
	git commit --quiet -m source
	git remote add origin "$TEST_DIR/remote.git"
	git push --quiet origin main
	mkdir website
	printf '<html>First</html>\n' > website/index.html
	printf 'old\n' > website/old.html
}

teardown() {
	rm -rf "$TEST_DIR"
}

@test "website publishing creates the branch without changing the source checkout" {
	run bash "$REPO_ROOT/scripts/publish-website-branch" website
	[ "$status" -eq 0 ]
	[ "$(git branch --show-current)" = main ]
	[ "$(git show HEAD:source.txt)" = source ]
	[ -s website/index.html ]
	[ "$(git --git-dir="$TEST_DIR/remote.git" show website:index.html)" = '<html>First</html>' ]
	run git --git-dir="$TEST_DIR/remote.git" cat-file -e website:source.txt
	[ "$status" -ne 0 ]
	[ "$(git worktree list --porcelain | grep -c '^worktree ')" -eq 1 ]
	! git branch --list 'website-publish-*' | grep -q .
}

@test "website publishing preserves history, removes stale files and skips unchanged builds" {
	bash "$REPO_ROOT/scripts/publish-website-branch" website
	first=$(git --git-dir="$TEST_DIR/remote.git" rev-parse website)
	run bash "$REPO_ROOT/scripts/publish-website-branch" website
	[ "$status" -eq 0 ]
	[ "$(git --git-dir="$TEST_DIR/remote.git" rev-parse website)" = "$first" ]
	[[ "$output" == *'already matches'* ]]
	rm website/old.html
	printf '<html>Second</html>\n' > website/index.html
	run bash "$REPO_ROOT/scripts/publish-website-branch" website
	[ "$status" -eq 0 ]
	[ "$(git --git-dir="$TEST_DIR/remote.git" rev-parse website^)" = "$first" ]
	[ "$(git --git-dir="$TEST_DIR/remote.git" show website:index.html)" = '<html>Second</html>' ]
	run git --git-dir="$TEST_DIR/remote.git" cat-file -e website:old.html
	[ "$status" -ne 0 ]
}

@test "website publishing rejects empty builds and private configuration" {
	rm website/index.html
	run bash "$REPO_ROOT/scripts/publish-website-branch" website
	[ "$status" -ne 0 ]
	printf '<html>Test</html>\n' > website/index.html
	printf 'secret\n' > website/.env
	run bash "$REPO_ROOT/scripts/publish-website-branch" website
	[ "$status" -ne 0 ]
	run git --git-dir="$TEST_DIR/remote.git" rev-parse --verify website
	[ "$status" -ne 0 ]
}

@test "website publishing fails on remote errors rather than treating them as a missing branch" {
	git remote set-url origin "$TEST_DIR/missing.git"
	run bash "$REPO_ROOT/scripts/publish-website-branch" website
	[ "$status" -ne 0 ]
	[ "$(git branch --show-current)" = main ]
	[ "$(git worktree list --porcelain | grep -c '^worktree ')" -eq 1 ]
}
