const SCOPES = "email openid"

export const cognitoAuthConfig = {
  authority: process.env.NEXT_PUBLIC_COGNITO_ENDPOINT,
  client_id: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID!,
  redirect_uri: process.env.NEXT_PUBLIC_COGNITO_REDIRECT_URI!,
  response_type: "code",
  scope: SCOPES,
  onSigninCallback: () => {
    window.history.replaceState({}, document.title, window.location.pathname);
  },
};

export const cognitoLogoutConfig = {
  domain: process.env.NEXT_PUBLIC_COGNITO_DOMAIN,
  clientId: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID!,
  redirect_uri: process.env.NEXT_PUBLIC_COGNITO_REDIRECT_URI!,
  response_type: "code",
  scope: SCOPES,
};