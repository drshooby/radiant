export interface CognitoSettings {
  authority: string;
  client_id: string;
  redirect_uri: string;
  domain: string;
  response_type: string;
  scopes: string;
}

const SCOPES = "email openid";
const RESPONSE_TYPE = "code";

let cachedConfig: CognitoSettings | null = null;

// Normalize either local env or Lambda fetch result into CognitoSettings
function normalizeConfig(data: Record<string, string>): CognitoSettings {
  return {
    authority: data.NEXT_PUBLIC_COGNITO_ENDPOINT || data.COGNITO_ENDPOINT!,
    client_id: data.NEXT_PUBLIC_COGNITO_CLIENT_ID || data.COGNITO_CLIENT_ID!,
    redirect_uri:
      data.NEXT_PUBLIC_COGNITO_REDIRECT_URI || data.COGNITO_REDIRECT_URI!,
    domain: data.NEXT_PUBLIC_COGNITO_DOMAIN || data.COGNITO_DOMAIN!,
    response_type: RESPONSE_TYPE,
    scopes: SCOPES,
  };
}

export async function getAuthVars(): Promise<CognitoSettings> {
  if (cachedConfig) return cachedConfig;

  let data: Record<string, string>;

  if (process.env.NEXT_PUBLIC_COGNITO_ENDPOINT) {
    // Local dev
    data = {
      NEXT_PUBLIC_COGNITO_ENDPOINT: process.env.NEXT_PUBLIC_COGNITO_ENDPOINT!,
      NEXT_PUBLIC_COGNITO_CLIENT_ID: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID!,
      NEXT_PUBLIC_COGNITO_REDIRECT_URI:
        process.env.NEXT_PUBLIC_COGNITO_REDIRECT_URI!,
      NEXT_PUBLIC_COGNITO_DOMAIN: process.env.NEXT_PUBLIC_COGNITO_DOMAIN!,
    };
    console.log("Using local NEXT_PUBLIC env for Cognito config:", data);
  } else {
    // Production: fetch from Lambda
    if (!process.env.NEXT_PUBLIC_COGNITO_CONFIG_URI) {
      throw new Error("NEXT_PUBLIC_COGNITO_CONFIG_URI is not set");
    }
    const res = await fetch(process.env.NEXT_PUBLIC_COGNITO_CONFIG_URI);
    if (!res.ok) throw new Error("Failed to fetch Cognito config from Lambda");
    data = await res.json();
    console.log("Fetched Cognito config from Lambda:", data);
  }

  cachedConfig = normalizeConfig(data);
  console.log("Normalized Cognito config:", cachedConfig);

  return cachedConfig;
}
