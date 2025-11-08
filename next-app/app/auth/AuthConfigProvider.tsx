"use client";

import { AuthProvider } from "react-oidc-context";
import { ReactNode } from "react";
import {
  CognitoConfigProvider,
  useCognitoConfig,
} from "./CognitoConfigContext";

// Top-level wrapper
export const AuthConfigProvider = ({ children }: { children: ReactNode }) => {
  return (
    <CognitoConfigProvider>
      <InnerAuthProvider>{children}</InnerAuthProvider>
    </CognitoConfigProvider>
  );
};

// Waits for config to load before rendering AuthProvider
const InnerAuthProvider = ({ children }: { children: ReactNode }) => {
  const { config, loading } = useCognitoConfig();

  if (loading || !config) return <div>Loading auth config...</div>;

  return <AuthProvider {...config}>{children}</AuthProvider>;
};
