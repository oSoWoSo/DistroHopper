# 1. OBJECTIVE

Add supported Linux distributions to the DistroHopper website (dh.osowoso.org) with:
1. ✅ **Distros page** - Card grid showing all distros from `public/` directory - EXISTS in `src/distros.html` (but download links broken)
2. ⚠️ **Download button** - Button opens modal with release/edition table - EXISTS but doesn't provide actual ISO download URLs (only links to homepage). Modal should show distro name with icon and release × edition combinations table.
3. ✅ **"all" page** - Page showing ALL distributions - EXISTS in `src/all.html`
4. 🔧 **Fix broken download links** - Currently modal shows invalid links (links to HOMEPAGE instead of actual ISO URLs)
5. ✅ **Distro icons** - Icons exist at `distros-gallery-v3/src/img/distro` - NEEDS TO BE COPIED TO THIS BRANCH
6. 🔧 **Show "Based on: <distro>"** - Add $BASEDOF from public/* files to distro cards
7. 🔧 **Add navigation links** - Add "Distros" and "All" links to main site navigation (currently only on those pages)
8. ⏳ **CI link checking** - Links verified automatically by CI - NOT IMPLEMENTED

The UI must follow site's light/dark theme toggle and match existing DistroHopper design.
**Note**: Site uses custom `web-create` bash script with pandoc (NOT Jekyll). Source in `src/`, built to `docs/`.

# 2. CONTEXT SUMMARY

- **Website**: dh.osowoso.org - static site built from `src/` → `docs/` using `web-create` script
- **Build System**: Custom bash script using pandoc (NOT Jekyll). Run `./web-create -b` to build.
- **Source Files**: `src/` directory contains HTML, CSS, JS source files
- **Domain**: Configured via CNAME (dh.osowoso.org)
- **Theme System**: CSS custom properties with `[data-theme="light"]` / `[data-theme="dark"]`
- **Data Files**:
  - `src/distros-data.js` - Contains ~100 distros with name, description, homepage, download links
  - `src/distros-releases.js` - Contains release versions and editions for each distro
- **Current CI**: `.github/workflows/website.yml` runs on *.md changes, builds with `./web-create -b`
- **Problem**: 
  1. No distros shown on homepage or other pages
  2. No "Distros" and "All" links in main navigation
  3. The download modal (line 387 in distros.html) links to HOMEPAGE instead of actual ISO URLs - broken!
  4. Distro icons exist on `distros-gallery-v3` branch but not copied to this branch
  5. No "Based on" information from $BASEDOF in public/* files
  6. CI doesn't generate download URLs or check links

# 3. APPROACH OVERVIEW

1. **Copy distro icons** - Copy images from `distros-gallery-v3/src/img/distro` to `src/img/distro`

2. **Update CI to generate all distro data** - CI should parse ALL data from `public/*` files:
   - OSNAME, PRETTY, DESCRIPTION, HOMEPAGE
   - RELEASES, EDITIONS
   - **$BASEDOF** - parent distro (currently missing!)
   - Run `get_()` function to generate actual ISO download URLs
   - Output: Updated `src/distros-data.js` with complete data

3. **Show distros on site** - Distros should be visible, not just on dedicated pages
   - Homepage should show featured distros or link to distros page

4. **Add navigation links** - Add "Distros" and "All" links to main nav (toggle.html or similar)

5. **Add "Based on" to cards** - Parse $BASEDOF from public/* files and display

6. **Add CI link checking** - Add external link validation

# 4. IMPLEMENTATION STEPS

### Step -1: Copy distro icons from distros-gallery-v3 branch
- **Goal**: Get distro images to use in cards
- **Method**: 
  1. Fetch/merge icons from `distros-gallery-v3/src/img/distro` branch
  2. Copy to `src/img/distro` directory
  3. Ensure images are accessible to the website
- **Reference**: Icons exist at `distros-gallery-v3/src/img/distro`

### Step 0: Update CI workflow to generate all distro data
- **Goal**: CI should parse ALL data from `public/*` files and generate complete `distros-data.js`
- **Method**: 
  1. Create/update GitHub Actions workflow (`.github/workflows/generate-distro-data.yml`)
  2. CI iterates through ALL `public/*` files and extracts:
     - `OSNAME` / `PRETTY` - distro name
     - `DESCRIPTION` - one-line description
     - `HOMEPAGE` - official website URL
     - **`BASEDOF`** - parent distro (currently missing from data!)
     - `RELEASES` - available versions
     - `EDITIONS` - available desktop editions
  3. Run `get_()` function to generate actual ISO download URLs for each release/edition combo
  4. Output: Complete `src/distros-data.js` with all fields including `basedof` and `downloads`
  5. Workflow runs: on schedule (daily) + on PR changes to `public/*` files + manual trigger
- **Reference**: `public/debian` shows format; current `src/distros-data.js` shows structure

### Step 1: Show distros on homepage
- **Goal**: Homepage should display distro cards or link to distros page
- **Method**: 
  1. Add distro cards section to homepage or add link to distros page prominently
  2. Could show "Featured Distros" grid on homepage
- **Reference**: `src/index.html` (if exists) or needs to be created from README.md

### Step 2: Add navigation links to main site
- **Goal**: "Distros" and "All" links should appear in main navigation on **ALL** pages (homepage, all markdown-generated pages, etc.)
- **Method**: 
  1. Find where main nav is built (in `src/toggle.html` - this is included in ALL pages via web-create)
  2. Add "Distros" and "All" links to the nav menu in toggle.html
  3. Verify links appear on: index.html, README.html, CODE_OF_CONDUCT.html, CONTRIBUTING.html, SECURITY.html, etc.
- **Reference**: `src/toggle.html` is the nav template included by web-create script

### Step 3: Add "Based on" to distro cards
- **Goal**: Display $BASEDOF from public/* files on each distro card
- **Method**: 
  1. CI already extracts $BASEDOF in Step 0
  2. Update JavaScript rendering to show "Based on: <distro>" on each card
  3. Show badge/pill for based-on distro
- **Reference**: Current card rendering in `src/distros.html`

### Step 4: Fix download modal to use generated URLs
- **Goal**: Make download links actually point to ISO files, not homepage. Button per distro opens table showing distro name with icon and all release × edition combinations
- **Method**: 
  1. Update JavaScript in `src/distros.html` to use `downloads` object from distros-data.js
  2. On "Download" button click, open modal/panel with table:
     - **Header**: Distro name with icon (from `src/img/distro/`)
     - **Rows**: Available RELEASE versions (e.g., 12.11.0, 11.11.0)  
     - **Columns**: Available EDITIONS (e.g., xfce, mate, kde, gnome, standard)
     - **Cells**: Clickable links to direct ISO downloads
  3. Mark specific release/edition combinations as **disabled** (grayed out) if not available
- **UI Example**:
  ```
         | xfce    | mate    | kde     | gnome   | standard
  ------+---------+---------+---------+---------+----------
  12.x  | [DL]    | [DL]    | [DL]    | [DL]    | [DL]
  11.x  | [DL]    | [DL]    | [X]     | [DL]    | [DL]
  10.x  | [DL]    | [X]     | [X]     | [X]     | [X]
  
  [DL] = available (clickable download link)  [X] = disabled/grayed out (not available)
  ```
- **Reference**: 
  - After Step 0, `distros-data.js` will have `downloads: { "12.11.0": { "xfce": "https://..." } }`
  - `public/*` files have RELEASES, EDITIONS, and get_() function

### Step 5: Fix all.html if needed
- **Goal**: Ensure all.html has same working download functionality
- **Method**: Verify it uses same modal/JS as distros.html

### Step 6: Add CI link checking
- **Goal**: Automatically verify external links work
- **Method**:
  1. Add GitHub Actions workflow that checks HOMEPAGE links
  2. Use tools like `linkchecker` or `lychee` to validate URLs
  3. Run on PRs and scheduled (weekly)
- **Output**: `.github/workflows/link-check.yml`

### Step 7: Verify theme toggle works
- **Goal**: Ensure distro cards render correctly in both light and dark themes
- **Method**: Already implemented - verify with visual check

### Step 8: Use distro icons in cards
- **Goal**: Each distro card should display its icon
- **Method**: 
  1. Icons already copied in Step -1
  2. Update card rendering to use icon from `src/img/distro/` directory
  3. Add `icon` field to distros-data.js or use filename convention
- **Reference**: Icons in `src/img/distro/`, current code uses placeholders

# 5. TESTING AND VALIDATION

## Current State (What's Already Working)
- ✅ Distros page exists in `src/distros.html`
- ✅ All page exists in `src/all.html`  
- ✅ Light/dark theme toggle works (click 🌓)
- ✅ Cards display correctly in both themes
- ✅ Search and filter buttons work
- ✅ Modal opens when clicking "Download" button
- ⚠️ Modal has colored placeholder icons (no distro-specific icons yet)
- ⚠️ No "Based on" shown on cards

## What's Missing/Needs Fix
- ❌ No distros shown on homepage or other pages (only on distros.html and all.html)
- ❌ No "Distros" and "All" links in main navigation
- ⚠️ Download links in modal DON'T WORK - they point to homepage instead of actual ISO files
- 🖼️ Distro icons exist on distros-gallery-v3 branch - NEEDS TO BE COPIED
- ⏳ No CI to generate download URLs from public/* files
- ⏳ No CI link checking

## Testing Steps After Implementation
- **Functional Check**:
  - CI workflow generates distro data from `public/*` files (including $BASEDOF)
  - Modal download links now point to actual ISO download URLs
  - Each release × edition combination has working link
  - All ~100 distros displayed on distros.html
  - "Based on: <distro>" shown on each card
  - "Distros" and "All" links appear in main nav on ALL pages

- **Visual Check**:
  - Homepage shows distros or links to distros page
  - Pages load correctly (after `./web-create -b`)
  - Light/dark theme toggle works (click 🌓)
  - Cards display distro-specific icons or enhanced placeholders
  - "Based on" badge visible on each card

- **CI Check**:
  - Distro data generation workflow runs on schedule (daily)
  - Link checking workflow runs on PRs
  - Broken HOMEPAGE links are reported

## Success Criteria
- ✅ Distros page exists with real distro info - DONE
- ✅ Theme toggle works correctly - DONE  
- ❌ Distros shown on homepage/navigation - NEEDS IMPLEMENTATION
- ❌ "Distros" and "All" in main nav - NEEDS IMPLEMENTATION
- ⚠️ Download shows versions/editions with WORKING links - NEEDS CI
- 🖼️ Distro icons exist (need to copy from distros-gallery-v3) - NEEDS COPY
- 🔧 "Based on: <distro>" shown on cards - NEEDS IMPLEMENTATION
- ✅ Design matches existing site style - DONE
- ⏳ CI download URL generation - NEEDS IMPLEMENTATION
- ⏳ CI link checking - NEEDS IMPLEMENTATION
