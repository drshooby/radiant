"use client";

import { useAuth } from "react-oidc-context";
import { useEffect, useCallback } from "react";
import { cognitoLogoutConfig } from "@/app/auth/auth.config";

export default function Home() {
  const auth = useAuth();

  // Handles automatic sign-in redirect if not authenticated
  const redirectToLogin = useCallback(() => {
    if (!auth.isAuthenticated && !auth.isLoading && !auth.activeNavigator) {
      auth.signinRedirect();
    }
  }, [auth]);

  // Runs once on mount or when auth state changes
  useEffect(() => {
    const justLoggedOut = sessionStorage.getItem("logging_out");

    if (justLoggedOut) {
      sessionStorage.removeItem("logging_out");
    } else {
      redirectToLogin();
    }
  }, [redirectToLogin]);

  // Handles logout flow
  const signOut = async () => {
    sessionStorage.setItem("logging_out", "true");
    await auth.removeUser();

    const { domain, clientId, redirect_uri, response_type, scope } =
      cognitoLogoutConfig;

    const params = new URLSearchParams({
      response_type: response_type,
      client_id: clientId,
      redirect_uri: redirect_uri,
      scope,
    });

    window.location.href = `${domain}/logout?${params.toString()}`;
  };

  if (auth.isLoading) return <div>Loading...</div>;
  if (auth.error) return <div>Oops... {auth.error.message}</div>;
  if (!auth.isAuthenticated)
    return <div>You have been signed out. Redirecting to sign in...</div>;

  return (
    <div>
      <h1>Hi... {auth.user?.profile.email}</h1>
      <button onClick={signOut}>Sign out?</button>

      <hr />

      <div style={{ marginTop: "1rem", fontSize: "0.9rem" }}>
        <h3>Session Info (Debug)</h3>
        <pre>
          ID Token Exp:{" "}
          {new Date((auth.user?.profile.exp ?? 0) * 1000).toLocaleString()}
          {"\n"}
          Access Token Expires In:{" "}
          {Math.round((auth.user?.expires_in ?? 0) / 60)} min{"\n"}
          Token Type: {auth.user?.token_type ?? "N/A"}
          {"\n\n"}
          ID Token:{"\n"}
          {auth.user?.id_token ?? "N/A"}
          {"\n\n"}
          Access Token:{"\n"}
          {auth.user?.access_token ?? "N/A"}
        </pre>
      </div>
    </div>
  );
}
