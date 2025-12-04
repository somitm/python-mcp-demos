param containerAppsEnvironmentName string
param mcpServerAppName string
param keycloakAppName string
param routeConfigName string = 'mcproutes'

resource containerEnv 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: containerAppsEnvironmentName
}

resource mcpServerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: mcpServerAppName
}

resource keycloakApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: keycloakAppName
}

// HTTP Route Configuration for rule-based routing
// Routes /auth/* to Keycloak and /* to MCP server
resource httpRouteConfig 'Microsoft.App/managedEnvironments/httpRouteConfigs@2024-10-02-preview' = {
  name: routeConfigName
  parent: containerEnv
  properties: {
    rules: [
      // Route /auth/* to Keycloak (strip /auth prefix since Keycloak serves at root)
      // Using pathSeparatedPrefix ensures /auth doesn't match /authentication
      {
        description: 'Keycloak Authentication Server'
        routes: [
          {
            match: {
              pathSeparatedPrefix: '/auth'
            }
            action: {
              prefixRewrite: '/'
            }
          }
        ]
        targets: [
          {
            containerApp: keycloakApp.name
          }
        ]
      }
      // Route everything else to MCP server (catch-all)
      {
        description: 'MCP Expenses Server'
        routes: [
          {
            match: {
              prefix: '/'
            }
            action: {
              prefixRewrite: '/'
            }
          }
        ]
        targets: [
          {
            containerApp: mcpServerApp.name
          }
        ]
      }
    ]
  }
  dependsOn: [
    mcpServerApp
    keycloakApp
  ]
}

output fqdn string = httpRouteConfig.properties.fqdn
output routeConfigUrl string = 'https://${httpRouteConfig.properties.fqdn}'
