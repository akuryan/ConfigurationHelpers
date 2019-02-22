# Scripts

# merge-current-branch-to.sh

This script takes as input parameter target branch to which current branch shall be merged. It checkouts target branch, pulls it, merges current branch to it and then return back (if there is no errors)

## Usage

I link scripts in this folder to my home and call them from there:

```bash
ln -s /bashScripts/merge-current-branch-to.sh ~/merge-current-branch-to.sh
```

# get-cert-from-server.sh

This script will show you certificate from server

## Usage

```bash
.\get-cert-from-server.sh serverName
```

The most time I use it - for redirect domains, to be sure that certificate there is valid

```bash
.\get-cert-from-server.sh serverName | grep After
```
