Pool Design/Theory
==================
The nodejs-pool is built around a small series of core daemons that share access to a single LMDB table for tracking of shares, with MySQL being used to centralize configurations and ensure simple access from local/remote nodes.  The core daemons follow:
```text
api - Main API for the frontend to use and pull data from.  Expects to be hosted at  /
remoteShare - Main API for consuming shares from remote/local pools.  Expects to be hosted at /leafApi
pool - Where the miners connect to.
longRunner - Database share cleanup.
payments - Handles all payments to workers.
blockManager - Unlocks blocks and distributes payments into MySQL
worker - Does regular processing of statistics and sends status e-mails for non-active miners.
```
API listens on port 8001, remoteShare listens on 8000

graftpool.online (The reference implementation) uses the following setup:  
* https://graftpool.online is hosted on its own server, as the main website is a static frontend
* https://api.graftpool.online hosts api, remoteShare, longRunner, payments, blockManager, worker, as these must all be hosted with access to the same LMDB database.

Sample Caddyfile for API:
```text
https://api.graftpool.online {
    proxy /leafApi 127.0.0.1:8000
    proxy / 127.0.0.1:8001
    cors
    gzip
}
```

It is critically important that your webserver does not truncate the `/leafApi` portion of the URL for the remoteShare daemon, or it will not function!  Local pool servers DO use the remoteShare daemon, as this provides a buffer in case of an error with LMDB or another bug within the system, allowing shares and blocks to queue for submission as soon as the leafApi/remoteShare daemons are back up and responding with 200's.


Deployment via Installer
------------------------


```shell
cd ~/nodejs-pool/
pm2 start init.js --name=blockManager --log-date-format="YYYY-MM-DD HH:mm Z"  -- --module=blockManager
pm2 start init.js --name=worker --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=worker
pm2 start init.js --name=payments --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=payments
pm2 start init.js --name=remoteShare --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=remoteShare
pm2 start init.js --name=longRunner --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=longRunner
pm2 start init.js --name=pool --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=pool
pm2 restart api
```


Assumptions for the installer
-----------------------------
The installer assumes that you will be running a single-node instance and using a clean Ubuntu 16.04 server install.  The following system defaults are set:
* MySQL Username: pool
* MySQL Password: 98erhfiuehw987fh23d
* MySQL Host: 127.0.0.1
* MySQL root access is only permitted as the root user, the password is in `/root/.my.cnf`
* SSL Certificate is generated, self-signed, but is valid for Claymore Miners.
* The server installs and deploys Caddy as it's choice of web server!

The following raw binaries **MUST BE AVAILABLE FOR IT TO BOOTSTRAP**:
* sudo

The pool comes pre-configured with values for Monero (XMR), these may need to be changed depending on the exact requirements of your coin.  Other coins will likely be added down the road, and most likely will have configuration.sqls provided to overwrite the base configurations for their needs, but can be configured within the frontend as well.

Setup Instructions
==================

Server Requirements
-------------------
* 4 Gb Ram (Graft Build will fail with <= 2GB)
* 2 CPU Cores (with AES_NI)
* 40 Gb SSD-Backed Storage
* Clean and fresh Installation of Ubuntu 16.04


A known-working Hoster for this pool is Vultr: https://www.vultr.com/?ref=7097618

Pre-Deploy
----------
* If you're planning on using e-mail, you'll want to setup an account at https://mailgun.com (It's free for 10k e-mails/month!), so you can notify miners.  This also serves as the backend for password reset emails, along with other sorts of e-mails from the pool, including pool startup, pool Monerod daemon lags, etc so it's highly suggested!
* Pre-Generate the wallets, or don't, it's up to you!  You'll need the addresses after the install is complete, so I'd suggest making sure you have them available.  Information on suggested setups are found below.
* If you're going to be offering PPS, PLEASE make sure you load the pool wallet with XMR before you get too far along.  Your pool will trigger PPS payments on its own, and fairly readily, so you need some float in there!
* Make a non-root user, and run the installer from there!




Installation Howto
==================

1. Initial Installation
-----------------------
The following Script will install the Pool as a "Whole-in-1-System". All needed Systems are executed on this Server. But the processes can be split on seperate Server.
	
