#!/bin/sh
# Fails Release builds when the public legal URLs are missing, unexpanded or not HTTPS.
# Values come from Config/Legal.xcconfig via build settings. Debug builds only warn.
fail=0
for name in LUMEN_TERMS_URL LUMEN_PRIVACY_URL; do
  value=$(eval echo "\$$name")
  case "$value" in
    https://?*.?*) ;;
    *)
      if [ "$CONFIGURATION" = "Release" ]; then
        echo "error: $name must be an https URL in Config/Legal.xcconfig (got: '$value')"
        fail=1
      else
        echo "warning: $name is missing or not https; the paywall will fall back to in-app text."
      fi ;;
  esac
done
exit $fail
