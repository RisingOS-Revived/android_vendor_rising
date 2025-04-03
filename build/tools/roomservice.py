#!/usr/bin/env python3
# Copyright (C) 2012-2013, The CyanogenMod Project
#           (C) 2017-2018,2020-2021, The LineageOS Project
#           (C) 2023-2025 RisingOS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import print_function

import glob
import json
import os
import shutil
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

from xml.etree import ElementTree

dryrun = os.getenv('ROOMSERVICE_DRYRUN') == "true"
if dryrun:
    print("Dry run roomservice, no change will be made.")

product = sys.argv[1]

if len(sys.argv) > 2:
    depsonly = sys.argv[2]
else:
    depsonly = None

try:
    device = product[product.index("_") + 1:]
except:
    device = product

if not depsonly:
    print("Device %s not found. Attempting to retrieve device repository from RisingOS-Revived-devices Github (http://github.com/RisingOS-Revived-devices)." % device)

repositories = []

if not depsonly:
    githubreq = urllib.request.Request("https://raw.githubusercontent.com/RisingOS-Revived/official_devices/refs/heads/fifteen/devices.xml")
    try:
        result = ElementTree.fromstring(urllib.request.urlopen(githubreq, timeout=10).read().decode())
    except urllib.error.URLError:
        print("Failed to fetch data from GitHub")
        sys.exit(1)
    except ValueError:
        print("Failed to parse return data from GitHub")
        sys.exit(1)
    for res in result.findall('.//project'):
        repositories.append(res.attrib['name'])

local_manifests = r'.repo/local_manifests'
if not os.path.exists(local_manifests): os.makedirs(local_manifests)

def backup_manifest(manifest_bkp_path):
    backup_path = f"{manifest_bkp_path}.backup"
    if not os.path.exists(backup_path):
        os.system(f"cp {manifest_bkp_path} {backup_path}")
        print(f"Backup created at {backup_path}")
    else:
        print(f"Backup already exists at {backup_path}")

def restore_manifest(manifest_bkp_path):
    backup_path = f"{manifest_bkp_path}.backup"
    if os.path.exists(backup_path):
        os.system(f"mv {backup_path} {manifest_bkp_path}")
        print(f"Manifest restored from {backup_path}")
    else:
        print(f"No backup found at {backup_path} to restore.")

def remove_local_manifest():
    local_manifest_path = ".repo/local_manifests/"
    if os.path.exists(local_manifest_path):
        shutil.rmtree(local_manifest_path)
        print(f"Removed local manifest: {local_manifest_path}")
    else:
        print(f"No local manifest found to remove: {local_manifest_path}")

def exists_in_tree(lm, path):
    for child in lm.getchildren():
        if child.attrib['path'] == path:
            return True
    return False

# in-place prettyprint formatter
def indent(elem, level=0):
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def get_manifest_path():
    '''Find the current manifest path
    In old versions of repo this is at .repo/manifest.xml
    In new versions, .repo/manifest.xml includes an include
    to some arbitrary file in .repo/manifests'''

    m = ElementTree.parse(".repo/manifest.xml")
    try:
        m.findall('default')[0]
        return '.repo/manifest.xml'
    except IndexError:
        return ".repo/manifests/{}".format(m.find("include").get("name"))

def get_default_revision():
    m = ElementTree.parse(".repo/manifests/snippets/rising.xml")
    d = m.find(".//remote[@name='devices']")
    r = d.get('revision')
    return r.replace('refs/heads/', '').replace('refs/tags/', '')

def get_from_manifest(devicename):
    for path in glob.glob(".repo/local_manifests/*.xml"):
        try:
            lm = ElementTree.parse(path)
            lm = lm.getroot()
        except:
            lm = ElementTree.Element("manifest")

        for localpath in lm.findall("project"):
            if re.search("device_.*_%s$" % device, localpath.get("name")):
                return localpath.get("path")

    return None

