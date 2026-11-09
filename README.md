# TradeWars Game Server in Docker

Runs the Windows TWGS server under Wine, with its full admin GUI available in a
browser through noVNC.

## Coming from the 2022 version

This is a rebuild of the earlier Alpine image, and existing setups don't carry over:

- TWGS data now lives in a `/data` volume. The old image kept it in `/app`, and
  nothing here reads that location, so a new container starts with fresh games.
  There is no migration path, so keep your old data if you want to go back to it.
- The web UI moved from port 8080 to 6080.
- The container no longer downloads TWGS. You supply the installers and accept
  the license, as described below.

The previous version is at commit `e65e158`.

## Quick start

1. Put your installers in `./installers` (`TWGS219.exe`, `TWGS220.exe`, `TWGS220B.exe`).
2. Run `cp .env.example .env`, then read the [license](#license) and set
   `TWGS_ACCEPT_LICENSE=yes`.
3. Run `docker compose up -d --build`.
4. Open <http://localhost:6080>. If you left the passwords blank, find them with
   `docker compose logs twgs | grep Generated`.
5. **First start only:** the Activate TWGS dialog holds back server startup and
   the default game. Either click Activate, which contacts EIS over the internet,
   or close the dialog to carry on unactivated in the free starter mode.

Players connect with a telnet client to port 2002.

| Port | Purpose | Published by the example compose file |
| --- | --- | --- |
| 2002 | Player telnet | All interfaces |
| 2003 | TWGS remote admin | 127.0.0.1 only |
| 6080 | Web UI (noVNC) | 127.0.0.1 only |

The web UI is unencrypted HTTP and VNC passwords are limited to 8 characters, so
keep it on localhost, or put it behind a VPN, SSH tunnel or TLS proxy.

## Persistent data

Everything lives in the `twgs-data` volume, mounted at `/data`. Paths are relative to it.

| Path | Contents |
| --- | --- |
| `wine/system.reg` | TWGS configuration: ports, admin password, registration, activation status, and the table of game slots A–Z |
| `wine/drive_c/Program Files/EIS/TWGS/Game/Game?/` | Each game's universe, players, ships, ports, planets, corporations and logs |
| `wine/drive_c/Program Files/EIS/TWGS/Game/TWGLOB.DAT` | Data shared across games |
| `wine/drive_c/Program Files/EIS/TWGS/INTRO.ANS`, `DESC.ANS` | Customisable menu screens |
| `wine/drive_c/Program Files/EIS/TWGS/Backup??/` | TWGS's own `.TWA` game exports |
| `backups/` | Archives made by this container |
| `state/` | Installed version and generated web UI password |

The registry and the game files must stay together, because the registry records
which game slots exist and where they are. That is why this uses one volume for
the whole Wine prefix rather than mounting only the game folder. Wine writes the
registry when it shuts down, so stop the container normally rather than using
`docker kill`, or recent settings changes can be lost.

Backups and `system.reg` contain the admin password in plain text.

## Upgrading

Change `TWGS_VERSION` in `.env` and run `docker compose up -d`. The container then:

1. Writes a full archive to `/data/backups/`.
2. Runs the new installer silently.
3. Answers TWGS's "Backup existing games" prompt, which otherwise blocks startup.

Downgrades are refused. To go back, restore a backup.

## Backup and restore

Back up on demand (the server has to be stopped so the game files are consistent):

```sh
docker compose stop
docker compose run --rm --no-deps --entrypoint twgs-backup twgs
docker compose start
```

Restore, then set `TWGS_VERSION` in `.env` to the version the backup was taken from:

```sh
docker compose down
docker compose run --rm --no-deps --entrypoint tar twgs -xzf /data/backups/NAME.tar.gz -C /data
docker compose up -d
```

A restore overwrites files with their backed-up versions but doesn't delete files
created since the backup.

## Limits

- Without a registration, TWGS allows one player connection and one game. Check
  that your registration terms cover running in a container before you use one.
- TWGS refuses connections for a few seconds while it starts.

## License

TWGS is shareware by John Pritchett / EIS. The full terms are shown by the
installer, and installing means accepting them. In particular, they limit
redistribution to the unmodified original packages and prohibit modifying or
reverse-engineering the program. This image contains no TWGS files. Don't publish
an image or volume that has TWGS installed in it.
