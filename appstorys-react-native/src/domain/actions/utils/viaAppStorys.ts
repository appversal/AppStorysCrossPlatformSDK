import AppStorys from '../../../index';

export default function viaAppStorys(event: string) {
  AppStorys.trackEvent(event).catch(() => {});
}

export function removeTrackedEvent(_event: string) {
  // no-op — campaign lifecycle is managed by KMP core
}
