# singularity-cli
`singularity-cli` replaces the `mescal` command that Offers.com used in the past
 * all of the commands except `delete` and `deploy` require you to be in the base project folder to work correctly

## Requirements
 * Docker >= 1.12.1
 * ~/.ssh has the right keys

## Install
If you don't have `dope` installed, go here to install it first: https://github.com/offers/dope
```
dope install registry.ofr.cloud/devops/singularity-cli
```
## Update
```
dope update singularity
```
# Usage:
#### singularity ssh
* start new container in singularity and SSH into it
 ```
 cd ~/yourproject
 singularity ssh
 ```

#### singularity run &lt;commands&gt;
* start new container in singularity and run &lt;commands&gt;
* for now, the commands (or script) must either be passed on the command line or in the container
 ```
 cd ~/yourproject
 singularity run /your/script/is/here.sh args
 singularity run ls -a | grep appname
 ```

#### singularity deploy &lt;uri&gt; &lt;file.json&gt; &lt;release&gt;
* manually deploy a single singularity job
 ```
 cd ~/yourproject
 singularity deploy ./singularity/some-singularity-config.json r74
 ```

#### singularity delete &lt;uri&gt; &lt;file.json&gt;
* delete singularity job
 ```
 singularity delete ./singularity/some-singularity-config.json
 ```

# Creation of a new project:
If you want to create a new project that uses this tool's functionality you must create the files `.mescal.json` and `mesos-deploy.yml` in the base project directory for your new project.
Use another project's files as a template and fill in the values for your new project.

# Testing:
```
docker-compose build
./test.sh
```

