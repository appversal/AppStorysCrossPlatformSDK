interface HealthCheckParams {
  component: string;
  action: string;
  startTime?: number;
  duration?: number;
  success?: boolean;
  reason?: string;
  [key: string]: any;
}

export default function healthCheck(_params: HealthCheckParams) {
  // no-op — analytics are handled by KMP core
}
