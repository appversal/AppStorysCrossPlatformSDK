import { createContext } from 'react';
import { ScreenContextValue } from './types';

const ScreenContext = createContext<ScreenContextValue | undefined>(undefined);

export default ScreenContext;
