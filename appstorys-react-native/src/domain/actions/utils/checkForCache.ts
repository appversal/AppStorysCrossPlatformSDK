import RNFS from 'react-native-fs';
import { Image, Platform } from 'react-native';
import healthCheck from './healthCheck';

type CacheType = 'image' | 'video' | 'lottie' | 'gif';

async function getImageAspectRatio(path: string) {
  return new Promise<number | null>((resolve) => {
    Image.getSize(
      path,
      (imgWidth, imgHeight) => resolve(imgHeight / imgWidth),
      () => resolve(null),
    );
  });
}

export default async function checkForCache(url: string, type: CacheType = 'image') {
  return new Promise<{ path: string; ratio: number | null } | null>(async (resolve) => {
    const startTime = Date.now();

    const filename = decodeURIComponent(url.split('/').pop()?.split('?')[0] || '')
      .replace(/[^a-zA-Z0-9._-]/g, '_');

    if (!filename) {
      healthCheck({ component: 'cache_service', action: 'filename_extraction_error', startTime, success: false, error: 'Invalid filename', url, type });
      return resolve(null);
    }

    const path = `${RNFS.CachesDirectoryPath}/${filename}`;
    const localPath = Platform.OS === 'android' ? `file://${path}` : path;

    try {
      let exists = await RNFS.exists(path);

      if (!exists) {
        const downloadResult = await RNFS.downloadFile({ fromUrl: url, toFile: path }).promise;
        const fileExists = await RNFS.exists(path);
        exists = downloadResult.statusCode === 200 && fileExists;
      }

      if (exists) {
        const ratio = (type === 'image' || type === 'gif') ? await getImageAspectRatio(localPath) : null;
        return resolve({ path: localPath, ratio });
      }
    } catch (error) {
      healthCheck({ component: 'cache_service', action: 'cache_operation_error', startTime, success: false, error: error instanceof Error ? error.message : 'Unknown error', url, type });
    }
    return resolve(null);
  });
}
