# Configuration Seed Split

The app now seeds indexes, layouts, and property presentations from separate interchange files. Seeding aggregates their records before pruning, so removed configuration records are deleted together.

The obsolete relationship index and layout, generic record layout, and seed-marker layout are no longer seeded. Book layouts retain their catch-all field expansion but exclude `originalData` by default.

Layouts can also use `excludedFields` to suppress any explicit or expanded field and `presentation` to link property metadata that takes precedence over kind-specific and generic presentation records.
