#!/bin/bash

# 1. Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

cp .env.example .env

echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" > .env

# 2. Run Flutter build
flutter config --enable-web
flutter pub get
flutter build web --release 