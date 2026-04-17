<svg width="1200" height="1800" viewBox="0 0 1200 1800" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- Background gradient: top-left darker to bottom-right lighter -->
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#B8B9B7"/>
      <stop offset="100%" stop-color="#D0D1CF"/>
    </linearGradient>

    <!-- Subtle grain overlay -->
    <filter id="grain">
      <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="3" result="n"/>
      <feColorMatrix in="n" type="saturate" values="0"/>
      <feBlend in="SourceGraphic" in2="n" mode="multiply"/>
    </filter>

    <!-- Shadow blur -->
    <filter id="blur">
      <feGaussianBlur stdDeviation="20"/>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="1200" height="1800" fill="url(#bgGradient)"/>
  <rect width="1200" height="1800" fill="#C4C5C3" opacity="0.01" filter="url(#grain)"/>

  <!-- Header -->
  <g id="header">
    <!-- Logo -->
    <image href="{{LOGO_DATA}}" x="60" y="60" height="60" preserveAspectRatio="xMidYMid meet"/>

    <!-- Title -->
    <text x="600" y="110" font-family="Montserrat, Arial, sans-serif" font-size="54" font-weight="800" fill="#111111" text-anchor="middle">
      Top 10 Research Peptides to Recomp Your Body
    </text>
  </g>

  <!-- Hero Section -->
  <g id="hero">
    <!-- Shadow (behind vial) -->
    <ellipse cx="600" cy="1080" rx="300" ry="100" fill="#000000" opacity="0.25" filter="url(#blur)"/>

    <!-- Translucent "10" -->
    <text x="600" y="720" font-family="Montserrat, Arial, sans-serif" font-size="700" font-weight="900" fill="#111111" text-anchor="middle" opacity="0.10">
      10
    </text>

    <!-- Hero Vial -->
    <image href="{{HERO_DATA}}" x="240" y="360" width="720" preserveAspectRatio="xMidYMid meet"/>
  </g>

  <!-- Subline -->
  <text x="600" y="1280" font-family="Montserrat, Arial, sans-serif" font-size="28" font-weight="400" fill="#111111" text-anchor="middle" opacity="0.85">
    Investigational compounds discussed for research use in metabolic, recovery, and cellular pathways.
  </text>

  <!-- Peptide List (Two columns) -->
  <g id="peptideList" transform="translate(0, 1360)">
    {{PEPTIDE_LIST}}
  </g>

  <!-- Footer -->
  <g id="footer">
    <!-- RUO Line -->
    <text x="600" y="1740" font-family="Montserrat, Arial, sans-serif" font-size="22" font-weight="600" fill="#111111" text-anchor="middle">
      For Research Use Only (RUO). Not for human or veterinary use.
    </text>
  </g>
</svg>
