# data "azuread_client_config" "current" {}

# resource "azuread_application" "example" {
#   display_name     = "example"
#   identifier_uris  = ["api://example-app"]
#   logo_image       = filebase64("/path/to/logo.png")
#   owners           = [data.azuread_client_config.current.object_id]
#   sign_in_audience = "AzureADMultipleOrgs"

#   api {
#     mapped_claims_enabled          = true
#     requested_access_token_version = 2

#     known_client_applications = [
#       azuread_application.known1.application_id,
#       azuread_application.known2.application_id,
#     ]

#     oauth2_permission_scope {
#       admin_consent_description  = "Allow the application to access example on behalf of the signed-in user."
#       admin_consent_display_name = "Access example"
#       enabled                    = true
#       id                         = "96183846-204b-4b43-82e1-5d2222eb4b9b"
#       type                       = "User"
#       user_consent_description   = "Allow the application to access example on your behalf."
#       user_consent_display_name  = "Access example"
#       value                      = "user_impersonation"
#     }

#     oauth2_permission_scope {
#       admin_consent_description  = "Administer the example application"
#       admin_consent_display_name = "Administer"
#       enabled                    = true
#       id                         = "be98fa3e-ab5b-4b11-83d9-04ba2b7946bc"
#       type                       = "Admin"
#       value                      = "administer"
#     }
#   }

#   app_role {
#     allowed_member_types = ["User", "Application"]
#     description          = "Admins can manage roles and perform all task actions"
#     display_name         = "Admin"
#     enabled              = true
#     id                   = "1b19509b-32b1-4e9f-b71d-4992aa991967"
#     value                = "admin"
#   }

#   app_role {
#     allowed_member_types = ["User"]
#     description          = "ReadOnly roles have limited query access"
#     display_name         = "ReadOnly"
#     enabled              = true
#     id                   = "497406e4-012a-4267-bf18-45a1cb148a01"
#     value                = "User"
#   }

#   feature_tags {
#     enterprise = true
#     gallery    = true
#   }

#   optional_claims {
#     access_token {
#       name = "myclaim"
#     }

#     access_token {
#       name = "otherclaim"
#     }

#     id_token {
#       name                  = "userclaim"
#       source                = "user"
#       essential             = true
#       additional_properties = ["emit_as_roles"]
#     }

#     saml2_token {
#       name = "samlexample"
#     }
#   }

#   required_resource_access {
#     resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

#     resource_access {
#       id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
#       type = "Role"
#     }

#     resource_access {
#       id   = "b4e74841-8e56-480b-be8b-910348b18b4c" # User.ReadWrite
#       type = "Scope"
#     }
#   }

#   required_resource_access {
#     resource_app_id = "c5393580-f805-4401-95e8-94b7a6ef2fc2" # Office 365 Management

#     resource_access {
#       id   = "594c1fb6-4f81-4475-ae41-0c394909246c" # ActivityFeed.Read
#       type = "Role"
#     }
#   }

#   web {
#     homepage_url  = "https://app.example.net"
#     logout_url    = "https://app.example.net/logout"
#     redirect_uris = ["https://app.example.net/account"]

#     implicit_grant {
#       access_token_issuance_enabled = true
#       id_token_issuance_enabled     = true
#     }
#   }
# }