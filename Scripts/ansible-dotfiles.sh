#!/bin/sh

# Usage:

# ansible-dotfiles.sh remoteserver.test.com,remoteserver2.test.com,
# ansible-dotfiles.sh $PWD/product_env


export ANSIBLE_HOST_KEY_CHECKING="False"
export ANSIBLE_SSH_ARGS="-o ForwardAgent=yes -o StrictHostKeyChecking=no"

ansible-playbook -i "${@}" /dev/stdin <<'PLAYBOOK'
---
- name: Install dotfiles remotely
  hosts: all
  gather_facts: no
  tasks:
    - name: Clone dotfiles
      git:
        repo: "git@github.com:richguk/dotfiles.git"
        dest: "$HOME/.dotfiles"
        update: yes
        bare: yes
        recursive: yes
        accept_hostkey: yes
    - name: Copy update script
      copy:
        content: |
                 #!/bin/sh
                 alias config='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
                 config fetch
                 config checkout -f server
                 config submodule init
                 config submodule update
                 config config --local status.showUntrackedFiles no
        dest: dotfiles-update.sh
        mode: 0700
    - name: Run update script
      shell: "./dotfiles-update.sh"
PLAYBOOK
