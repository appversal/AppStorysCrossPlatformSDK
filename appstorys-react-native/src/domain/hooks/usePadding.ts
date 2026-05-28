import { useMemo } from 'react';
import useScreen from '../screen/useScreen';
import { ComponentPadding } from '../screen/types';

export default function usePadding(campaignType: string): ComponentPadding | null {
  const padding = useScreen().options?.overlayPadding;

  return useMemo(() => {
    if (typeof padding === 'number') {
      return { top: padding, bottom: padding };
    } else if (typeof padding === 'object') {
      if ('top' in padding || 'bottom' in padding) {
        return padding as ComponentPadding;
      } else if (campaignType === 'PIP' && 'pip' in padding) {
        const pip = (padding as any).pip;
        if (typeof pip === 'number') return { top: pip, bottom: pip };
        return pip || null;
      } else if (campaignType === 'FLT' && 'floater' in padding) {
        const f = (padding as any).floater;
        return { top: f, bottom: f };
      } else if (campaignType === 'BAN' && 'banner' in padding) {
        const b = (padding as any).banner;
        return { top: b, bottom: b };
      } else if (campaignType === 'CSAT' && 'csat' in padding) {
        const c = (padding as any).csat;
        return { top: c, bottom: c };
      }
    }
    return null;
  }, [padding, campaignType]);
}
