export interface LayoutFrame {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface LayoutInfo {
  id: string;
  frame: LayoutFrame;
}

export interface CaptureServiceStore {
  isCapturing: Record<string, boolean>;
}

export interface CaptureServiceActions {
  setIsCapturing: (screenName: string, capturing: boolean) => void;
}

export interface MeasurementData {
  id: string;
  size: {
    width: number;
    height: number;
    logicalWidth: number;
    logicalHeight: number;
  };
  position: {
    x: number;
    y: number;
    logicalX: number;
    logicalY: number;
  };
  pixelRatio: number;
}
