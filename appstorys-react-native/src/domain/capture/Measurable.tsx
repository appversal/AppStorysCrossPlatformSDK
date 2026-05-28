import React, { useEffect, useRef } from 'react';
import { View } from 'react-native';
import { layoutChangeEvent } from './layoutChangeEvent';
import useScreen from '../screen/useScreen';

interface MeasurableProps {
  appstorys: string;
  children: React.ReactNode;
}

export default function Measurable({ appstorys, children }: MeasurableProps) {
  const { context: { register, unregister } } = useScreen();
  const componentRef = useRef(null);

  useEffect(() => {
    if (appstorys && componentRef.current) {
      register(appstorys, componentRef.current);
    }
    return () => {
      if (appstorys) unregister(appstorys);
    };
  }, [appstorys, register, unregister]);

  return (
    <View ref={componentRef} collapsable={false} onLayout={() => layoutChangeEvent(appstorys)}>
      {children}
    </View>
  );
}
