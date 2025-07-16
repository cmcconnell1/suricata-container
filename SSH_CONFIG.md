# SSH_KEY_FINGERPRINT
- The SSH_KEY_FINGERPRINT variable should contain the _fingerprint_ of the SSH key, _not_ the public key itself.

## Summary:
- CircleCI gets: Private key (in SSH Keys section) + Fingerprint (in environment variable)
- Bitbucket gets: Public key (in repository access keys)
- Config uses: ${SSH_KEY_FINGERPRINT} to reference the key by its fingerprint
- The fingerprint is just an identifier that tells CircleCI which of your stored SSH keys to use.

# What Goes in the Environment Variable:
```bash
SSH_KEY_FINGERPRINT = The fingerprint (like "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99")
```

# NOTE: again NOT the actual public key content.

# How to Set This Up:
1. Add SSH Key to CircleCI:
- Go to CircleCI Project Settings → SSH Keys
    - Click "Add SSH Key"
    - Paste your private key here
    - CircleCI will show you the fingerprint after adding it

2. Copy the Fingerprint:
- After adding the key, CircleCI displays the fingerprint
- Copy that fingerprint value (looks like: aa:bb:cc:dd:ee:ff:...)

3. Set Environment Variable:
- Go to Project Settings → Environment Variables
    - Add: SSH_KEY_FINGERPRINT = aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99

4. Add Public Key to Bitbucket:
- Go to Bitbucket → Repository Settings → Access Keys
    - Add your public key there
