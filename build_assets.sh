#!/bin/bash

echo "Building Load Balancer assets..."

# Build CSS
echo "Building CSS..."
cd assets
npx tailwindcss -i ./css/app.css -o ../priv/static/assets/app.css

# Build JavaScript
echo "Building JavaScript..."
npm run build

echo "Assets built successfully!"
echo "CSS: priv/static/assets/app.css"
echo "JS:  priv/static/assets/app.js"
