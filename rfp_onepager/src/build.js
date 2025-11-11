#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Project root
const ROOT = path.join(__dirname, '..');

// Paths
const dataPath = path.join(ROOT, 'data/top10.csv');
const emailTplPath = path.join(ROOT, 'src/email.svg.tpl');
const socialTplPath = path.join(ROOT, 'src/social.svg.tpl');
const emailOutPath = path.join(ROOT, 'out/RFP_Top10_Email.svg');
const socialOutPath = path.join(ROOT, 'out/RFP_Top10_Social.svg');

// Asset paths
const logoPath = path.join(ROOT, 'assets/logo.svg');
const vialPngPath = path.join(ROOT, 'assets/vial.png');
const vialSvgPath = path.join(ROOT, 'assets/vial.svg');

// Helper: Get MIME type
const mimeFor = p => {
  const ext = path.extname(p).toLowerCase();
  if (ext === '.svg') return 'image/svg+xml';
  if (ext === '.png') return 'image/png';
  if (ext === '.jpg' || ext === '.jpeg') return 'image/jpeg';
  return 'application/octet-stream';
};

// Helper: Convert file to data URI
const dataURI = rel => {
  const abs = path.join(ROOT, rel);
  if (!fs.existsSync(abs)) {
    console.warn(`   ⚠️  Warning: ${rel} not found, using placeholder`);
    return '';
  }
  const buf = fs.readFileSync(abs);
  return `data:${mimeFor(rel)};base64,${buf.toString('base64')}`;
};

// Read and parse CSV
function parseCSV(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.trim().split('\n');
  const headers = lines[0].split(',');

  const data = [];
  for (let i = 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue; // Skip empty rows
    const values = lines[i].split(',');
    const row = {};
    headers.forEach((header, index) => {
      row[header.trim()] = values[index].trim();
    });
    data.push(row);
  }

  return data;
}

// Generate peptide list for email (2 columns)
function generateEmailList(peptides) {
  const leftColumn = peptides.slice(0, 5);
  const rightColumn = peptides.slice(5, 10);

  let svg = '';

  // Left column
  leftColumn.forEach((peptide, index) => {
    const y = index * 50;
    svg += `    <text x="0" y="${y}" font-family="Montserrat, Arial, sans-serif" font-size="24" font-weight="600" fill="#111111">\n`;
    svg += `      ${index + 1}. ${peptide.product_name} — ${peptide.dose}\n`;
    svg += `    </text>\n`;
  });

  // Right column
  rightColumn.forEach((peptide, index) => {
    const y = index * 50;
    svg += `    <text x="540" y="${y}" font-family="Montserrat, Arial, sans-serif" font-size="24" font-weight="600" fill="#111111">\n`;
    svg += `      ${index + 6}. ${peptide.product_name} — ${peptide.dose}\n`;
    svg += `    </text>\n`;
  });

  return svg;
}

// Generate peptide list for social (1 column)
function generateSocialList(peptides) {
  let svg = '';

  peptides.forEach((peptide, index) => {
    const y = index * 26;
    svg += `    <text x="0" y="${y}" font-family="Montserrat, Arial, sans-serif" font-size="22" font-weight="600" fill="#111111">\n`;
    svg += `      ${index + 1}. ${peptide.product_name} — ${peptide.dose}\n`;
    svg += `    </text>\n`;
  });

  return svg;
}

// Main build function
function build() {
  console.log('🔨 Building RFP One-Pagers...\n');

  // Determine which vial asset to use
  let vialPath = 'assets/vial.svg';
  if (fs.existsSync(vialPngPath)) {
    vialPath = 'assets/vial.png';
    console.log('📸 Using vial.png');
  } else {
    console.log('🎨 Using vial.svg (fallback)');
  }

  // Generate data URIs
  console.log('🔐 Encoding assets as base64...');
  const logoData = dataURI('assets/logo.svg');
  const heroData = dataURI(vialPath);
  console.log('   Assets encoded\n');

  // Parse CSV
  console.log('📊 Reading data/top10.csv...');
  const peptides = parseCSV(dataPath);
  console.log(`   Found ${peptides.length} peptides\n`);

  // Generate lists
  console.log('📝 Generating peptide lists...');
  const emailList = generateEmailList(peptides);
  const socialList = generateSocialList(peptides);
  console.log('   Lists generated\n');

  // Read templates
  console.log('📄 Reading templates...');
  let emailTemplate = fs.readFileSync(emailTplPath, 'utf8');
  let socialTemplate = fs.readFileSync(socialTplPath, 'utf8');
  console.log('   Templates loaded\n');

  // Replace placeholders
  console.log('🔄 Injecting content...');
  emailTemplate = emailTemplate.replace('{{LOGO_DATA}}', logoData);
  emailTemplate = emailTemplate.replace('{{HERO_DATA}}', heroData);
  emailTemplate = emailTemplate.replace('{{PEPTIDE_LIST}}', emailList);

  socialTemplate = socialTemplate.replace('{{LOGO_DATA}}', logoData);
  socialTemplate = socialTemplate.replace('{{HERO_DATA}}', heroData);
  socialTemplate = socialTemplate.replace('{{PEPTIDE_LIST}}', socialList);
  console.log('   Content injected\n');

  // Write output files
  console.log('💾 Writing output files...');
  fs.writeFileSync(emailOutPath, emailTemplate, 'utf8');
  console.log(`   ✓ ${emailOutPath}`);
  fs.writeFileSync(socialOutPath, socialTemplate, 'utf8');
  console.log(`   ✓ ${socialOutPath}\n`);

  console.log('✅ Build complete!\n');
  console.log('Generated files:');
  console.log(`   - out/RFP_Top10_Email.svg (1200×1800 px)`);
  console.log(`   - out/RFP_Top10_Social.svg (1080×1350 px)`);
  console.log(`\nSVGs are self-contained with base64-embedded assets.\n`);
}

// Run build
try {
  build();
} catch (error) {
  console.error('❌ Build failed:', error.message);
  process.exit(1);
}
