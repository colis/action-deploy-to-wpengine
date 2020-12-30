#!/bin/bash

WPENGINE_HOST="git.wpengine.com"
WPENGINE_ENVIRONMENT_DEFAULT="production"
WPENGINE_ENV=${WPENGINE_ENVIRONMENT:-$WPENGINE_ENVIRONMENT_DEFAULT}
LOCAL_BRANCH_DEFAULT="main"
BRANCH=${LOCAL_BRANCH:-$LOCAL_BRANCH_DEFAULT}

function deploy() {
	printf "[\e[0;34mNOTICE\e[0m] Deploying $BRANCH to $WPENGINE_ENV.\n"

	git add --all
	git commit -m "Bitbucket Pipelines Deployment"
	git status
	git push -fu $WPENGINE_ENV $BRANCH:master
}

function cleanup_repo() {
	printf "[\e[0;34mNOTICE\e[0m] Cleaning up unnecessary files.\n"

	rm "$GITHUB_WORKSPACE/.gitignore"
	mv assets/.gitignore-wpe "$GITHUB_WORKSPACE/.gitignore"

	readarray -t filefolders < assets/remove-from-server
	for filefolder in "${filefolders[@]}"
	do
		rm -rf "$GITHUB_WORKSPACE/$filefolder"
	done
}

function setup_remote() {
	printf "[\e[0;34mNOTICE\e[0m] Setting up remote repository.\n"

	git config user.name "Automated Deployment"
	git config user.email "wp-support@americaneagle.com"
	git remote add $WPENGINE_ENV git@$WPENGINE_HOST:$WPENGINE_ENV/$WPENGINE_ENVIRONMENT_NAME.git
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

function main() {
	setup_ssh_access
	setup_wordpress_files
	setup_remote
	cleanup_repo
	deploy
}

main