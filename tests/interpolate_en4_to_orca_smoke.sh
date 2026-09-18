#!/bin/bash
# Smoke test for interpolate_en4_to_orca

set -e

# Create test input
mkdir -p test_input
echo "dummy netcdf content" > test_input/en4.2.2_test.nc

echo "dummy grid content" > ORCA1_grid.nc

# Run script
./workflows/EN4/scripts/interpolate_en4.2.2_to_ORCA.sh \
  --input test_input/en4.2.2_test.nc \
  --grid ORCA1_grid.nc \
  --output test_output/en4.2.2_test_ORCA1.nc

# Verify output
if [ -f "test_output/en4.2.2_test_ORCA1.nc" ]; then
    echo "✅ Smoke test passed"
else
    echo "❌ Smoke test failed: Output file missing"
    exit 1
fi