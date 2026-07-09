# Verification Script for Generator Tag Fix
# Run this script in the Hyku repo directory
# Usage: bash scripts/verify-generator-tag.sh
# Can be run locally (on the branch) or in the container

echo "=== Verifying Generator Tag Fix ==="
echo ""

# Determine if we're in a container or local environment
HELPER_PATH="app/helpers/hyku_helper.rb"
PARTIAL_PATH="app/views/layouts/_generator_meta_tag.html.erb"

# If running in container, the files are in hyrax-webapp submodule
if [ -d "/app/samvera/hyrax-webapp" ]; then
    HELPER_PATH="/app/samvera/hyrax-webapp/app/helpers/hyku_helper.rb"
    PARTIAL_PATH="/app/samvera/hyrax-webapp/app/views/layouts/_generator_meta_tag.html.erb"
fi

# Check that the override helper exists
if [ -f "$HELPER_PATH" ]; then
    echo "✅ Override helper found: $HELPER_PATH"
else
    echo "❌ ERROR: Override helper not found at $HELPER_PATH"
    exit 1
fi

# Check that the helper defines hyku_generator_meta_tag
if grep -q 'def hyku_generator_meta_tag' "$HELPER_PATH"; then
    echo "✅ Helper method 'hyku_generator_meta_tag' defined"
else
    echo "❌ ERROR: Helper method not found!"
    exit 1
fi

# Check that it returns the correct format with Hyku version
if grep -q 'Samvera Hyku.*::Hyku::VERSION' "$HELPER_PATH"; then
    echo "✅ Helper returns correct format: 'Samvera Hyku #{::Hyku::VERSION}'"
else
    echo "❌ ERROR: Helper format incorrect!"
    exit 1
fi

# Check that the override partial exists
if [ -f "$PARTIAL_PATH" ]; then
    echo "✅ Override partial found: $PARTIAL_PATH"
else
    echo "❌ ERROR: Override partial not found at $PARTIAL_PATH"
    exit 1
fi

# Check that the partial calls the helper
if grep -q 'hyku_generator_meta_tag' "$PARTIAL_PATH"; then
    echo "✅ Partial calls helper method"
else
    echo "❌ ERROR: Partial doesn't call helper!"
    exit 1
fi

# Try to verify Hyku::VERSION (only works in container with Rails)
if [ -d "/app/samvera" ] && command -v bundle &> /dev/null; then
    if bundle exec rails runner -e development 'puts Hyku::VERSION' > /dev/null 2>&1; then
        HYKU_VERSION=$(bundle exec rails runner -e development 'puts Hyku::VERSION')
        echo "✅ Hyku version available: $HYKU_VERSION"
    else
        echo "⚠️  WARNING: Could not verify Hyku::VERSION (may need Rails environment)"
    fi
else
    echo "ℹ️  Skipping Rails verification (not in container or Rails not available)"
fi

echo ""
echo "=== ✅ Verification Complete ==="
echo ""
echo "The generator tag fix is correctly implemented."
echo "Implementation files:"
echo "  - Helper:  $(basename $HELPER_PATH) (defines hyku_generator_meta_tag)"
echo "  - Partial: $(basename $PARTIAL_PATH) (calls helper via ERB)"
echo ""
echo "When deployed, Hyku will report: 'Samvera Hyku X.Y.Z' instead of 'Samvera Hyrax'"
