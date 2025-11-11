# RFP Top-10 Peptide One-Pager Generator

Deterministic SVG generator for brand-accurate, print-clean one-pagers (email + social).

## Project Structure

```
rfp_onepager/
├── assets/
│   ├── logo.svg          # RFP logo placeholder
│   └── vial.svg          # Peptide vial image
├── data/
│   └── top10.csv         # Top-10 peptide data (single source of truth)
├── src/
│   ├── email.svg.tpl     # Email template (1200×1800 px)
│   ├── social.svg.tpl    # Social template (1080×1350 px)
│   └── build.js          # Build script (pure Node.js, no deps)
├── out/
│   ├── RFP_Top10_Email.svg   # Generated email one-pager
│   └── RFP_Top10_Social.svg  # Generated social one-pager
└── README.md
```

## Quick Start

### Build the SVGs

```bash
node src/build.js
```

This will:
1. Read `data/top10.csv`
2. Inject data into templates
3. Generate final SVGs in `out/`

### Output Files

- **Email**: `out/RFP_Top10_Email.svg` (1200×1800 px)
- **Social**: `out/RFP_Top10_Social.svg` (1080×1350 px)

## Brand Guidelines

### Colors
- **Background**: #C4C5C3 (soft gradient, top-left darker → bottom-right lighter)
- **Text**: #111111
- **Palette**: Neutral (logo colors preserved)

### Typography
- **Font**: Montserrat, Arial, sans-serif
- **Text**: Fully selectable (not rasterized)

### Layout
- **Header**: RFP logo + title
- **Hero**: Large translucent "10" (10% opacity) with centered vial
- **List**: Clean text (2 columns for email, 1 column for social)
- **Footer**: RUO disclaimer + CTA + QR placeholder

### RUO Disclaimer
> For Research Use Only (RUO). Not for human or veterinary use.

## Exporting to Other Formats

### Using Inkscape (Recommended)

#### Export to PNG

```bash
# High-resolution PNG (300 DPI for print)
inkscape out/RFP_Top10_Email.svg --export-filename=email.png --export-dpi=300

# Social PNG (for web)
inkscape out/RFP_Top10_Social.svg --export-filename=social.png --export-dpi=150
```

#### Export to JPG

```bash
# First export to PNG, then convert with ImageMagick
inkscape out/RFP_Top10_Email.svg --export-filename=temp.png --export-dpi=300
convert temp.png -quality 95 email.jpg
rm temp.png
```

#### Export to PDF (Print-Ready)

```bash
# Email PDF
inkscape out/RFP_Top10_Email.svg --export-filename=email.pdf --export-type=pdf

# Social PDF
inkscape out/RFP_Top10_Social.svg --export-filename=social.pdf --export-type=pdf
```

### Using GUI Tools

#### Inkscape GUI
1. Open `File → Open` and select the SVG
2. Go to `File → Export PNG Image` (Shift+Ctrl+E)
3. Set desired DPI (300 for print, 72-150 for web)
4. Click **Export**

For PDF:
1. `File → Save a Copy`
2. Choose **PDF** from format dropdown
3. Save with appropriate settings

#### Adobe Illustrator
1. Open the SVG file
2. `File → Export → Export As`
3. Choose format (PNG, JPG, PDF)
4. Set resolution and quality
5. Export

#### Online Tools (No Installation)
- **CloudConvert**: cloudconvert.com (SVG → PNG/JPG/PDF)
- **SVG2PNG**: svgtopng.com
- **Convertio**: convertio.co/svg-png

## Customization

### Update Peptide Data
Edit `data/top10.csv` and rebuild:

```csv
product_name,dose
NEW-PEPTIDE,50 mg
...
```

### Replace Assets
- Replace `assets/logo.svg` with your logo
- Replace `assets/vial.svg` with your vial image
- Rebuild to apply changes

### Modify Templates
Edit `src/email.svg.tpl` or `src/social.svg.tpl` directly. Available placeholders:
- `{{PEPTIDE_LIST}}` - Replaced by generated peptide list

## Technical Notes

- **No external dependencies**: Pure Node.js (fs, path only)
- **No network calls**: Fully offline build
- **Deterministic output**: Same input = same output
- **Print-clean**: Vector graphics, selectable text, 24px margins
- **Self-contained**: All assets embedded/referenced locally

## Requirements

- Node.js (any version with ES6 support)
- Inkscape (optional, for PNG/PDF export)

## License

For internal RFP use only. Assets and branding are proprietary.
