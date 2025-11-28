// jest.config.js
module.exports = {
  // Global settings for coverage collection
  collectCoverage: true,
  coverageDirectory: '<rootDir>/coverage',
  coverageReporters: ['json', 'lcov', 'text', 'clover'],

  // Define both test suites as separate projects
  projects: [
    // 1. Non-E2E Tests (Your existing configuration)
    {
      displayName: 'unit/integration',
      rootDir: '<rootDir>', // Note: rootDir is now relative to project root

      // Copy the rest of your settings from package.json
      moduleFileExtensions: ['js', 'json', 'ts'],
      testRegex: '.*\\.spec\\.ts$', // Matches your standard tests
      transform: {
        '^.+\\.(t|j)s$': 'ts-jest',
      },
      collectCoverageFrom: ['**/*.(t|j)s'],
      moduleNameMapper: {
        '^src/(.*)$': '<rootDir>/src/$1', // Adjusted for new rootDir context
        '^generated/(.*)$': '<rootDir>/generated/$1', // Adjusted path
      },
      testEnvironment: 'node',
      // Optional: Store coverage for this project separately if needed
      // coverageDirectory: '<rootDir>/coverage/unit',
    },

    // 2. E2E Tests (Referencing your existing file)
    './test/jest-e2e.json', // Jest will load this file as the second project
  ],
};
