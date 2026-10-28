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
| `sea-prep check` | Existing Sea readiness checklist, coin/ember warnings, codpiece read check. May issue read-only GET requests. | No purchases or adventure spending |
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
