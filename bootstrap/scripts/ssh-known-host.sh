#!/bin/bash

touch "${HOME}/.ssh/known_hosts"
chmod u=rw,go= "$_"

ssh-keygen -R "$2" &> /dev/null
echo "${2} $(cat "${1}.pub")" >> "${HOME}/.ssh/known_hosts"
