import { useContext } from 'react';
import ScreenContext from './ScreenContext';

export default function useScreen() {
  const context = useContext(ScreenContext);
  if (!context) {
    throw new Error('useScreen must be used within a ScreenProvider');
  }
  return context;
}