def is_in_manifest(projectpath):
    for path in glob.glob(".repo/local_manifests/*.xml"):
        try:
            lm = ElementTree.parse(path)
            lm = lm.getroot()
        except:
            lm = ElementTree.Element("manifest")

        for localpath in lm.findall("project"):
            if localpath.get("path") == projectpath:
                return True

    # Search in main manifest, too
    try:
        lm = ElementTree.parse(get_manifest_path())
        lm = lm.getroot()
    except:
        lm = ElementTree.Element("manifest")

    for localpath in lm.findall("project"):
        if localpath.get("path") == projectpath:
            return True

    # ... and don't forget the rising snippet
    try:
        lm = ElementTree.parse(".repo/manifests/snippets/rising.xml")
        lm = lm.getroot()
    except:
        lm = ElementTree.Element("manifest")

    for localpath in lm.findall("project"):
        if localpath.get("path") == projectpath:
            return True

    return False

def comment_project_in_manifests(target_path):
    """
    Search through manifest files and comment out any project with matching path
    Returns True if any changes were made
    """
    if dryrun:
        return False

    # Set the path for the manifest and the backup path
    manifest_bkp_path = ".repo/manifests/snippets/lineage.xml"
    # Backup the manifest before making changes
    backup_manifest(manifest_bkp_path)

    changed = False
    manifest_files = glob.glob(".repo/local_manifests/*.xml") + [
        get_manifest_path(),
        ".repo/manifests/snippets/lineage.xml"
    ]

    for manifest_file in manifest_files:
        try:
            # Read the file content
            with open(manifest_file, 'r') as f:
                content = f.read()

            # Parse the XML file
            tree = ElementTree.parse(manifest_file)
            root = tree.getroot()

            modified = False
            for project in root.findall('.//project'):
                if project.get('path') == target_path:
                    # Convert project to string
                    project_str = ElementTree.tostring(project, encoding='unicode')
                    # Create comment string
                    comment = f'<!-- {project_str} -->'
                    # Replace in content
                    content = content.replace(project_str, comment)
                    modified = True
                    changed = True

            if modified:
                # Write back the modified content
                with open(manifest_file, 'w') as f:
                    f.write(content)
                print(f"Commented out project with path {target_path} in {manifest_file}")

        except Exception as e:
            print(f"Error processing {manifest_file}: {str(e)}")
            continue

    return changed

def add_to_manifest(repositories):
    if dryrun:
        return

    try:
        lm = ElementTree.parse(".repo/local_manifests/roomservice.xml")
        lm = lm.getroot()
    except:
        lm = ElementTree.Element("manifest")

    for repository in repositories:
        repo_name = repository['repository']
        repo_target = repository['target_path']
        repo_revision = repository.get('revision')
        repo_remote = repository.get('remote', 'devices')

        # Handle new override format
        if override_data := repository.get('override'):
            print(f'Override specified: {override_data}')

            # Extract override details
            override_repo = override_data.get('repo')
            override_path = override_data.get('path')

            if override_repo and override_path:
                print(f'Searching for repository: {override_repo} with path: {override_path}')

                for manifest_file in glob.glob(".repo/local_manifests/*.xml") + [get_manifest_path(), ".repo/manifests/snippets/lineage.xml"]:
                    try:
                        tree = ElementTree.parse(manifest_file)
                        root = tree.getroot()

                        for project in root.findall('.//project'):
                            # Check if both repository name and path match
                            if (project.get('name') == override_repo and 
                                project.get('path') == override_path):
                                print(f'Found matching project: {override_repo} at path: {override_path}')
                                comment_project_in_manifests(override_path)
                                break
                    except Exception as e:
                        print(f"Error processing {manifest_file}: {str(e)}")
                        continue

        print('Checking if %s is fetched from %s' % (repo_target, repo_name))
        if is_in_manifest(repo_target):
            print('RisingOS-Revived-devices/%s already fetched to %s' % (repo_name, repo_target))
            continue

        project = ElementTree.Element("project", attrib = {
            "path": repo_target,
            "remote": repo_remote,
            "name": repo_name
        })

        if repo_revision is not None:
            project.attrib["revision"] = repo_revision

        if repo_remote.startswith("aosp-"):
            project.attrib["clone-depth"] = "1"
            if "revision" in project.attrib:
                del project.attrib["revision"]

        print("Adding dependency: %s -> %s" % (project.attrib["name"], project.attrib["path"]))
        lm.append(project)

    indent(lm, 0)
    raw_xml = ElementTree.tostring(lm).decode()
    raw_xml = '<?xml version="1.0" encoding="UTF-8"?>\n' + raw_xml

    f = open('.repo/local_manifests/roomservice.xml', 'w')
    f.write(raw_xml)
    f.close()

