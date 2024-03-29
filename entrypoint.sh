#!/bin/bash

WPENGINE_HOST="git.wpengine.com"
WPENGINE_ENVIRONMENT_DEFAULT="production"
WPENGINE_ENV=${WPENGINE_ENVIRONMENT:-$WPENGINE_ENVIRONMENT_DEFAULT}
LOCAL_BRANCH_DEFAULT="main"
BRANCH=${LOCAL_BRANCH:-$LOCAL_BRANCH_DEFAULT}

function init_checks() {
	# Check required env variables
	if [[ -z "$WPENGINE_SSH_PRIVATE_KEY" ]] || [[ -z "$WPENGINE_SSH_PUBLIC_KEY" ]] || [[ -z "$WPENGINE_ENVIRONMENT_NAME" ]]; then
		missing_secret="WPENGINE_SSH_PRIVATE_KEY and/or WPENGINE_SSH_PUBLIC_KEY and/or WPENGINE_ENVIRONMENT_NAME"
		printf "[\e[0;31mERROR\e[0m] Secret %s is missing. Please add it to this action for proper execution.\nRefer https://github.com/colis/action-deploy-to-wpengine for more information.\n" "$missing_secret"
		exit 1
	fi
}

function setup_safe_directory() {
	git config --global --add safe.directory "$GITHUB_WORKSPACE"
}

function setup_ssh_access() {
	printf "[\e[0;34mNOTICE\e[0m] Setting up SSH access to server.\n"

	SSH_PATH="$HOME/.ssh"
	mkdir "$SSH_PATH"
	chmod 700 "$SSH_PATH"

	KNOWN_HOSTS_PATH="$SSH_PATH/known_hosts"
	WPENGINE_SSH_PRIVATE_KEY_PATH="$SSH_PATH/wpengine_key"
	WPENGINE_SSH_PUBLIC_KEY_PATH="$SSH_PATH/wpengine_key.pub"

	setup_private_key
}

function setup_private_key() {
	echo "$WPENGINE_SSH_PRIVATE_KEY" > "$WPENGINE_SSH_PRIVATE_KEY_PATH"
	echo "$WPENGINE_SSH_PUBLIC_KEY" > "$WPENGINE_SSH_PUBLIC_KEY_PATH"

	ssh-keyscan -t rsa "$WPENGINE_HOST" >> "$KNOWN_HOSTS_PATH"

	chmod 644 "$KNOWN_HOSTS_PATH"
	chmod 600 "$WPENGINE_SSH_PRIVATE_KEY_PATH"
	chmod 644 "$WPENGINE_SSH_PUBLIC_KEY_PATH"

	git config core.sshCommand "ssh -i $WPENGINE_SSH_PRIVATE_KEY_PATH -o UserKnownHostsFile=$KNOWN_HOSTS_PATH"
}

function setup_remote() {
	printf "[\e[0;34mNOTICE\e[0m] Setting up remote repository.\n"

	git config user.name "Automated Deployment"
	git config user.email "wp-support@americaneagle.com"
	git remote add "$WPENGINE_ENV" "git@$WPENGINE_HOST:$WPENGINE_ENV/$WPENGINE_ENVIRONMENT_NAME.git"
}

function cleanup_repo() {
	printf "[\e[0;34mNOTICE\e[0m] Cleaning up unnecessary files.\n"

	rm "$GITHUB_WORKSPACE/.gitignore"
	mv "$GITHUB_WORKSPACE/.github/assets/.gitignore-wpe" "$GITHUB_WORKSPACE/.gitignore"

	readarray -t filefolders < "$GITHUB_WORKSPACE/.github/assets/blocklist"
	for filefolder in "${filefolders[@]}"
	do
		rm -rf "$GITHUB_WORKSPACE/${filefolder:?}"
	done
}

function deploy() {
	printf "[\e[0;34mNOTICE\e[0m] Deploying %s to %s.\n" "$BRANCH" "$WPENGINE_ENV"

	git add --all
	git commit -m "GitHub Actions Deployment"
	git status
	git push -fu "$WPENGINE_ENV" "$BRANCH:master"
}

function main() {
	init_checks
	setup_safe_directory
	setup_ssh_access
	setup_remote
	cleanup_repo
	deploy
}

main