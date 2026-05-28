const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const projectRoot = __dirname;
const sdkRoot = path.resolve(projectRoot, '..');
const nm = (pkg) => path.resolve(projectRoot, 'node_modules', pkg);

// Escape Windows backslashes for use in a RegExp
const esc = (p) => p.replace(/\\/g, '\\\\').replace(/\//g, '\\/');

const config = {
  watchFolders: [sdkRoot],
  resolver: {
    nodeModulesPaths: [path.resolve(projectRoot, 'node_modules')],
    // Exclude the SDK's own node_modules from Metro so it never finds a
    // duplicate (or newer) react-native there. Resolution falls through to
    // the example's node_modules instead.
    blockList: [
      new RegExp(`^${esc(path.join(sdkRoot, 'node_modules'))}[\\\\/].*`),
    ],
    extraNodeModules: {
      'react': nm('react'),
      'react-native': nm('react-native'),
      'lottie-react-native': nm('lottie-react-native'),
      'react-native-fs': nm('react-native-fs'),
      'react-native-safe-area-context': nm('react-native-safe-area-context'),
      'react-native-video': nm('react-native-video'),
      'react-native-view-shot': nm('react-native-view-shot'),
    },
  },
};

module.exports = mergeConfig(getDefaultConfig(projectRoot), config);
