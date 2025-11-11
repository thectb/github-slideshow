#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Paths
const dataPath = path.join(__dirname, '../data/top10.csv');
const emailTplPath = path.join(__dirname, 'email.svg.tpl');
const socialTplPath = path.join(__dirname, 'social.svg.tpl');
const emailOutPath = path.join(__dirname, '../out/RFP_Top10_Email.svg');
const socialOutPath = path.join(__dirname, '../out/RFP_Top10_Social.svg');

// Read and parse CSV
function parseCSV(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.trim().split('\n');
  const headers = lines[0].split(',');

  const data = [];
  for (let i = 1; i < lines.length; i++) {
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
    const y = index * 45;
    svg += `    <text x="0" y="${y}" font-family="Montserrat, Arial, sans-serif" font-size="22" font-weight="600" fill="#111111">\n`;
    svg += `      ${index + 1}. ${peptide.product_name}\n`;
    svg += `    </text>\n`;
    svg += `    <text x="0" y="${y + 24}" font-family="Montserrat, Arial, sans-serif" font-size="18" font-weight="400" fill="#111111" opacity="0.75">\n`;
    svg += `      ${peptide.dose}\n`;
    svg += `    </text>\n`;
  });

  // Right column
  rightColumn.forEach((peptide, index) => {
    const y = index * 45;
    svg += `    <text x="540" y="${y}" font-family="Montserrat, Arial, sans-serif" font-size="22" font-weight="600" fill="#111111">\n`;
    svg += `      ${index + 6}. ${peptide.product_name}\n`;
    svg += `    </text>\n`;
    svg += `    <text x="540" y="${y + 24}" font-family="Montserrat, Arial, sans-serif" font-size="18" font-weight="400" fill="#111111" opacity="0.75">\n`;
    svg += `      ${peptide.dose}\n`;
    svg += `    </text>\n`;
  });

  return svg;
}

// Generate peptide list for social (1 column)
function generateSocialList(peptides) {
  let svg = '';

  peptides.forEach((peptide, index) => {
    const y = index * 24;
    svg += `    <text x="0" y="${y}" font-family="Montserrat, Arial, sans-serif" font-size="19" font-weight="600" fill="#111111">\n`;
    svg += `      ${index + 1}. ${peptide.product_name} — ${peptide.dose}\n`;
    svg += `    </text>\n`;
  });

  return svg;
}

// Main build function
function build() {
  console.log('🔨 Building RFP One-Pagers...\n');

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
  const emailTemplate = fs.readFileSync(emailTplPath, 'utf8');
  const socialTemplate = fs.readFileSync(socialTplPath, 'utf8');
  console.log('   Templates loaded\n');

  // Replace placeholders
  console.log('🔄 Injecting content...');
  const emailSVG = emailTemplate.replace('{{PEPTIDE_LIST}}', emailList);
  const socialSVG = socialTemplate.replace('{{PEPTIDE_LIST}}', socialList);
  console.log('   Content injected\n');

  // Write output files
  console.log('💾 Writing output files...');
  fs.writeFileSync(emailOutPath, emailSVG, 'utf8');
  console.log(`   ✓ ${emailOutPath}`);
  fs.writeFileSync(socialOutPath, socialSVG, 'utf8');
  console.log(`   ✓ ${socialOutPath}\n`);

  console.log('✅ Build complete!\n');
  console.log('Generated files:');
  console.log(`   - out/RFP_Top10_Email.svg (1200×1800 px)`);
  console.log(`   - out/RFP_Top10_Social.svg (1080×1350 px)\n`);
}

// Run build
try {
  build();
} catch (error) {
  console.error('❌ Build failed:', error.message);
  process.exit(1);
}
