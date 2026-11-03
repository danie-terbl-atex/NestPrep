import { ASSISTANT_SCOPES } from '../assistant_scopes';
import type { AuthorizationServer } from './assistants_config';

/**
 * How an assistant finds out where to sign in (assistants ADR-0002). The MCP
 * endpoint's 401 points at the protected-resource metadata (RFC 9728), which
 * names this server, whose own metadata (RFC 8414) names every endpoint and
 * says what it supports: codes with S256 only, public clients, client id
 * metadata documents, and `iss` on every response (RFC 9207).
 */
export function protectedResourceMetadata(server: AuthorizationServer): object {
  return {
    resource: server.resource,
    authorization_servers: [server.issuer],
    scopes_supported: [...ASSISTANT_SCOPES],
    bearer_methods_supported: ['header'],
    resource_name: 'nestprep',
  };
}

export function authorizationServerMetadata(server: AuthorizationServer): object {
  const at = (path: string): string => `${server.issuer}${path}`;
  return {
    issuer: server.issuer,
    authorization_endpoint: at('/oauth/authorize'),
    token_endpoint: at('/oauth/token'),
    registration_endpoint: at('/oauth/register'),
    revocation_endpoint: at('/oauth/revoke'),
    response_types_supported: ['code'],
    response_modes_supported: ['query'],
    grant_types_supported: ['authorization_code', 'refresh_token'],
    code_challenge_methods_supported: ['S256'],
    token_endpoint_auth_methods_supported: ['none'],
    revocation_endpoint_auth_methods_supported: ['none'],
    client_id_metadata_document_supported: true,
    authorization_response_iss_parameter_supported: true,
    scopes_supported: [...ASSISTANT_SCOPES],
  };
}