def fetch_dependencies(repo_path):
    print('Looking for dependencies in %s' % repo_path)
    dependencies_path = repo_path + '/rising.dependencies'
    syncable_repos = []
    verify_repos = []

    if os.path.exists(dependencies_path):
        dependencies_file = open(dependencies_path, 'r')
        dependencies = json.loads(dependencies_file.read())
        fetch_list = []

        for dependency in dependencies:
            if not is_in_manifest(dependency['target_path']):
                fetch_list.append(dependency)
                syncable_repos.append(dependency['target_path'])
                if 'branch' not in dependency:
                    if dependency.get('remote', 'github') == 'github':
                        dependency['branch'] = get_default_or_fallback_revision(dependency['repository'])
                        if not dependency['branch']:
                            sys.exit(1)
                    else:
                        dependency['branch'] = None
            verify_repos.append(dependency['target_path'])

            if not os.path.isdir(dependency['target_path']):
                syncable_repos.append(dependency['target_path'])

        dependencies_file.close()

        if len(fetch_list) > 0:
            print('Adding dependencies to manifest')
            add_to_manifest(fetch_list)
    else:
        print('%s has no additional dependencies.' % repo_path)

    if len(syncable_repos) > 0:
        print('Syncing dependencies')
        if not dryrun:
            os.system('repo sync --force-sync %s' % ' '.join(syncable_repos))

    for deprepo in verify_repos:
        fetch_dependencies(deprepo)

    # Set the path for the manifest and the backup path
    manifest_bkp_path = ".repo/manifests/snippets/lineage.xml"
    restore_manifest(manifest_bkp_path)

    # Remove the local manifest after fetching
    remove_local_manifest()

def get_default_or_fallback_revision(repo_name):
    default_revision = get_default_revision()
    print("Default revision: %s" % default_revision)
    print("Checking branch info")

    try:
        stdout = subprocess.run(
            ["git", "ls-remote", "-h", "https://:@github.com/RisingOS-Revived-devices/" + repo_name],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout.decode()
        branches = [x.split("refs/heads/")[-1] for x in stdout.splitlines()]
    except:
        return ""

    if default_revision in branches:
        return default_revision

    if os.getenv('ROOMSERVICE_BRANCHES'):
        fallbacks = list(filter(bool, os.getenv('ROOMSERVICE_BRANCHES').split(' ')))
        for fallback in fallbacks:
            if fallback in branches:
                print("Using fallback branch: %s" % fallback)
                return fallback

    print("Default revision %s not found in %s. Bailing." % (default_revision, repo_name))
    print("Branches found:")
    for branch in branches:
        print(branch)
    print("Use the ROOMSERVICE_BRANCHES environment variable to specify a list of fallback branches.")
    return ""

if depsonly:
    repo_path = get_from_manifest(device)
    if repo_path:
        fetch_dependencies(repo_path)
    else:
        print("Trying dependencies-only mode on a non-existing device tree?")

    sys.exit()

else:
    for repo_name in repositories:
        if repo_name.startswith("device_") and repo_name.endswith("_" + device):
            print("Found repository: %s" % repo_name)

            manufacturer = repo_name[len("device_") : -len("_" + device)]
            repo_path = "device/%s/%s" % (manufacturer, device)
            revision = get_default_revision()
            print("Using revision: %s" % revision)

            device_repository = {'repository':repo_name,'target_path':repo_path,'branch':revision}
            add_to_manifest([device_repository])

            print("Syncing repository to retrieve project.")
            os.system('repo sync --force-sync %s' % repo_path)
            print("Repository synced!")

            fetch_dependencies(repo_path)
            print("Done")
            sys.exit()

print("Repository for %s not found in the RisingOS-Revived-devices Github repository list. If this is in error, you may need to manually add it to your local_manifests/roomservice.xml." % device)
