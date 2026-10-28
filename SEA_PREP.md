# Sea Prep (optional UnderTheSea branch)

This branch adds `scripts/sea-prep.ash` and leaves the existing `UnderTheSea` loop unchanged. The command is **`sea-prep`** (KoLmafia loads `scripts/*.ash` after Git checkout).

## Installation and updates

From the KoLmafia gCLI:

```text
git checkout donCannoli-burns/UnderTheSea sea-prep
verify sea-prep.ash
sea-prep help
sea-prep sim
```

To get future commits from the **sea-prep branch**:

```text
git update
```

`git update` updates all tracked Git projects, including whichever branch was checked out. `git list` prints the installed project IDs; `git update <unique-project-id>` updates just one. `git sync` can restore a missing script from an installed project's checkout.

**If you already have UnderTheSea on the main branch:** KoLmafia stores branch checkouts as separately named projects but both branches provide `scripts/UnderTheSea.ash` and support files. Avoid installing both in parallel: back up existing local changes, use `git list`, remove the old checkout with `git delete <exact-project-id>`, and then check out `sea-prep`. Do not delete the independent `codMaster`, `pvp_mab`, or `flogger` projects. Running `git update` on a previously installed **main** checkout will not switch it to `sea-prep` automatically.

## Arguments

| gCLI | Description | State changes? |
|---|---|---|
| `sea-prep help` | Show commands. Also the default with no arguments. | No |
| `sea-prep sim` | Print a FULL RUN projection from known inventory and preferences without visiting pages, changing settings, buying, adventuring, prompting, or issuing CLI commands. Does not emulate random results or live prices. | No |
| `sea-prep check` | Existing Sea readiness checklist, coin/ember warnings, codpiece read check. If already in home clan, inspects photo booth; otherwise reports verification deferred without switching clans. May issue read-only GET requests. | No purchases or adventure spending, no clan switching |
| `sea-prep booth` | Join the configured home clan with `clanhop` (when necessary), visit the photo booth and report all three daily activity counters and Sheriff prop status. Does not borrow props. | Changes clan if necessary; GET-only booth audit |
| `sea-prep run` | Entire pre-ascension Sea suite: wallet quest, sushi mat, Borrowed Time logic, optional legacy tasks, pearls/codMaster, coins/embers and prompted end-of-day cleanup. | Yes; prompts for adventuring |
| `sea-prep wallet` | Acquire wallet, inspect sushi mat and offer the prompted end-of-day clean-up. | Yes |
| `sea-prep pearls` | Stock max 5 pearls when needed under price cap; load using codMaster. | Yes |
| `sea-prep spend` | Pearl/codpiece plus Interesting Coin and Sept-Ember spending; skip adventure farming. | Yes |

## External local helpers

* The pearl loader uses `codMaster`. This branch adds `github donCannoli-burns/codMaster` to `dependencies.txt`; make sure it installs and `codMaster help` works.
* End-of-day cleanup calls `pvp_mab`, `flogger.ash`, `dpills`, `combo` and `CONSUME` if their branches run. These are **not bundled** and must already be installed/configured separately.
* The optional `sea_prep` outfit, Red-Nosed Snapper familiar, `snapper fish` CCS and `sea_prep` mood are local character configuration. The wallet route restores the previous setup where supported.
* Gameplay modes can spend resources and Meat; review `sea-prep sim` and `sea-prep check` before `sea-prep run`.

## Branch maintenance

This is a separate Git branch, **not a plugin in the main branch**. KoLmafia's `git update` follows commits on the installed `sea-prep` branch. Changes made only to `main` require a deliberate merge into `sea-prep`; Git update does not merge separate upstream branches automatically.

## Home clan photo booth

The configured `home_clan` is **The Meat Packers Union Of Slave Labor**. `sea-prep run` calls `clanhop <home_clan>` if not already in that clan, and verifies the active clan name before visiting `clan_viplounge.php?action=photobooth`. `sea-prep booth` invokes just this audit. You must have a working `clanhop` custom script and permission to rejoin the clan; `clanhop` is not a built-in KoLmafia command.

The audit recognizes the three booth actions: **Get your photo taken** (up to 3/day), **Borrow a prop** (up to 3/day), and **Take a group photo** (up to 1/day). It parses available counts from the page when displayed; for the first two, KoLmafia's `_photoBoothEffects` and `_photoBoothEquipment` are fallback estimates if the page text lacks counts.

When the home-clan booth is verified, all three Sheriff options report **green (supported by booth)** even if not in inventory. **Held/borrowable are distinct**: zero remaining borrow credits means the booth is stocked, but missing items cannot be borrowed today. The routine never automatically borrows props, takes photos, or spends credits. If the home clan or booth cannot be verified, the script does not claim unheld props are available.

`sea-prep check` does **not** change clans. `sea-prep sim` never makes page visits or runs `clanhop`; it reports what a full run would do.
