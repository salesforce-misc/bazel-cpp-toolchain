def create_mac_postfix_script(mac_artifacts):
    postfix_script = ""
    install_name_tool = "/usr/bin/install_name_tool"
    for mac_artifact in mac_artifacts:
        for other_mac_artficat in mac_artifacts:
            if other_mac_artficat != mac_artifact:
                if postfix_script != "":
                    postfix_script += " && "
                new_command = "%s -change %s @rpath/%s $INSTALLDIR/lib/%s" % (install_name_tool, other_mac_artficat, other_mac_artficat, mac_artifact)
                postfix_script += new_command
    return postfix_script
