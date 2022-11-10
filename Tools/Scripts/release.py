#!/usr/bin/python3

import os
import subprocess
import json
import argparse
from fileinput import FileInput
from pathlib import Path
import requests
import json

parser = argparse.ArgumentParser()
parser.add_argument('--version', type=str, help='Version of the release', required=True)
parser.add_argument('--sdk_path', type=str, default='', help='Path of the matrix-rust-sdk repository (defaults to sibling matrix-rust-sdk folder)', required=False)

args = vars(parser.parse_args())

def remove_suffix(string, suffix):
    if string.endswith(suffix):
        return string[:-len(suffix)]
    return string

# find root directory
root = remove_suffix(Path(os.path.abspath(os.path.dirname(__file__))).parent.parent.__str__(), '/')
version = args['version']
sdk_path = str(args['sdk_path'])
if len(sdk_path) == 0:
    sdk_path = remove_suffix(Path(root).parent.__str__(), '/') + '/matrix-rust-sdk'
else:
    sdk_path = remove_suffix(os.path.realpath(sdk_path), '/')

print("SDK path: " + sdk_path)
print("Generating framework")
os.system(sdk_path + "/bindings/apple/build_xcframework.sh")

print("Copy generated files")
os.system("rsync -a '" + sdk_path + "/generated/swift/' '" + root + "/Sources/MatrixRustSDK'")
os.system("rm '" + root + "/Sources/MatrixRustSDK/sdk.swift'")

print("Zipping framework")
zip_file_name = "MatrixSDKFFI.xcframework.zip"
os.system("pushd " + sdk_path + "/generated; zip -r " + root + "/" + zip_file_name + " MatrixSDKFFI.xcframework; popd")

github_token = os.environ['GITHUB_TOKEN']

if github_token is None:
    print("Please set GITHUB_TOKEN environment variable")
    exit(1)

print("Creating release")
checksum = subprocess.getoutput("shasum -a 256 " + root + "/" + zip_file_name).split()[0]

with FileInput(files=[root + '/Package.swift'], inplace=True) as file:
    for line in file:
        line = line.rstrip()
        if line.startswith('let checksum ='):
            line = 'let checksum = "' + checksum + '"'
        if line.startswith('let version ='):
            line = 'let version = "' + version + '"'
        if line.startswith('let useLocalBinary = true'):
            line = 'let useLocalBinary = false'
        print(line)

sdk_commit_hash = subprocess.getoutput("cat " + sdk_path + "/.git/refs/heads/main")
print("SDK commit: " + sdk_commit_hash)
commit_message = "Bump to " + version + " (matrix-rust-sdk " + sdk_commit_hash + ")"
print("Pushing changes as: " + commit_message)
os.system("git add " + root + "/Package.swift")
os.system("git add " + root + "/Sources")
os.system("git commit -m '" + commit_message + "'")
os.system("git push")

response1 = requests.post('https://api.github.com/repos/matrix-org/matrix-rust-components-swift/releases',
headers={
    'Accept': 'application/vnd.github+json',
    'Authorization': 'Bearer ' + github_token,
    'Content-Type': 'application/x-www-form-urlencoded',
},
data=json.dumps({
    "tag_name": version,
    "target_commitish": "main",
    "name": version,
    "body": "https://github.com/matrix-org/matrix-rust-sdk/tree/" + sdk_commit_hash,
    "draft": False,
    "prerelease": False,
    "generate_release_notes": False,
    "make_latest": "true"
}))
creation_response = response1.json()
print("Release created: " + creation_response['html_url'])

print("Uploading release assets")
upload_url = creation_response['upload_url'].split(u"{")[0]
with open(root + '/' + zip_file_name, 'rb') as file:
    response2 = requests.post(upload_url,
    headers={
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/zip',
        'Authorization': 'Bearer ' + github_token,
    },
    params={'name': zip_file_name},
    data=file)

if response2.status_code == 201:
    upload_response = response2.json()
    print("Upload finished: " + upload_response['browser_download_url'])
