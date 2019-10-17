# HSQLDB image

Image for HSQLDB. This exposes port 9001 for database connections and uses `file:/var/opt/hsqldb/data` for database files. If this directory is mounted, change ownership of the local mount path before running the tool:

```sh
chown -R 9999:999 <local mount path>
```
