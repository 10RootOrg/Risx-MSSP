# Risx-MSSP
 
# Global environment variables used by scripts

- `PASSWORD_GENERATOR` -- should contain a command to be executed to get a single random password, by default it would be `LC_ALL=C tr -dc 'A-Za-z0-9-_!' < /dev/urandom | head -c 16`
- `GENERATE_PASSWORDS` -- if set, script will try to generate undefined passwords
- `GENERATE_ALL_PASSWORDS` -- if set, script will try to generate *ALL* passwords, *ignoring* existing ones

# Per-script environment variables

## Example

```
$ PASSWORD_GENERATOR='apg -n 1 -m 16' ./endtoend.sh
```