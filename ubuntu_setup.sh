#!/bin/bash

package_updates () {
    if [! test -d "/etc/initial-package-updates-done"]; then
        echo "Package updates starting..."
        domain_packages="$(realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob)"
        sudo apt update
        sudo apt upgrade
        sudo apt install "${domain_packages[@]}"
        oddjob-mkhomedir packagekit
        sudo touch /etc/initial-package-updates-done
        echo "Package updates finished."
        # TODO: Add self to startup scripts folder
        sudo shutdown -r now
    else
        echo "Package updates already completed."
    fi
}

rename_computer () {
   echo "Renaming computer..."
   serial=$(sudo dmidecode | grep -m 1 "Serial Number" | awk '{print $3}')      # Grabs the computer's serial number
   if [! $serial == $hostname]; then
        truncate -s 0 /etc/hostname /etc/hosts                                  # Removes the contents of the hostname files
        echo $serial | tee -a /etc/hostname /etc/hosts                          # Adds the serial number to the hostname files
        sudo service hostname start                                             # Restarts the hostname service and applies changes
    fi
    echo "Computer rename finished."
}

# Add computer to domain
domain_join () {
    echo "Domain join starting..."
    file="./ubuntu_setup.conf"
    domain=$(grep '^domain' "$file" | cut -d\= -f2)
    dc=$(grep '^dc=' "$file" | cut -d\= -f2)
    read -p "Email address: " adm

    sudo realm discover $domain
    sudo realm join -U $adm $dc -v                                 
    sudo realm permit --all
    echo "Domain join finished."
}

# Disable the new user welcome screen
disable_welcome () {
    echo "Disable welcome starting..."
    if [test -d "/etc/skel/.config"]; then
        sudo touch /etc/skel/.config/gnome-initial-setup-done
        echo "Removed GNOME welcome screen."
    elif [! test -d "/etc/skel/.config"]; then
        sudo mkdir /etc/skel/.config
        sudo touch /etc/skel/.config/gnome-initial-setup-done
        echo "Removed GNOME welcome screen."
    fi
    echo "Disable welcome finished."
}
