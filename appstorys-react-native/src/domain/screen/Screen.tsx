import { ScreenProviderProps } from './types';
import ScreenProvider from './ScreenProvider';
import Overlay from './Overlay';

export default function Screen({ name, options, children }: ScreenProviderProps) {
  return (
    <ScreenProvider name={name} options={options}>
      {children}
      <Overlay name={name} />
    </ScreenProvider>
  );
}
