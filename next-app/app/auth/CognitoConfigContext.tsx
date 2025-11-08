"use client";

import {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
} from "react";
import { CognitoSettings, getAuthVars } from "./auth-details";

interface CognitoConfigContextValue {
  config: CognitoSettings | null;
  loading: boolean;
}

const CognitoConfigContext = createContext<CognitoConfigContextValue>({
  config: null,
  loading: true,
});

export const CognitoConfigProvider = ({
  children,
}: {
  children: ReactNode;
}) => {
  const [config, setConfig] = useState<CognitoSettings | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAuthVars()
      .then((cfg) => {
        console.log("Cognito config loaded.");
        setConfig(cfg);
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <CognitoConfigContext.Provider value={{ config, loading }}>
      {children}
    </CognitoConfigContext.Provider>
  );
};

// Hook to consume config
export const useCognitoConfig = () => useContext(CognitoConfigContext);
