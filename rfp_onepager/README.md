# RFP Top-10 Peptide One-Pager Generator

Self-contained SVG generator for brand-accurate email and social one-pagers. Outputs production-ready SVGs with base64-embedded assets.

## Quick Start

### Build the SVGs

```bash
node src/build.js
```

This will:
1. Read peptide data from `data/top10.csv`
2. Encode assets (logo.svg, vial image) as base64 data URIs
3. Inject data into templates
4. Generate self-contained SVGs in `out/`

### Output Files

- **Email**: `out/RFP_Top10_Email.svg` (1200×1800 px)
- **Social**: `out/RFP_Top10_Social.svg` (1080×1350 px)

Both SVGs are **self-contained** with base64-embedded images (no external dependencies).

## Project Structure

```
rfp_onepager/
├── assets/
│   ├── logo.svg          # RFP logo (replace with real asset)
│   └── vial.svg          # Peptide vial image (or vial.png if available)
├── data/
│   └── top10.csv         # Top-10 peptide data (single source of truth)
├── src/
│   ├── email.svg.tpl     # Email template (1200×1800 px)
│   ├── social.svg.tpl    # Social template (1080×1350 px)
│   └── build.js          # Build script (pure Node.js, no deps)
├── out/
│   ├── RFP_Top10_Email.svg   # Generated email one-pager
│   └── RFP_Top10_Social.svg  # Generated social one-pager
├── PUBLISH/
│   ├── email_subject.txt     # Email subject line
│   ├── email_preheader.txt   # Email preheader text
│   ├── alt_text.txt          # Image alt text for accessibility
│   └── social_caption.txt    # Social media caption
└── README.md
```

## Assets

### Replacing Placeholder Assets

The build script currently uses placeholder assets. To use production assets:

1. **Logo**: Replace `assets/logo.svg` with `RibbonFoldedPeptides_Logo_Master.svg`
2. **Vial**: Add `assets/vial.png` (transparent PNG preferred) or replace `assets/vial.svg`

The build script automatically prefers `vial.png` if present, otherwise falls back to `vial.svg`.

After replacing assets, run `node src/build.js` to regenerate the SVGs.

## Brand Guidelines

### Colors
- **Background**: #C4C5C3 soft gradient (top-left #B8B9B7 → bottom-right #D0D1CF)
- **Text**: #111111
- **Gradient direction**: Top-left darker to bottom-right lighter
- **Grain overlay**: Extremely subtle (0.01 opacity)

### Typography
- **Font stack**: `Montserrat, Arial, sans-serif` (no web fonts)
- **Text**: Fully selectable SVG text (not rasterized)

### Layout
- **Margins**: ≥24px on all edges
- **Header**: Logo + title "Top 10 Research Peptides to Recomp Your Body"
- **Hero**: Large translucent "10" (10% opacity) with centered vial + shadow
- **Subline**: "Investigational compounds discussed for research use in metabolic, recovery, and cellular pathways."
- **List**:
  - Email: Two columns
  - Social: Single column
  - Format: `#. NAME — DOSE` (em dash)
- **Footer**: RUO disclaimer (verbatim below)

### RUO Disclaimer (Verbatim)
> For Research Use Only (RUO). Not for human or veterinary use.

## Exporting to Other Formats

### Using Inkscape (Recommended)

#### Export to PNG

**High-resolution for email (300 DPI)**
```bash
inkscape out/RFP_Top10_Email.svg \
  --export-filename=RFP_Top10_Email.png \
  --export-dpi=300
```

**Web-optimized for social (150 DPI)**
```bash
inkscape out/RFP_Top10_Social.svg \
  --export-filename=RFP_Top10_Social.png \
  --export-dpi=150
```

#### Export to JPG

First export to PNG, then convert with ImageMagick:

