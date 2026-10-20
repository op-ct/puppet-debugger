# Prepared commits for puppet-debugger and puppet-debug

`git commit` was not permitted in the session that did this work, so each logical commit was
recorded as a patch plus a commit message instead. The working trees of
`../../puppet-debugger` (branch `no-runtime-deps`) and `../../puppet-debug` already hold the
final state of all of them; `trees.txt` lists the git tree object recorded after each step.

To turn them into commits on a clean checkout of upstream `main` (v1.6.0, `f16ac1d`):

    cd puppet-debugger
    git checkout -b no-runtime-deps f16ac1d
    for p in 00 01 02 03 04 05 06 07 08 09 10; do
      f=$(ls ../_local_notes/commit-msgs/$p-*.patch)
      git apply --index "$f" && git commit -q -F "${f%.patch}.txt" || break
    done

Each patch is the diff between consecutive trees in `trees.txt`, so the sequence applies cleanly
in order. The module has one patch under `module/`, against nwops/puppet-debug `2a005d5`.

Order and content:

| step | subject |
|---|---|
| 00 | Use the published openvox gem in the Gemfile |
| 01 | Replace tty-pager with a built-in pager (the Bolt fix) |
| 02 | Drop rb-readline in favour of Ruby's readline |
| 03 | Recognise openvox gem paths in the functions listing |
| 04 | Drop the bundler runtime dependency |
| 05 | Drop table_print |
| 06 | Drop pluginator; discover plugins with Gem.find_files |
| 07 | Replace awesome_print with Puppet's StringConverter (plus colour pass) |
| 08 | Make facterdb optional; add --facts FILE |
| 09 | Replace the vendored Trollop with optparse |
| 10 | Metadata, CI and docs for the dependency-free gem |

Not included in any patch: `Gemfile.aio`, `Gemfile.aio.lock`, `.bundle/`, `vendor/` in the gem
checkout. They are the local Bundler setup for the Bolt AIO Ruby and are excluded through
`.git/info/exclude`.
