# JWW Parser returns abnormal coordinate values

## Problem

When parsing サンプル.jww file, the jww-parser library returns extremely large coordinate values (10^18 ~ 10^19 order) which are clearly incorrect.

## Evidence

```json
{
  "bounds": {
    "min_x": -1680920987680768,
    "min_y": 0,
    "max_x": 18466190030163970000,
    "max_y": 18474562622279310000
  },
  "entity_counts": {
    "lines": 592,
    "arcs": 64,
    "texts": 20,
    "points": 19
  }
}
```

Generated SVG contains lines like:
```xml
<line x1="13861129179445450000" y1="-4628542801539694000" ... />
```

## Expected

JWW coordinates should be in mm units, typically ranging from -10^6 to 10^6 for most drawings.

## Analysis

The entity counts are correct (592 lines, 64 arcs, etc.), suggesting the parser is reading the file structure correctly. The issue appears to be in coordinate value interpretation, possibly:

1. Incorrect byte order when reading double values
2. Missing unit conversion
3. Incorrect offset in binary structure parsing

## Workaround

Currently, `calculate_bounds` in `jww_converter.mbt` filters out coordinates with absolute values > 10^9, which causes the drawing to not be rendered.

## Related Files

* `jww_converter.mbt`: calculate_bounds function
* `.mooncakes/horideicom/jww_parser/core`

## Next Steps

1. Check if the issue is in jww-parser package
2. Test with other JWW files to see if the problem is file-specific
3. Consider updating jww-parser or filing an issue upstream