```bash
# Email
inkscape out/RFP_Top10_Email.svg --export-filename=temp.png --export-dpi=300
convert temp.png -quality 80 RFP_Top10_Email.jpg
rm temp.png

# Social
inkscape out/RFP_Top10_Social.svg --export-filename=temp.png --export-dpi=150
convert temp.png -quality 80 RFP_Top10_Social.jpg
rm temp.png
```

#### Export to PDF (Print-Ready)

**Email PDF**
```bash
inkscape out/RFP_Top10_Email.svg \
  --export-filename=RFP_Top10_Email.pdf \
  --export-type=pdf
```

**Social PDF**
```bash
inkscape out/RFP_Top10_Social.svg \
  --export-filename=RFP_Top10_Social.pdf \
  --export-type=pdf
```

### Using Inkscape GUI

1. Open Inkscape and load the SVG file
2. **For PNG Export**:
   - Go to `File → Export PNG Image` (Shift+Ctrl+E)
   - Select "Page" as export area
   - Set DPI:
     - **300 DPI** for print/email
     - **150 DPI** for web/social
   - Click **Export**

3. **For JPG Export**:
   - Export as PNG first (see above)
   - Use image editing software to convert PNG → JPG
   - Or use online converter

4. **For PDF Export**:
   - Go to `File → Save a Copy`
   - Choose **PDF** from the format dropdown
   - Options:
     - ✓ Convert text to paths (for font embedding)
     - ✓ Embed images
   - Click **Save**

### Using Adobe Illustrator

1. Open the SVG file in Illustrator
2. Go to `File → Export → Export As`
3. Choose format:
   - **PNG**: Set resolution (300 DPI for print, 150 for web)
   - **JPG**: Set quality (80-95 for high quality)
   - **PDF**: Use "High Quality Print" preset
4. Click **Export**

### Using Online Tools (No Installation Required)

- **CloudConvert**: https://cloudconvert.com (SVG → PNG/JPG/PDF)
- **SVG2PNG**: https://svgtopng.com
- **Convertio**: https://convertio.co/svg-png/

**Online export steps:**
1. Upload the SVG file
2. Select output format (PNG, JPG, or PDF)
3. Set quality/resolution if available
4. Convert and download

## Marketing Copy

Pre-written marketing copy is available in the `PUBLISH/` directory:

- **email_subject.txt**: Email subject line
- **email_preheader.txt**: Email preheader text
- **alt_text.txt**: Image alt text for accessibility
- **social_caption.txt**: Social media caption with hashtags

## Customization

### Update Peptide Data

Edit `data/top10.csv` and rebuild:

```csv
product_name,dose
KLOW,80 mg
GLOW,80 mg
BPC-157,10 mg
...
```

Run `node src/build.js` to regenerate SVGs.

### Modify Templates

Edit `src/email.svg.tpl` or `src/social.svg.tpl` directly.

**Available placeholders:**
- `{{LOGO_DATA}}` - Base64-encoded logo
- `{{HERO_DATA}}` - Base64-encoded vial image
- `{{PEPTIDE_LIST}}` - Generated peptide list

After editing, run `node src/build.js`.

## Technical Notes

- **No external dependencies**: Pure Node.js (fs, path only)
- **No network calls**: Fully offline build
- **Deterministic output**: Same input = same output
- **Self-contained SVGs**: All images base64-encoded as data URIs
- **Print-clean**: Vector graphics, selectable text, proper margins
- **Assets**: Build script prefers vial.png over vial.svg if both exist

## Placeholder Assets

**⚠️ Note**: This build currently uses placeholder assets:
- `assets/logo.svg` - Simple "RFP" text placeholder
- `assets/vial.svg` - Vector vial illustration

For production use, replace these with:
- Real RFP logo (RibbonFoldedPeptides_Logo_Master.svg)
- High-quality transparent vial PNG

After replacing, rebuild with `node src/build.js`.

## Requirements

- **Node.js**: Any version with ES6 support (v12+)
- **Inkscape** (optional): For PNG/PDF export
- **ImageMagick** (optional): For JPG conversion

## License

For internal RFP use only. Assets and branding are proprietary.
