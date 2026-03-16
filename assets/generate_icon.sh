#!/bin/bash
# Script to generate placeholder icon
# In real usage, replace assets/icon.png with your actual logo (1024x1024 PNG)

cat > /tmp/icon.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <rect width="1024" height="1024" rx="180" fill="#1a1a2e"/>
  <rect x="200" y="400" width="624" height="350" rx="20" fill="#4fc3f7"/>
  <polygon points="512,150 150,420 874,420" fill="#e0e0e0"/>
  <rect x="380" y="550" width="120" height="200" rx="10" fill="#1a1a2e"/>
  <rect x="530" y="550" width="120" height="140" rx="10" fill="#1a1a2e"/>
  <text x="512" y="870" font-family="Arial" font-size="80" font-weight="bold" fill="white" text-anchor="middle">BS</text>
</svg>
EOF

echo "Icon SVG created"