*  	Create a user "pooldaemon" with `useradd -m pooldaemon -d /home/pooldaemon`
*   Add the following line to /etc/sudoers:  `pooldaemon ALL=(ALL) NOPASSWD:ALL`
* 	Preinstall curl: `apt-get install -y curl sudo`
* 	Su into our user `su pooldaemon`

* 	Auto-Install Script: `curl -L https://github.com/mirei83/nodejs-pool/raw/master/deployment/deploy.bash| bash`
	This will to a complete initial setup including to compile all Graft binaries and will take a while!
	
*   Log out and back in from the pool user to activate the npm settings. (As root, you need to be in `/home/pooldaemon` then `su pooldaemon`)

* 	Check if everything has worked out:

	- Check Daemon with: `/usr/local/src/GraftNetwork/build/release/bin/graftnoded status`
	- Check RPC with: `curl -X POST http://127.0.0.1:18981/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"getblockcount"}' -H 'Content-Type: application/json'`
	- Check Pool at `http://<your-ip-here>` (just check if Networkhashrate is shown. Then its fine.)

2. Configure Pool & Webfrontend
-------------------------------
*	Change `nodejs-pool/config.json` appropriate.  It is pre-loaded for a local install of everything, running on 127.0.0.1.  This will work perfectly fine if you're using a single node setup.  You'll also want to set `bind_ip` to the external IP of the pool server, and `hostname` to the resolvable hostname for the pool server. `pool_id` is mostly used for multi-server installations to provide unique identifiers in the backend. You will also want to run: source ~/.bashrc  This will activate NVM and get things working for the following pm2 steps.
*	You'll need to change the API endpoint for the frontend code in the `poolui/build/globals.js` and `poolui/build/globals.default.js`. This will usually be `http(s)://<your server FQDN>/api` unless you tweak caddy!

3. Wallet Setup
---------------
The pool is designed to have a dual-wallet design, one which is a fee wallet, one which is the live pool wallet.  The fee wallet is the default target for all fees owed to the pool owner.  PM2 can also manage your wallet daemon, and that is the suggested run state.

*	Generate your wallets using `/usr/local/src/GraftNetwork/build/release/bin/graft-wallet-cli`. This is the wallet of your pool.
*	Make sure to save your regeneration stuff!
*	For the pool wallet, store the password in a file, the suggestion is ~/wallet_pass: `echo YOURPASSWORD > ~/wallet_pass`
*	Change the mode of the file with chmod to 0400: `chmod 0400 ~/wallet_pass`

*	Start the rpc-wallet using PM2: `pm2 start /usr/local/src/GraftNetwork/build/release/bin/graft-wallet-rpc -- --rpc-bind-port 18982 --password-file ~/wallet_pass --wallet-file <Your wallet name here> --disable-rpc-login --trusted-daemon`
*	To test if the wallet-rpc is running try: `curl -X POST http://127.0.0.1:18982/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"getaddress"}' -H 'Content-Type: application/json'`

4. Modify SQL Settings
----------------------
*	Edit `nodejs-pool/deployment/personal.sql` for your needs and execute it with `sudo mysql -u root --password=$ROOT_SQL_PASS < ./deployment/personal.sql` (ROOT_SQL_PASS is in /root/.my.cnf)

5. Start Pool
--------------
```shell
cd ~/nodejs-pool/
pm2 start init.js --name=blockManager --log-date-format="YYYY-MM-DD HH:mm Z"  -- --module=blockManager
pm2 start init.js --name=worker --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=worker
pm2 start init.js --name=payments --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=payments
pm2 start init.js --name=remoteShare --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=remoteShare
pm2 start init.js --name=longRunner --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=longRunner
pm2 start init.js --name=pool --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=pool
pm2 restart api
```

and save all running pm2 processes: `pm2 save`


The shareHost configuration is designed to be pointed at wherever the leafApi endpoint exists.  For graftpool.online, we use https://api.graftpool.online/leafApi.  If you're using the automated setup script, you can use: `http://<your IP>/leafApi`, as Caddy will proxy it.  If you're just using localhost and a local pool serv, http://127.0.0.1:8000/leafApi will do you quite nicely


Pool Troubleshooting
====================

