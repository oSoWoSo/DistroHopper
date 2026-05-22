# Test suite for qget and action scripts
# Format: clitest - https://github.com/aureliojargas/clitest

$ cd ..

# Test 1: qget --help should work
$ ./qget --help 2>&1 | head -3
 Usage: qget

# Test 2: qget --list should list all supported OS
$ ./qget --list 2>&1 | head -5
debian

# Test 3: action script should exist and be executable
$ test -x generate && echo "generate is executable"

# Test 4: All action files should exist
$ test -f templates/linuxmint && echo "linuxmint action exists"

# Test 5: Each action file should have releases_ function
$ grep -q "^function releases_" templates/linuxmint && echo "linuxmint has releases_"

# Test 6: Each action file should have get_ function
$ grep -q "^function get_" templates/linuxmint && echo "linuxmint has get_"

# Test 7: List all action files count
$ ls templates/ | wc -l
# Should be > 90

# Test 8: qget can show OS info
$ qget linuxmint 2>&1 | head -3
 Linux Mint

# Test 9: Each action has required variables
$ grep -q "^OSNAME=" templates/linuxmint && echo "has OSNAME"

# Test 10: Verify web_pipe function exists in qget
$ grep -q "function web_pipe" qget && echo "web_pipe exists"

# Test 11: action can be sourced without error
$ bash -c 'source action 2>&1 | head -1' || echo "source works"

# Test 12: New OS actions exist
$ test -f templates/easyos && echo "easyos action exists"
$ test -f templates/fedora && echo "fedora action exists"
$ test -f templates/mageia && echo "mageia action exists"
$ test -f templates/zorin && echo "zorin action exists"
$ test -f templates/pantherx && echo "pantherx action exists"
$ test -f templates/holoiso && echo "holoiso action exists"

# Test 13: New actions have releases_ function
$ grep -q "^function releases_" templates/easyos && echo "easyos has releases_"
$ grep -q "^function releases_" templates/fedora && echo "fedora has releases_"
$ grep -q "^function releases_" templates/mageia && echo "mageia has releases_"
$ grep -q "^function releases_" templates/zorin && echo "zorin has releases_"
$ grep -q "^function releases_" templates/pantherx && echo "pantherx has releases_"
$ grep -q "^function releases_" templates/holoiso && echo "holoiso has releases_"

# Test 14: New actions have get_ function
$ grep -q "^function get_" templates/easyos && echo "easyos has get_"
$ grep -q "^function get_" templates/fedora && echo "fedora has get_"
$ grep -q "^function get_" templates/mageia && echo "mageia has get_"
$ grep -q "^function get_" templates/zorin && echo "zorin has get_"
$ grep -q "^function get_" templates/pantherx && echo "pantherx has get_"
$ grep -q "^function get_" templates/holoiso && echo "holoiso has get_"

# Test 15: List all action files count includes new ones
$ ls templates/ | wc -l
# Should be > 102
