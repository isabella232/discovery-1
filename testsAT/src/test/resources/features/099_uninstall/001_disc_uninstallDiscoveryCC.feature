@rest @dcos
Feature: [Uninstallation Discovery Command Center] Discovery uninstall with command center

  @skipOnEnv(DISCOVERY_SKIP_UNINSTALL=yes)
  Scenario: Uninstall Discovery
    Given I set sso token using host '!{EOS_ACCESS_POINT}' with user '${DCOS_TENANT1_OWNER_USER}' and password '${DCOS_TENANT1_OWNER_PASSWORD}' and tenant '${DCOS_TENANT1}'
    And I securely send requests to '!{EOS_ACCESS_POINT}:443'
    Then I uninstall service '${DISCOVERY_ID:-discovery-qa}' from tenant '${DCOS_TENANT1}'

  @skipOnEnv(DISCOVERY_SKIP_UNINSTALL=yes)
  Scenario: [QATM-1863][03] Delete Discovery policy
    Given I delete 'policy' '${DCOS_TENANT1}-${DISCOVERY_ID:-discovery-qa}' from tenant '${DCOS_TENANT1}' with tenant user and tenant password '${DCOS_TENANT1_OWNER_USER}:${DCOS_TENANT1_OWNER_PASSWORD}' if it exists