API stopped updating!
---------------------
This is likely due to LMDB's MDB_SIZE being hit, or due to LMDB locking up due to a reader staying open too long, possibly due to a software crash.
The first step is to run:
```
mdb_stat -fear ~/pool_db/
```
This should give you output like:
```
Environment Info
  Map address: (nil)
  Map size: 51539607552
  Page size: 4096
  Max pages: 12582912
  Number of pages used: 12582904
  Last transaction ID: 74988258
  Max readers: 512
  Number of readers used: 24
Reader Table Status
    pid     thread     txnid
     25763 7f4f0937b740 74988258
Freelist Status
  Tree depth: 3
  Branch pages: 135
  Leaf pages: 29917
  Overflow pages: 35
  Entries: 591284
  Free pages: 12234698
Status of Main DB
  Tree depth: 1
  Branch pages: 0
  Leaf pages: 1
  Overflow pages: 0
  Entries: 3
Status of blocks
  Tree depth: 1
  Branch pages: 0
  Leaf pages: 1
  Overflow pages: 0
  Entries: 23
Status of cache
  Tree depth: 3
  Branch pages: 16
  Leaf pages: 178
  Overflow pages: 2013
  Entries: 556
Status of shares
  Tree depth: 2
  Branch pages: 1
  Leaf pages: 31
  Overflow pages: 0
  Entries: 4379344
```
The important thing to verify here is that the "Number of pages used" value is less than the "Max Pages" value, and that there are "Free pages" under "Freelist Status".  If this is the case, them look at the "Reader Table Status" and look for the PID listed.  Run:
```shell
ps fuax | grep <THE PID FROM ABOVE>

ex:
ps fuax | grep 25763
```
If the output is not blank, then one of your node processes is reading, this is fine.  If there is no output given on one of them, then proceed forwards.

The second step is to run:
```shell
pm2 stop blockManager worker payments remoteShare longRunner api
pm2 start blockManager worker payments remoteShare longRunner api
```
This will restart all of your related daemons, and will clear any open reader connections, allowing LMDB to get back to a normal state.

If on the other hand, you have no "Free pages" and your Pages used is equal to the Max Pages, then you've run out of disk space for LMDB.  You need to verify the cleaner is working.  For reference, 4.3 million shares are stored within approximately 2-3 Gb of space, so if you're vastly exceeding this, then your cleaner (longRunner) is likely broken.



Installation/Configuration Assistance
=====================================
If you need help installing the pool from scratch, please have your servers ready, which would be Ubuntu 16.04 servers, blank and clean, DNS records pointed.  These need to be x86_64 boxes with AES-NI Available.


Installation assistance is 0,5 XMR, with a 0,2 XMR deposit, with remainder to be paid on completion.  
Configuration assistance is 0,3 XMR with a 0,1 XMR deposit, and includes debugging your pool configurations, ensuring that everything is running, and tuning for your uses/needs.  

SSH access with a sudo-enabled user will be needed, preferably the user that is slated to run the pool.

If you'd like assistance with setting up node-cryptonote-pool, please provide what branch/repo you'd like to work from, as there's a variety of these.

Assistance is not available for frontend customization!

You can find us at the Discord Channel https://discord.gg/uTMpZby



Developer Donations
===================

Donate for Snipa22 for the original Code!

If you'd like to make a one time donation, the addresses are as follows:
* XMR - 44Ldv5GQQhP7K7t3ZBdZjkPA7Kg7dhHwk3ZM3RJqxxrecENSFx27Vq14NAMAd2HBvwEPUVVvydPRLcC69JCZDHLT2X5a4gr
* BTC - 114DGE2jmPb5CP2RGKZn6u6xtccHhZGFmM
* AEON - WmtvM6SoYya4qzkoPB4wX7FACWcXyFPWAYzfz7CADECgKyBemAeb3dVb3QomHjRWwGS3VYzMJAnBXfUx5CfGLFZd1U7ssdXTu

Credits
=======

[Zone117x](https://github.com/zone117x) - Original [node-cryptonote-pool](https://github.com/zone117x/node-cryptonote-pool) from which, the stratum implementation has been borrowed.

[Mesh00](https://github.com/mesh0000) - Frontend build in Angular JS [XMRPoolUI](https://github.com/mesh0000/poolui)

[Wolf0](https://github.com/wolf9466/)/[OhGodAGirl](https://github.com/ohgodagirl) - Rebuild of node-multi-hashing with AES-NI [node-multi-hashing](https://github.com/Snipa22/node-multi-hashing-aesni)
