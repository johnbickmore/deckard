#!/usr/bin/env bash

# Deckard, a Web based Glade Runner
# Copyright (C) 2013  Nicolas Delvaux <contact@nicolas-delvaux.org>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

export GDK_BACKEND=broadway  # necessary for X-less servers
export BROADWAY_DISPLAY=9999  # The default port is 8080, but it is occupied by apache on deckard.malizor.org

# Supported locales
locales=(af_ZA \
         am_ET \
         an_ES \
         ar_AE \
         as_IN \
         ast_ES \
         az_AZ \
         be_BY \
         bem_ZM \
         bn_IN \
         brx_IN \
         bs_BA \
         ca_ES \
         cs_CZ \
         da_DK \
         de_DE \
         el_GR \
         en_AU \
         eo \
         es_ES \
         et_EE \
         eu_ES \
         fi_FI \
         fur_IT \
         fr_FR \
         gl_ES \
         gu_IN \
         he_IL \
         hi_IN \
         hr_HR \
         hu_HU \
         hy_AM \
         id_ID \
         is_IS \
         it_IT \
         ja_JP \
         kn_IN \
         ko_KR \
         lt_LT \
         lv_LV \
         mai_IN \
         mg_MG \
         mk_MK \
         ml_IN \
         mn_MN \
         mr_IN \
         ms_MY \
         my_MM \
         nb_NO \
         nds_NL \
         ne_NP \
         nl_NL \
         nn_NO \
         nso_ZA \
         oc_FR \
         or_IN \
         pa_IN \
         pl_PL \
         pt_BR \
         pt_PT \
         ro_RO \
         ru_RU \
         rw_RW \
         si_LK \
         sk_SK \
         sl_SI \
         sq_AL \
         sr_RS \
         sv_SE \
         ta_IN \
         te_IN \
         tg_TJ \
         th_TH \
         tr_TR \
         ug_CN \
         uk_UA \
         uz_UZ \
         vi_VN \
         wa_BE \
         xh_ZA \
         zh_CN \
         zh_HK \
         zh_TW \
         zu_ZA)

rm -rf content_tmp

for lang in "${locales[@]}"
do
    mkdir -p "content_tmp/LANGS/$lang/LC_MESSAGES"
done

function get_module {
    module=$1
    echo "Getting $module..."
    mkdir -p $module
    git clone --depth 1 git://git.gnome.org/$module tmp_clone

    # Build locals
    for lang in ${locales[@]}
    do
        # Try to figure out the PO name from the locale name
        IFS="_."
        unset lstring
        for i in $lang; do lstring+=($i); done
        unset IFS

        if [ -f tmp_clone/po/$lang.po ]
        then
            msgfmt --output-file LANGS/$lang/LC_MESSAGES/$module.mo tmp_clone/po/$lang.po
        elif [ -f tmp_clone/po/${lstring[0]}_${lstring[1]}.po ]
        then
            msgfmt --output-file LANGS/$lang/LC_MESSAGES/$module.mo tmp_clone/po/${lstring[0]}_${lstring[1]}.po
        elif [ -f tmp_clone/po/${lstring[0]}.po ]
        then
            msgfmt --output-file LANGS/$lang/LC_MESSAGES/$module.mo tmp_clone/po/${lstring[0]}.po
        else
            echo "No PO file found for $lang in $module!"
        fi
    done

    # Detect and keep relevant folders
    folders=(`find tmp_clone -iregex ".*\.\(ui\|xml\|glade\)" -printf '%h\n' | sort -u`)
    for folder in ${folders[@]}
    do
	cp --parents -r $folder $module
    done
    # Move all the tree up
    mv $module/tmp_clone/* $module
    rm -rf $module/tmp_clone
    # We don't need the clone anymore
    rm -rf tmp_clone

    # Remove unwanted files
    find $module -not -iregex ".*\.\(ui\|xml\|glade\|png\|jpg\|jpeg\|svg\)" | xargs rm 2> /dev/null

    # Basic check to remove non-glade files
    find $module -iregex ".*\.\(ui\|xml\|glade\)" -exec sh -c 'xmllint --xpath /interface/object {} 2> /dev/null > /dev/null || (echo {} is not valid, removing it... && rm -f {})' \;

    # We don't support odd glade files with type-func attributes (evolution, I'm looking at you)
    rm -f $(grep -lr "type-func" .)

    # Some glade files do not contain anything displayable (eg: cheese, data/cheese-actions.ui)
    cd ..
    find content_tmp/$module -iregex ".*\.\(ui\|xml\|glade\)" -exec python3 -c "
import os
from gladerunner import GladeRunner
gr = GladeRunner('{}')
gr.load()
if len(gr.windows) == 0:
    print('Nothing is displayable in {}, removing it...')
    os.remove('{}')
" \; 2> /dev/null
    cd content_tmp

    # Remove empty folders
    find $module -type d -empty -exec rmdir 2> /dev/null {} \;
}

cd content_tmp

# Get relevant modules
get_module alacarte
get_module anjuta
get_module anjuta-extras
get_module cheese
get_module dasher
get_module empathy
get_module eog
get_module eog-plugins
get_module epiphany
get_module evolution
get_module file-roller
get_module five-or-more
get_module f-spot
get_module gbrainy
get_module gcalctool
get_module gedit
get_module gedit-latex
get_module gedit-plugins
get_module gevice
get_module gitg
get_module gnome-bluetooth
get_module gnome-chess
get_module gnome-color-manager
get_module gnome-control-center
get_module gnome-dictionary
get_module gnome-disk-utility
get_module gnome-nettool
get_module gnome-session
get_module gnome-sudoku
get_module gnome-system-log
get_module gnome-system-monitor
get_module gnome-terminal
get_module gnumeric
get_module goffice
get_module gpointing-device-settings
get_module gthumb
get_module gtranslator
get_module iagno
get_module libgnome-media-profiles
get_module meld
get_module monkey-bubble
get_module mousetweaks 
get_module nanny
get_module nemiver
get_module network-manager-applet
get_module network-manager-openvpn
get_module network-manager-pptp
get_module office-runner
get_module orca
get_module pitivi
get_module rhythmbox
get_module rygel
get_module sabayon
get_module sound-juicer
get_module swell-foop
get_module totem
get_module tracker
get_module transmageddon
get_module vinagre
get_module vino
get_module zenity

# We are done, now replace the old content folder (if any)
cd ..
rm -rf content
mv content_tmp content