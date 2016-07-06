# Deploy Homu and watch repos, everything automatic

These scripts are used to deploy [homu](https://github.com/servo/homu), the friendly merger bot on an Ubuntu machine.
It will install required tools, clone the repo, set up the configuration and launch the server.

## Configuration

Copy `vars.sample.yml` to `vars.yml` and start adding your own repositories.
Generate the necessary lines:

```
TRAVIS_TOKEN=homu-user-travis-token ./register-hook/register-hook.rb user repo-name >> vars.yml
```

Keep in mind that the `vars.yml` will contain secret data, so you should not publish it to public hosts.

## Deploy

Deployment is done via [Ansible](https://www.ansible.com/).

Create a file `hosts` to define your hosts:

```
[homu]
homu.example.com

[homu:vars]
ansible_python_interpreter=/usr/bin/python2.7
ansible_user=ubuntu
```

Start the deployment with:

```
ansible-playbook -i hosts deploy.xml
```

## Tests?

The scripts were tested on a Ubuntu 16.04 machine.
Homu also runs on SmartOS. I have modified Ansible scripts to achieve the same deployment for a zone on SmartOS.
If interested, I can make them available.
