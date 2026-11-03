# SparrowX Backstage portal

A Backstage developer portal for the SparrowX platform. It provides a catalog for services and teams, software templates, search, and the platform-specific UI used to onboard services and inspect their ownership metadata.

The application is a TypeScript/Yarn workspace. `packages/app` contains the frontend, `packages/backend` contains the backend, and `templates/` contains the service scaffolding template. Container and GitHub Actions definitions support deployment through the shared EKS/Argo CD platform.

## Development

```bash
yarn install
yarn dev
```

See the package-level READMEs and `app-config.yaml` for local configuration. Secrets and provider credentials must be supplied through environment-specific configuration rather than committed files.

For the shared delivery workflows, define `HEALTH_CHECK_PATH` and optionally `AWS_ROLE_NAME` at repository scope. `AWS_ACCOUNT_ID`, `AWS_REGION`, environment URLs, and Argo CD credentials are supplied through organization configuration.

## License

See [LICENSE.md](LICENSE.md).
