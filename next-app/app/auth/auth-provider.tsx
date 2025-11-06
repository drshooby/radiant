"use client";

import { AuthProvider } from "react-oidc-context";
import { cognitoAuthConfig } from "./auth.config";

export function Provider({ children }: { children: React.ReactNode }) {
  return <AuthProvider {...cognitoAuthConfig}>{children}</AuthProvider>;
}
