# AzureAD OIDC for GitHub

Simple example of setting up OIDC auth for GitHub

As per these guides:

- https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure
- https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux

## Usage

- Edit `setup.sh` and change vars at the top
- Run `setup.sh`
- The workflow that uses this identity to access Azure is in `.github/workflows/oidc-example.yaml` it can be manually run
  