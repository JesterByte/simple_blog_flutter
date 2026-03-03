#!/bin/bash

# 1. Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

cp .env.example .env

sed -i "s|SUPABASE_URL|$SUPABASE_URL|g" .env
sed -i "s|SUPABASE_ANON_KEY|$SUPABASE_ANON_KEY|g" .env

# 2. Run Flutter build
flutter config --enable-web
flutter pub get
flutter build web --release 