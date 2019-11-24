# CTF Reports

Allows players to report players and bugs to admins and online moderators.

Suppose `player`, `griefer` and `moderator` are online players:

- `player` runs this command: `/report griefer is griefing`
- `moderator` sees: `-!- player reported: griefer is griefing`
- The admin (named in `name`) is mailed via email: `<player> Report: griefer is griefing (moderators online: moderator)`

License: WTFPL

Dependencies: `ctf`, `email`
Optional dependencies: `irc`
