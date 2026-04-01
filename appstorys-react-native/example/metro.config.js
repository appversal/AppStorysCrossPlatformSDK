const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

// The library root (one level up from example/)
const root = path.resolve(__dirname, '..');

const config = {
  watchFolders: [root],
  resolver: {
    // Prevent duplicate React / React Native when resolving from the library root
    nodeModulesPaths: [
      path.resolve(__dirname, 'node_modules'),
    ],
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
