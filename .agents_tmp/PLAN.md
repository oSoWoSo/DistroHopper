# 1. OBJECTIVE

Add supported Linux distributions to the DistroHopper website (dh.osowoso.org) with:
1. **Distros page** - Card grid showing all distros from `public/` directory with real information (name, homepage, description)
2. **Download button** - Button that opens version/edition dropdown with direct download links
3. **"all" page** - Page showing ALL distributions from the previous distributionhub project
4. **CI link checking** - Links verified automatically by CI

The UI must follow site's light/dark theme toggle and match existing DistroHopper design (Courier New font, green/yellow accents, card-based layout).

# 2. CONTEXT SUMMARY

- **Website**: dh.osowoso.org - static Jekyll site in `docs/` directory
- **Domain**: Configured via CNAME (dh.osowoso.org)
- **Theme System**: CSS custom properties with `[data-theme="light"]` / `[data-theme="dark"]`
- **Data Source**: `public/` directory contains ~100 distro template files with:
  - `OSNAME`, `PRETTY`, `DESCRIPTION`, `HOMEPAGE` - basic info
  - `RELEASES` - available versions (e.g., "12.11.0 11.11.0")
  - `EDITIONS` - desktop editions (e.g., "xfce mate lxde kde gnome")
  - `get_()` function - builds download URL
- **Current State**: Homepage shows project info but no distro listing

# 3. APPROACH OVERVIEW

1. **Parse public/ templates**: Extract distro data (name, homepage, releases, editions) from `public/*` files
2. **Create distros.html**: Card grid with each distro linking to its HOMEPAGE
3. **Add download modal**: Button per card opens dropdown with version/edition options + direct download links
4. **Create all.html**: Page for ALL distributions (from previous distributionhub)
5. **Style for theme**: Cards use CSS variables for automatic light/dark theme support
6. **Add nav links**: "Distros" and "All" links in navigation

# 4. IMPLEMENTATION STEPS

### Step 1: Parse public/ templates and generate distro data
- **Goal**: Extract all distro information from `public/*` files
- **Method**: Parse each file to extract:
  - `PRETTY` or `OSNAME` - display name
  - `HOMEPAGE` - official website URL
  - `DESCRIPTION` - one-line description
  - `RELEASES` - available versions
  - `EDITIONS` - available editions
- **Reference**: `public/` directory (~100 files)
- **Output**: JSON/data structure for website to use

### Step 2: Create distros.html page
- **Goal**: Display all supported distros in card grid
- **Method**: 
  1. Use existing HTML template from `docs/index.html`
  2. Create CSS grid of distro cards (responsive `auto-fill` layout)
  3. Each card shows: PRETTY name, DESCRIPTION, Download button
  4. Each card links to distro's HOMEPAGE
- **Reference**: `docs/index.html`, `docs/style.css`

### Step 3: Add download button with release × edition table
- **Goal**: Button per distro opens table showing all release × edition combinations
- **Method**: 
  1. Add "Download" button to each distro card
  2. On click, open modal/panel with table:
     - **Rows**: Available RELEASE versions (e.g., 12.11.0, 11.11.0)
     - **Columns**: Available EDITIONS (e.g., xfce, mate, kde, gnome)
     - **Cells**: Clickable links to direct ISO downloads
  3. Can mark specific release/edition combinations as **disabled** (grayed out) if not available
- **UI Example**:
  ```
         | xfce    | mate    | kde     | gnome   | standard
  ------+---------+---------+---------+---------+----------
  12.x  | [DL]    | [DL]    | [DL]    | [DL]    | [DL]
  11.x  | [DL]    | [DL]    | [X]     | [DL]    | [DL]
  10.x  | [DL]    | [X]     | [X]     | [X]     | [X]
  
  [DL] = available  [X] = disabled/grayed out
  ```
- **Reference**: `public/*` files have RELEASES, EDITIONS, and get_() function

### Step 4: Create all.html page for distributionhub distros
- **Goal**: Page showing ALL distributions from previous distributionhub project
- **Method**: 
  1. Create `all.html` page similar structure to distros.html
  2. Include additional distros that were in distributionhub
  3. Add link from main navigation
- **Reference**: Separate list or combined with main distros

### Step 5: Style distro cards for theme compatibility
- **Goal**: Cards work with light/dark theme toggle
- **Method**: Use existing CSS variables:
  - `--bg-light` for card background
  - `--border-color` for borders
  - `--link-color` for links
  - `--green` for hover/accent
- **Reference**: `docs/style.css`

### Step 6: Add navigation links
- **Goal**: Make pages accessible from main site
- **Method**: Add to nav in both `index.html` and new pages:
  - `<li><a href="distros.html">Distros</a></li>`
  - `<li><a href="all.html">All</a></li>`
- **Reference**: `docs/index.html` nav section

### Step 7: Add CI link checking structure
- **Goal**: Links should be verifiable by CI
- **Method**: 
  1. Use HOMEPAGE URLs from templates (already real URLs)
  2. Add `rel="external"` or specific class for CI to check
  3. CI can be configured separately to verify these links

# 5. TESTING AND VALIDATION

- **Visual Check**: 
  - Pages load at dh.osowoso.org/distros.html and dh.osowoso.org/all.html
  - Light/dark theme toggle works (click 🌓)
  - Cards display correctly in both themes
  - Download dropdown shows versions/editions

- **Functional Check**:
  - Navigation shows "Distros" and "All" links
  - Card link goes to distro HOMEPAGE
  - Download button shows version/edition options
  - All ~100 distros displayed
  - Responsive on mobile

- **Success Criteria**:
  - Distros page accessible with real distro info from public/
  - Theme toggle works correctly
  - Download shows versions/editions with links
  - Design matches existing site style
