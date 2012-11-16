continuous deployment script POC
--------------------------------

This script is made to deploy RPM packages after Jenkins sent them to your repository.

You just need to chose a file location (e.g /tmp/to_be_deployed), and make jenkins write the package name to update into it.

Example of to_be_deployed file:
```
puppet-tree-production:1.0-50:internal-repo
```

The cron job would be:
```cron
* * * * * /usr/local/bin/continuous_deployment.sh -f /tmp/to_be_deployed -p yum
```

optionally, you can add -g graphite -x deployed to graph deployments into graphite.

```
usage:
    ./continuous_deployment.sh -f package_file -p package_manager

    -f is a file containing the packages that needs to be updated,
       in the form package[:version[:repository]]
    -p is the package manager (yum or apt)
    -g graphite host (optionnal)
    -x graphite prefix (optionnal)
    -h shows this message
```


