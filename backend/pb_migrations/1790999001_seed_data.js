/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // Test seed data has been removed. Database is now in clean state for real users.
}, (app) => {
  // No-op revert
});
