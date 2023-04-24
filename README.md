# GitHub Action for WP Engine Git Deployments

An action to deploy a WordPress project to a **[WP Engine](https://wpengine.com)** site via git. [Read more](https://wpengine.com/git/) about WP Engine's git deployment support.

## Usage

1. Create a `.github/workflows/ci.yml` file in your project repo.
2. Add the following code to the `ci.yml` file

```
name: CI Workflow

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout files and setup environment
      uses: actions/checkout@v3
      with:
        fetch-depth: 0

    - name: Set up Node
      uses: actions/setup-node@v3
      with:
        node-version: 16.x

    - name: Set up authentication for SatisPress packages
      run: composer config ${{ secrets.SATISPRESS_URL }} ${{ secrets.SATISPRESS_API_KEY }} satispress

    - name: Install project dependencies
      run: composer install --no-dev -o

    - name: Build theme assets
      run: npm install && npm run build
      working-directory: wp-content/themes/your-theme

    - name: Deploy
      uses: colis/action-deploy-to-wpengine@main
      env:
        WPENGINE_ENVIRONMENT_NAME: ${{ secrets.WPENGINE_ENVIRONMENT_NAME }}
        WPENGINE_SSH_PRIVATE_KEY: ${{ secrets.WPENGINE_SSH_PRIVATE_KEY }}
        WPENGINE_SSH_PUBLIC_KEY: ${{ secrets.WPENGINE_SSH_PUBLIC_KEY }}
```
3. Create a `.github/assets/.gitignore-wpe` file in your project repo containing untracked files and folders that WP Engine should ignore.
4. Create a `.github/assets/blocklist` file in your project repo containing all files and folders that should not be copied to the WP Engine server with `git push` - e.g.
```
auth.json
composer.json
composer.lock
README.md
wp-content/themes/your-theme/assets
```

## Environment Variables & Secrets

### Required

| Name | Type | Usage |
|-|-|-|
| `WPENGINE_ENVIRONMENT_NAME` | Secret | The name of the WP Engine environment you want to deploy to. |
| `WPENGINE_SSH_PRIVATE_KEY` | Secret | Private SSH key of your WP Engine git deploy user. See below for SSH key usage. |
|  `WPENGINE_SSH_PUBLIC_KEY` | Secret | Public SSH key of your WP Engine git deploy user. See below for SSH key usage. |

### Optional

| Name | Type  | Usage |
|-|-|-|
| `WPENGINE_ENVIRONMENT` | Environment Variable | Defaults to `production`. You shouldn't need to change this, but if you're using WP Engine's legacy staging, you can override the default and set to `staging` if needed. |
| `LOCAL_BRANCH` | Environment Variable | Set which branch in your repository you'd like to push to WP Engine. Defaults to `main`. |
| `SATISPRESS_URL` | Secret | The URL of your private SatisPress packagist repository. |
| `SATISPRESS_API_KEY` | Secret | The API Key of your private SatisPress packagist repository. |

### Further reading

* [Defining environment variables in GitHub Actions](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#environment-variables)
* [Storing secrets in GitHub repositories](https://developer.github.com/actions/managing-workflows/storing-secrets/)

## Setting up your SSH keys

1. [Generate a new SSH key pair](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/) as a special deploy key. The simplest method is to generate a key pair with a blank passphrase, which creates an unencrypted private key.
2. Store your public and private keys in your GitHub repository as new 'Secrets' (under your repository settings), using the names `WPENGINE_SSH_PRIVATE_KEY` and `WPENGINE_SSH_PUBLIC_KEY` respectively. In theory, this replaces the need for encryption on the key itself, since GitHub repository secrets are encrypted by default.
3. Add the public key to your target WP Engine environment.
4. Per the [WP Engine documentation](https://wpengine.com/git/), it takes about 30-45 minutes for the new SSH key to become active.