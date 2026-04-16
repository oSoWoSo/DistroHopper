# Test suite for qget and action scripts
# Format: clitest - https://github.com/aureliojargas/clitest

$ cd /home/z/8T/git/dh

# Test 1: qget --help should work
$ qget --help 2>&1 | head -3
 Usage: qget

# Test 2: qget --list should list all supported OS
$ qget --list 2>&1 | head -5
debian

# Test 3: action script should exist and be executable
$ test -x action && echo "action is executable"

# Test 4: All action files should exist
$ test -f actions/linuxmint && echo "linuxmint action exists"

# Test 5: Each action file should have releases_ function
$ grep -q "^function releases_" actions/linuxmint && echo "linuxmint has releases_"

# Test 6: Each action file should have get_ function
$ grep -q "^function get_" actions/linuxmint && echo "linuxmint has get_"

# Test 7: List all action files count
$ ls actions/ | wc -l
# Should be > 90

# Test 8: qget can show OS info
$ qget linuxmint 2>&1 | head -3
 Linux Mint

# Test 9: Each action has required variables
$ grep -q "^OSNAME=" actions/linuxmint && echo "has OSNAME"

# Test 10: Verify web_pipe function exists in qget
$ grep -q "function web_pipe" qget && echo "web_pipe exists"

# Test 11: action can be sourced without error
$ bash -c 'source action 2>&1 | head -1' || echo "source works"

# Test 12: New OS actions exist
$ test -f actions/easyos && echo "easyos action exists"
$ test -f actions/fedora && echo "fedora action exists"
$ test -f actions/mageia && echo "mageia action exists"
$ test -f actions/zorin && echo "zorin action exists"
$ test -f actions/pantherx && echo "pantherx action exists"
$ test -f actions/holoiso && echo "holoiso action exists"

# Test 13: New actions have releases_ function
$ grep -q "^function releases_" actions/easyos && echo "easyos has releases_"
$ grep -q "^function releases_" actions/fedora && echo "fedora has releases_"
$ grep -q "^function releases_" actions/mageia && echo "mageia has releases_"
$ grep -q "^function releases_" actions/zorin && echo "zorin has releases_"
$ grep -q "^function releases_" actions/pantherx && echo "pantherx has releases_"
$ grep -q "^function releases_" actions/holoiso && echo "holoiso has releases_"

# Test 14: New actions have get_ function
$ grep -q "^function get_" actions/easyos && echo "easyos has get_"
$ grep -q "^function get_" actions/fedora && echo "fedora has get_"
$ grep -q "^function get_" actions/mageia && echo "mageia has get_"
$ grep -q "^function get_" actions/zorin && echo "zorin has get_"
$ grep -q "^function get_" actions/pantherx && echo "pantherx has get_"
$ grep -q "^function get_" actions/holoiso && echo "holoiso has get_"

# Test 15: List all action files count includes new ones
$ ls actions/ | wc -l
# Should be > 102
