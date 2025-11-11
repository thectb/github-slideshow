<svg width="1200" height="1800" viewBox="0 0 1200 1800" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <defs>
    <!-- Background gradient: top-left darker to bottom-right lighter -->
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#B8B9B7;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#D0D1CF;stop-opacity:1" />
    </linearGradient>

    <!-- Subtle grain pattern -->
    <filter id="grain">
      <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="4" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0"/>
      <feBlend in="SourceGraphic" in2="noise" mode="multiply" />
    </filter>
  </defs>

  <!-- Background -->
  <rect width="1200" height="1800" fill="url(#bgGradient)"/>
  <rect width="1200" height="1800" fill="#C4C5C3" opacity="0.008" filter="url(#grain)"/>

  <!-- Header Section (24px margin) -->
  <g id="header">
    <!-- Logo -->
    <image x="40" y="40" width="180" height="60" xlink:href="../assets/logo.svg"/>

    <!-- Header Title -->
    <text x="600" y="90" font-family="Montserrat, Arial, sans-serif" font-size="42" font-weight="700" fill="#111111" text-anchor="middle">
      Top 10 Research Peptides
    </text>
    <text x="600" y="130" font-family="Montserrat, Arial, sans-serif" font-size="42" font-weight="700" fill="#111111" text-anchor="middle">
      to Recomp Your Body
    </text>
  </g>

  <!-- Subheadline -->
  <text x="600" y="180" font-family="Montserrat, Arial, sans-serif" font-size="18" font-weight="400" fill="#111111" text-anchor="middle" opacity="0.85">
    Investigational compounds discussed for research use in
  </text>
  <text x="600" y="205" font-family="Montserrat, Arial, sans-serif" font-size="18" font-weight="400" fill="#111111" text-anchor="middle" opacity="0.85">
    metabolic, recovery, and cellular pathways.
  </text>

  <!-- Hero "10" (translucent, 10% opacity) -->
  <text x="600" y="850" font-family="Montserrat, Arial, sans-serif" font-size="550" font-weight="900" fill="#111111" text-anchor="middle" opacity="0.10">
    10
  </text>

  <!-- Hero Vial (centered, ~660px width = 55% of canvas) -->
  <image x="270" y="420" width="660" height="660" xlink:href="../assets/vial.svg" opacity="0.95"/>

  <!-- Peptide List Section (Two columns) -->
  <g id="peptideList" transform="translate(80, 1150)">
    {{PEPTIDE_LIST}}
  </g>

  <!-- Footer Section -->
  <g id="footer">
    <!-- RUO Line -->
    <text x="600" y="1650" font-family="Montserrat, Arial, sans-serif" font-size="14" font-weight="600" fill="#111111" text-anchor="middle">
      For Research Use Only (RUO). Not for human or veterinary use.
    </text>

    <!-- CTA -->
    <text x="600" y="1710" font-family="Montserrat, Arial, sans-serif" font-size="20" font-weight="600" fill="#111111" text-anchor="middle">
      View full RUO catalog →
    </text>

    <!-- QR Code Placeholder -->
    <rect x="540" y="1730" width="120" height="120" fill="#FFFFFF" stroke="#111111" stroke-width="2" rx="4"/>
    <text x="600" y="1795" font-family="Arial, sans-serif" font-size="14" fill="#666666" text-anchor="middle">QR</text>
  </g>
</svg>
