// Shared code, types, and utilities
// This module will be used by both client and server

// Example shared constants
const API_ROUTES = {
  HEALTH: '/api/health',
};

// Example shared utilities
const formatDate = (date) => {
  return new Date(date).toLocaleDateString();
};

module.exports = {
  API_ROUTES,
  formatDate,
};