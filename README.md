# Hands on Ansible

> 本實驗參考[怎麼用 Docker 練習 Ansible？](https://chusiang.gitbooks.io/automate-with-ansible/content/05.how-to-practive-the-ansible-with-docker.html)

最近有些面試的職務需求會需要使用 ansible，所以就來玩玩看

## Install ansible on MacOS

```sh
$ brew install ansible
# 過程中有跳出 xcode 版本的問題，更新到最新版即可
```

## Create node machine using docker compose

這邊要注意的是，我的電腦是 M2 晶片，而原作者提供的 image 的 OS/ARCH 是 `linux/amd64`，使用上一直出現奇怪的問題，所以我又照者原作者的[範例](https://github.com/chusiang/ansible-managed-node.dockerfile/blob/master/alpine-3.7/Dockerfile)重新 build 了一版 `linux/arm64` 的

```yaml
version: '3'

services:
  ansible-node-1:
    image: weeee9/ansible-managed-node:alpine3.7
    ports:
      - '4444:22'

  ansible-node-2:
    image: weeee9/ansible-managed-node:alpine3.7
    ports:
      - '4445:22'
```

## Setting ansible config

1. `ansible.cfg`

```ini
[defaults]

inventory=hosts
remote_user=docker
host_key_checking=False
```

- inventory: 指定 inventory 檔案路徑，內容包含要連線的遠端主機清單
- remote_user: 使用 `docker` 這個使用者登入遠端主機
- host_key_checking: 為了方便，這邊先跳過 ssh key 檢查

2. hosts

```ini
[dockertesting]
ansible-node-1 ansible_ssh_host=127.0.0.1 ansible_ssh_port=4444 ansible_ssh_pass=docker
ansible-node-2 ansible_ssh_host=127.0.0.1 ansible_ssh_port=4445 ansible_ssh_pass=docker
```

- [dockertesting]: 定義一個叫做 `dockertesting` 的遠端主機群組
- ansible-node-1/ansible-node-2: 遠端主機名稱
- ansible_ssh_host: 遠端主機地址，因為我們用 docker container 的方式啟動 node，所以這邊都是 localhost
- ansible_ssh_port: 我們在 `docker-compose.yml` 中分別將 port `4444` 及 `4445` 對應到了 container 的 `22` port
- ansible_ssh_pass: 這邊一樣為了方便，使用密碼來做登入，而密碼 `docker` 則是在建立 image 時就設定好的

## First ansible playbook

```yaml
- name: say 'Hello World!'
  hosts: dockertesting
  vars:
    ansible_python_interpreter: /usr/bin/python3
  tasks:
    - name: echo 'Hello World!'
      command: echo 'Hello World!'
      register: result

    - name: print stdout
      debug:
        msg: '{{ result.stdout }}'
```

這份 playbook 名為 `say 'Hello World!`，並指定在 `dockertest` 這個群組下的遠端主機上執行。裡面包含兩個 task：

1. echo 'Hello World!'
    這裡會執行 command - `echo 'Hello World!` 並把結果註冊到變數 `result` 中
2. print stdout
    這裡使用 `debug` module 來輸出 result 中的 `stdout`

預期執行 playbook 結果如下：
```sh
$ ansible-playbook hello_world.yml

PLAY [say 'Hello World!'] **********************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************
ok: [ansible-node-2]
ok: [ansible-node-1]

TASK [echo 'Hello World!'] *********************************************************************************************************************************
changed: [ansible-node-2]
changed: [ansible-node-1]

TASK [print stdout] ****************************************************************************************************************************************
ok: [ansible-node-1] => {
    "msg": "Hello World!"
}
ok: [ansible-node-2] => {
    "msg": "Hello World!"
}

PLAY RECAP *************************************************************************************************************************************************
ansible-node-1             : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ansible-node-2             : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```